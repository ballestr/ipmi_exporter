# prometheus exporter for IPMI sensors

IPMI metrics are quite painful because they are not standardised at all.
Not only they change from one vendor to another, but the same vendor change naming conventions from one model to another, 
and sometimes they also change when upgrading BIOS or BMC firmware.

There is a commonly used IPMI exporter in Debian. It its symplicity it does work ok.  
The issue with it is that it has no knowledge whatsoever of what the sensors are on a piece of hardware and what their states mean,
so you end up with a ton of labels that convey very little meaning, and constructing meaningful dashboards with that is a futile effort.  
Trying to use relabeling in Prometheus to sort this out would get quite crazy if you have more than a handful of servers.

This exporter addresses that, by using a sensor mapping file installed on the host.
It's relatively straightforward to use a configuration management tool to deploy the correct sensor mapping for the specific type of hardware, so that the combination of the two allows for the correct and meaningful labeling of IPMI metrics.

## Contents

`debian_orig` is the `awk` based IPMI collector from Debian package `prometheus-node-exporter-collectors`

`ipmisensors.sh` is an adaptation of an metrics exporter that I originally wrote for Ganglia.

