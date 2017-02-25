nench.sh ("new bench.sh")
=========================

- based on the established freevps.us/bench.sh
- modified to include CPU and ioping measurements and to reduce the number of
  speedtests while retaining useful European and North American POPs

Usage example
-------------

```
(curl bench.wget.racing | bash; curl bench.wget.racing | bash) | tee nench.log
```
