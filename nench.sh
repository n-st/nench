#!/bin/bash

#####
# nench.sh ("new bench.sh")
# - based on the established freevps.us/bench.sh
# - modified to include CPU and ioping measurements and to reduce the number of
#   speedtests while retaining useful European and North American POPs
#####

wget -q -r http://bench.wget.racing/ioping.static -O ioping.static
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
    free -h | awk 'NR==4 {print $2}'
fi
printf 'Kernel:       '
uname -s -r -m

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
./ioping.static -R -w 5 /var/tmp | tail -n 2 | head -n 1

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

ipv4=$(wget -4qO- http://icanhazip.com/)
if [ -n "$ipv4" ]
then
    printf 'IPv4 speedtests\n'
    printf '    your IPv4:    %s\n' $ipv4
    printf '\n'

    printf '    Cachefly CDN:         '
    timeout 50 wget -4 -O /dev/null http://cachefly.cachefly.net/100mb.test 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    Leaseweb (NL):        '
    timeout 50 wget -4 -O /dev/null http://mirror.nl.leaseweb.net/speedtest/100mb.bin 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    Linode Dallas (US):   '
    timeout 50 wget -4 -O /dev/null http://speedtest.dallas.linode.com/100MB-dallas.bin 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    Online.net (FR):      '
    timeout 50 wget -4 -O /dev/null http://ping.online.net/100Mo.dat 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    OVH BHS (CA):         '
    timeout 50 wget -4 -O /dev/null http://proof.ovh.ca/files/100Mio.dat 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

else
    printf 'No IPv4 connectivity detected\n'
fi

printf '\n'

ipv6=$(wget -6qO- http://icanhazip.com/)
if [ -n "$ipv6" ]
then
    printf 'IPv6 speedtests\n'
    printf '    your IPv6:    %s\n' $ipv6
    printf '\n'

    printf '    Leaseweb (NL):        '
    timeout 50 wget -6 -O /dev/null http://mirror.nl.leaseweb.net/speedtest/100mb.bin 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    Linode Dallas (US):   '
    timeout 50 wget -6 -O /dev/null http://speedtest.dallas.linode.com/100MB-dallas.bin 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    Online.net (FR):      '
    timeout 50 wget -6 -O /dev/null http://ping6.online.net/100Mo.dat 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

    printf '    OVH BHS (CA):         '
    timeout 50 wget -6 -O /dev/null http://proof.ovh.ca/files/100Mio.dat 2>&1 | \
        awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); if (speed ~ /null/) {print "timeout (< 2MB/s)"} else {print speed}}'

else
    printf 'No IPv6 connectivity detected\n'
fi

