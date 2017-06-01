nench.sh ("new bench.sh")
=========================

Current version always available at https://github.com/n-st/nench

IPv4- and v6-enabled download at http://wget.racing/nench.sh

- loosely based on the established freevps.us/bench.sh
- includes CPU and ioping measurements
- reduced number of speedtests (9 x 100 MB), while retaining useful European
  and North American POPs
- runs IPv6 speedtest by default (if the server has IPv6 connectivity)
- has a 10-second timeout for each speedtest, so you don't end up waiting 10
  minutes for that one slow speedtest from halfway around the globe — but
  thanks to the power of `curl -w`, you still get to see what speed your server
  achieved during those 10 seconds
- successfully tested on Arch Linux, Debian, FreeBSD, and Ubuntu

The script was originally intended to be used only by me, so I didn't put much
effort into ensuring safety, security, and interoperability.  
I welcome any improvements, just send me a pull request.

Disclaimer
----------

You've probably noticed that the usage examples below have you directly run a
script from an unauthenticated source (as so many "easy-install" and benchmark
scripts do).

I didn't think I'd have to mention that this is a **potential security risk** —
really, if you're at the point where you're benchmarking Linux VMs, I would
assume you know how much harm a rogue shell script could potentially do to your
system…

What's more, `nench.sh` downloads a statically built binary to run the IO
latency tests. I assure you it is and always will be a clean unmodified build
of `ioping`, but how do you know you can trust me?

So, basically: **use `nench.sh` at your own risk**, and preferably not on
production systems (which is a bad idea anyway, because it will hammer your
harddisk and network for up to several minutes).

Usage example
-------------

```
(curl -s wget.racing/nench.sh | bash; curl -s wget.racing/nench.sh | bash) 2>&1 | tee nench.log
```

```
(wget -qO- wget.racing/nench.sh | bash; wget -qO- wget.racing/nench.sh | bash) 2>&1 | tee nench.log
```

Example output
--------------

Output from a VPS hosted with Vultr in Frankfurt:

```
-------------------------------------------------
 nench.sh v2017.05.08 -- https://git.io/nench.sh
 benchmark timestamp:    2017-05-08 20:36:54 UTC
-------------------------------------------------

Processor:    Virtual CPU a7769a6388d5
CPU cores:    1
Frequency:    2394.454 MHz
RAM:          494M
Swap:         871M
Kernel:       Linux 3.16.0-4-amd64 x86_64

Disks:
vda  20G  HDD

CPU: SHA256-hashing 500 MB
    4.183 seconds
CPU: bzip2-compressing 500 MB
    6.830 seconds
CPU: AES-encrypting 500 MB
    1.636 seconds

ioping: seek rate
    min/avg/max/mdev = 148.6 us / 280.9 us / 9.22 ms / 234.7 us
ioping: sequential speed
    generated 2.15 k requests in 5.00 s, 536.2 MiB, 428 iops, 107.2 MiB/s

dd test
    1st run:    339.51 MiB/s
    2nd run:    345.23 MiB/s
    3rd run:    342.37 MiB/s
    average:    342.37 MiB/s

IPv4 speedtests
    your IPv4:    108.61.179.xxxx

    Cachefly CDN:         205.34 MiB/s
    Leaseweb (NL):        140.55 MiB/s
    Softlayer DAL (US):   0.08 MiB/s
    Online.net (FR):      0.17 MiB/s
    OVH BHS (CA):         11.13 MiB/s

IPv6 speedtests
    your IPv6:    2001:19f0:6c01:xxxx

    Leaseweb (NL):        101.06 MiB/s
    Softlayer DAL (US):   2.89 MiB/s
    Online.net (FR):      0.18 MiB/s
    OVH BHS (CA):         9.84 MiB/s
-------------------------------------------------
```
