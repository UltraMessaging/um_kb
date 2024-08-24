# LBT-RU Configuration

<!-- mdtoc-start -->
&bull; [LBT-RU Configuration](#lbt-ru-configuration)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [High-Level Considerations](#high-level-considerations)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [NAK Storms](#nak-storms)  
<!-- TOC created by './mdtoc.pl kb/lbt-ru-configuration.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

The Ultra Messaging LBT-RU transport protocol uses unicast UDP for messaging.
The UDP protocol does not guarantee packet ordering or provide automatic
retransmission of lost packets, so UM's LBT-RU protocol adds those features.

Starting in UM version 6.16, the DRO peer link now has a UDP feature called
"[UDP Peer Link](https://ultramessaging.github.io/currdoc/doc/Gateway/droarchitecture.html#udppeerlink)"
which leverages the same codebase as LBT-RU,
and is therefore configured roughly the same.
However, there are some issues unique to DRO peer links that deserve special consideratino.

## High-Level Considerations

There is no "one size fits all" configuration for LBT-RU.
We've set most defaults to suit a wide range of use cases,
but you should still evaluate these settings based on your specific needs.

Here are the characteristics of your use case that you should identify:
1. Expected average and peak message rates required.
2. Expected avarage and maximum message sizes being sent.
3. Expected maximum round-trip network latency between a publisher and a subscriber.
This can typically be ignored within a single data center,
but in the case of international WAN hops, round-trip latencies can grow to several hundred milliseconds.
4. Network bandwidth limitations. This can typically be assumed to be the servers' network connection
speed (usually 10 gig), but can be different for international WAN hops where data streams must be limited
below the servers' network connection speed. (Note that this is something that the TCP protocol adjusts
for dynamically. UDP does not.)

