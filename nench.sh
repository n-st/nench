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
time dd if=/dev/zero bs=1M count=500 2> /dev/null | \
    sha256sum > /dev/null

printf 'CPU: bzip2-compressing 500 MB\n    '
time dd if=/dev/zero bs=1M count=500 2> /dev/null | \
    bzip2 > /dev/null

printf 'CPU: AES-encrypting 500 MB\n    '
time dd if=/dev/zero bs=1M count=500 2> /dev/null | \
    openssl enc -e -aes-256-cbc -pass pass:12345678 > /dev/null

printf '\n'

# ioping
printf 'ioping: seek rate\n    '
./ioping.static -R -w 5 /var/tmp | tail -n 1
printf 'ioping: sequential speed\n    '
./ioping.static -RL -w 5 /var/tmp | tail -n 2 | head -n 1

printf '\n'

# dd disk test
printf 'dd test\n'

io1=$( ( dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
printf '    1st run:    %s\n' "$io1"

io2=$( ( dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
printf '    2nd run:    %s\n' "$io2"

io3=$( ( dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
printf '    3rd run:    %s\n' "$io3"

# Calculating avg I/O (better approach with awk for non int values)
ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
ioavg=$( awk 'BEGIN{print int(('$ioraw1' + '$ioraw2' + '$ioraw3')/3)}' )
printf '    average:    %d MB/s\n' "$ioavg"

printf '\n'

# Network speedtests

ipv4=$(curl -4 -s --max-time 5 http://icanhazip.com/)
if [ -n "$ipv4" ]
then
    printf 'IPv4 speedtests\n'
    printf '    your IPv4:    %s\n' $ipv4
    printf '\n'

    printf '    Cachefly CDN:         '
    curl -4 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://cachefly.cachefly.net/100mb.test | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    Leaseweb (NL):        '
    curl -4 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://mirror.nl.leaseweb.net/speedtest/100mb.bin | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    Softlayer DAL (US):   '
    curl -4 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://speedtest.dal01.softlayer.com/downloads/test100.zip | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    Online.net (FR):      '
    curl -4 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://ping.online.net/100Mo.dat | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    OVH BHS (CA):         '
    curl -4 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://proof.ovh.ca/files/100Mio.dat | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

else
    printf 'No IPv4 connectivity detected\n'
fi

printf '\n'

ipv6=$(curl -6 -s --max-time 5 http://icanhazip.com/)
if [ -n "$ipv6" ]
then
    printf 'IPv6 speedtests\n'
    printf '    your IPv6:    %s\n' $ipv6
    printf '\n'

    printf '    Leaseweb (NL):        '
    curl -6 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://mirror.nl.leaseweb.net/speedtest/100mb.bin | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    Softlayer DAL (US):   '
    curl -6 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://speedtest.dal01.softlayer.com/downloads/test100.zip | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    Online.net (FR):      '
    curl -6 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://ping6.online.net/100Mo.dat | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

    printf '    OVH BHS (CA):         '
    curl -6 --max-time 10 -so /dev/null -w '%{speed_download}\n' http://proof.ovh.ca/files/100Mio.dat | \
        awk '{ printf "%.2f MiB/s\n", $0 / 1024 / 1024 } END { if (NR == 0) { print "timeout (< 2MB/s)" } }'

else
    printf 'No IPv6 connectivity detected\n'
fi

printf '%s\n' '-------------------------'

printf '\n'

# delete downloaded ioping binary if script has been run straight from a pipe
# (rather than a downloaded file)
[[ -t 0 ]] || rm -f ioping.static
