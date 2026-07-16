# Configuring RSS

Elements of configuring Linux's Receive-Side Scaling (RSS) for Ultra Messaging

<!-- mdtoc-start -->
&bull; [Configuring RSS](#configuring-rss)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [IP Fragmentation](#ip-fragmentation)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Linux RSS](#linux-rss)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [4-tuple Hash Performs Poorly with IP Fragmentation](#4-tuple-hash-performs-poorly-with-ip-fragmentation)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [2-tuple Hash Performs Better](#2-tuple-hash-performs-better)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Why Do IP Fragmentation?](#why-do-ip-fragmentation)  
<!-- TOC created by './mdtoc.pl kb/configuring-rss.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article gives advice on configuring Linux's Receive-Side Scaling (RSS) for UDP-based Ultra Messaging transports.
It assumes you are familiar with the basics of Ultra Messaging's messaging paradigm
and the basics of network data communication.

This article assumes you are NOT using a kernel-bypass network driver, like Onload.
The concepts still apply, but the UM configurations for those use cases differ significantly.

## IP Fragmentation

UM's LBT-RM and LBT-RU transports use UDP datagrams.
UM can be configured for different max datagram sizes
([LBT-RM](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmoperation.html#transportlbtrmdatagrammaxsizecontext),
[LBT-RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtruoperation.html#transportlbtrudatagrammaxsizecontext)),
which affects how UM [creates datagrams](https://ultramessaging.github.io/currdoc/doc/Design/architecture.html#messagefragmentationandreassembly).
By default, UM datagrams are limited to 8192 bytes.
Notice that this is larger than the standard Ethernet MTU of 1500 bytes.
When UM sends a datagram larger than an MTU,
the kernel's IP layer will fragment the datagram into multiple packets,
which the receiving kernel will reassemble into a contiguous datagram for delivery to UM.

Therefore, by default, messages larger than an MTU will undergo IP fragmentation.

## Linux RSS

Many high-performance network controllers support Receive-Side Scaling (RSS).
One function of RSS is to improve network throughput by spreading processing
of different UDP data flows to different CPU cores,
allowing greater parallelism.
A "flow hash" is used by the hardware to steer packets to different CPU cores
(via receive queues) based on a configurable set of fields within the packets.
The default flow hash for most server-grade NICs is a 4-tuple hash that
includes source IP, destination IP, source port, and destination port.

## 4-tuple Hash Performs Poorly with IP Fragmentation

The problem with the standard 4-tuple hash is that when a UDP datagram exceeds MTU and the kernel
produces IP fragments, only the first packet in the fragment set contains the UDP ports.
Subsequent packets contain user data at the packet offsets normally used for UDP ports.
This causes the hash function to direct different fragments of the same datagram to different CPU cores.

This does not cause failures - the kernel still reassembles the datagram - but fragments landing on
different CPUs contend for the shared IP reassembly table, adding lock and cache-coherence overhead.
The result is out-of-order delivery and elevated latency, sometimes on the order of tens of milliseconds.

So while sending large UM datagrams (and letting the kernel fragment them) can improve throughput on
the sending side, the resulting fragments can degrade performance on the receiving side.

## 2-tuple Hash Performs Better

By configuring the hash to only use source and destination IP addresses,
all the packets of a given fragmented datagram will be hashed to the same CPU core.

For example, if your interface device name is "eth1":
```bash
$ sudo ethtool -N eth1 rx-flow-hash udp4 sd
```
"sd" is the abbreviation for source and destination IP.

**NOTE**: We recommend doing this during a quiet period
to minimize the risk of disruption.

You can also read what your current settings are:
```bash
$ ethtool -n eth1 rx-flow-hash udp4
UDP over IPV4 flows use these fields for computing Hash flow key:
IP SA
IP DA
```
It only shows two IP lines, so the ports are not being included in the hash.

If you want to return it to the 4-tuple setting:
```bash
$ sudo ethtool -N eth1 rx-flow-hash udp4 sdnr
```
The "sdnr" means IPs and ports.

Different Linux distributions and versions use different methods to make that
ethtool setting permanent (survive a reboot).
See your version's documentation.

## Why Do IP Fragmentation?

Kernel-level IP fragmentation can provide a significant improvement in throughput.
The alternative would be to lower the datagram max size such that IP fragmentation would never happen.
Then, if you have a 5000-byte message to send,
UM would need to break it into four MTU-sized datagrams and send each one separately.
That's four kernel calls, which is expensive.

Note that the issue also depends on an application's UM usage pattern.
For example, if an application never sends messages greater than 1 KB and
flushes each message (no batching), UM will never send a datagram larger than an MTU,
and the kernel will never fragment the datagram.
There will be no performance degradation.
However, this use case also does not benefit from kernel call reduction,
and therefore will have a lower maximum throughput than if larger datagrams
could be used.
See [Message Batching](https://ultramessaging.github.io/currdoc/doc/Design/architecture.html#messagebatching)
for techniques that can leverage large datagrams to improve maximum throughput.
