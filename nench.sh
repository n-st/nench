#!/bin/bash

##########
# nench.sh ("new bench.sh")
# =========================
# current version at https://github.com/n-st/nench
# - loosely based on the established freevps.us/bench.sh
# - includes CPU and ioping measurements
# - reduced number of speedtests (9 x 100 MB), while retaining useful European
#   and North American POPs
# - runs IPv6 speedtest by default (if the server has IPv6 connectivity)
# Run using `curl -s bench.wget.racing | bash`
# or `wget -qO- bench.wget.racing | bash`
##########

command_exists()
{
    command -v $@ > /dev/null 2>&1
}

Bps_to_MiBps()
{
    awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "error" } }'
}

finish()
{
    rm -f test_$$
    exit
}
# make sure the dd test file is always deleted, even when the script is
# interrupted while dd is running
trap finish EXIT INT TERM

command_benchmark()
{
    if [ "$1" = "-q" ]
    then
        QUIET=1
        shift
    fi

    if command_exists "$1"
    then
        time dd if=/dev/zero bs=1M count=500 2> /dev/null | \
            "$@" > /dev/null
    else
        if [ "$QUIET" -ne 1 ]
        then
            unset QUIET
            printf '[command `%s` not found]\n' "$1"
        fi
        return 1
    fi
}

dd_benchmark()
{
    # returns IO speed in B/s

    # Temporarily override locale to deal with non-standard decimal separators
    # (e.g. "," instead of ".").
    # The awk script assumes bytes/second if the suffix is !~ [TGMK]B. Call me
    # if your storage system does more than terabytes per second; I'll want to
    # see that.
    LC_ALL=C dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync 2>&1 | \
        awk -F, '
            {
                io=$NF
            }
            END {
                if (io ~ /TB\/s/) {print 1000*1000*1000*1000*io}
                else if (io ~ /GB\/s/) {print 1000*1000*1000*io}
                else if (io ~ /MB\/s/) {print 1000*1000*io}
                else if (io ~ /KB\/s/) {print 1000*io}
                else { print 1*io}
            }'
    rm -f test_$$
}

download_benchmark()
{
    curl --max-time 10 -so /dev/null -w '%{speed_download}\n' "$@"
}

if ! command_exists curl
then
    printf '%s\n' 'This script requires curl, but it could not be found.' 1>&2
    exit 1
fi

printf '%s\n' '-------------------------'
printf ' nench.sh benchmark\n'
date -u '+ %F %T UTC'
printf '%s\n' '-------------------------'

printf '\n'

curl -s --max-time 10 -o ioping.static http://bench.wget.racing/ioping.static
chmod +x ioping.static

# Basic info
printf 'Processor:    '
awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//'
printf 'CPU cores:    '
awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo
printf 'Frequency:    '
awk -F: ' /cpu MHz/ {freq=$2} END {print freq " MHz"}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//'
printf 'RAM:          '
free -h | awk 'NR==2 {print $2}'
if [ $(swapon -s | wc -l) -lt 2 ]
then
    printf 'Swap:         -\n'
else
    printf 'Swap:         '
    free -h | awk 'NR==4 {printf $2}'
    printf '\n'
fi
printf 'Kernel:       '
uname -s -r -m

printf '\n'

printf 'Disks:\n'
lsblk --nodeps --noheadings --output NAME,SIZE,ROTA --exclude 1,2,11 | sort | awk '{if ($3 == 0) {$3="SSD"} else {$3="HDD"}; print}' | column -t

printf '\n'

# CPU tests
export TIMEFORMAT='%3R seconds'

printf 'CPU: SHA256-hashing 500 MB\n    '
command_benchmark -q sha256sum || command_benchmark -q sha256 || printf '[no SHA256 command found]\n'

printf 'CPU: bzip2-compressing 500 MB\n    '
command_benchmark bzip2

printf 'CPU: AES-encrypting 500 MB\n    '
command_benchmark openssl enc -e -aes-256-cbc -pass pass:12345678

printf '\n'

# ioping
printf 'ioping: seek rate\n    '
./ioping.static -R -w 5 /var/tmp | tail -n 1
printf 'ioping: sequential speed\n    '
./ioping.static -RL -w 5 /var/tmp | tail -n 2 | head -n 1

printf '\n'

# dd disk test
printf 'dd test\n'

io1=$( dd_benchmark )
printf '    1st run:    %s\n' "$(printf '%d\n' "$io1" | Bps_to_MiBps)"

io2=$( dd_benchmark )
printf '    2nd run:    %s\n' "$(printf '%d\n' "$io2" | Bps_to_MiBps)"

io3=$( dd_benchmark )
printf '    3rd run:    %s\n' "$(printf '%d\n' "$io3" | Bps_to_MiBps)"

# Calculating avg I/O (better approach with awk for non int values)
ioavg=$( awk 'BEGIN{print int(('"$io1"' + '"$io2"' + '"$io3"')/3)}' )
printf '    average:    %s\n' "$(printf '%d\n' "$ioavg" | Bps_to_MiBps)"

printf '\n'

# Network speedtests

ipv4=$(curl -4 -s --max-time 5 http://icanhazip.com/)
if [ -n "$ipv4" ]
then
    printf 'IPv4 speedtests\n'
    printf '    your IPv4:    %s\n' $(printf '%s\n' $ipv4 | sed 's!\(\([0-9a-f]\+[.:]\)\{3\}\).\+!\1xxxx!')
    printf '\n'

    printf '    Cachefly CDN:         '
    download_benchmark -4 http://cachefly.cachefly.net/100mb.test | \
        Bps_to_MiBps

    printf '    Leaseweb (NL):        '
    download_benchmark -4 http://mirror.nl.leaseweb.net/speedtest/100mb.bin | \
        Bps_to_MiBps

    printf '    Softlayer DAL (US):   '
    download_benchmark -4 http://speedtest.dal01.softlayer.com/downloads/test100.zip | \
        Bps_to_MiBps

    printf '    Online.net (FR):      '
    download_benchmark -4 http://ping.online.net/100Mo.dat | \
        Bps_to_MiBps

    printf '    OVH BHS (CA):         '
    download_benchmark -4 http://proof.ovh.ca/files/100Mio.dat | \
        Bps_to_MiBps

else
    printf 'No IPv4 connectivity detected\n'
fi

printf '\n'

ipv6=$(curl -6 -s --max-time 5 http://icanhazip.com/)
if [ -n "$ipv6" ]
then
    printf 'IPv6 speedtests\n'
    printf '    your IPv6:    %s\n' $(printf '%s\n' $ipv6 | sed 's!\(\([0-9a-f]\+[.:]\)\{3\}\).\+!\1xxxx!')
    printf '\n'

    printf '    Leaseweb (NL):        '
    download_benchmark -6 http://mirror.nl.leaseweb.net/speedtest/100mb.bin | \
        Bps_to_MiBps

    printf '    Softlayer DAL (US):   '
    download_benchmark -6 http://speedtest.dal01.softlayer.com/downloads/test100.zip | \
        Bps_to_MiBps

    printf '    Online.net (FR):      '
    download_benchmark -6 http://ping6.online.net/100Mo.dat | \
        Bps_to_MiBps

    printf '    OVH BHS (CA):         '
    download_benchmark -6 http://proof.ovh.ca/files/100Mio.dat | \
        Bps_to_MiBps

else
    printf 'No IPv6 connectivity detected\n'
fi

printf '%s\n' '-------------------------'

printf '\n'

# delete downloaded ioping binary if script has been run straight from a pipe
# (rather than a downloaded file)
[[ -t 0 ]] || rm -f ioping.static
