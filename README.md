nench.sh ("new bench.sh")
=========================

Current version always available at https://github.com/n-st/nench

IPv4- and v6-enabled download at http://wget.racing/nench.sh

- loosely based on the established freevps.us/bench.sh
- includes CPU and ioping measurements
- reduced number of speedtests (9 x 100 MB), while retaining useful European
  and North American POPs
- runs IPv6 speedtest by default (if the server has IPv6 connectivity)
- has a 50-second timeout for each speedtest, so you don't end up waiting 10
  minutes for that one slow speedtest from halfway around the globe
  (this means that any speedtest result < 2 MB/s will be squelched)

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
