# Configuring UDP-Based Transports

Elements of configuring LBT-RM and LBT-RU transports.

<!-- mdtoc-start -->
&bull; [Configuring UDP-Based Transports](#configuring-udp-based-transports)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Preparation](#preparation)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Retransmit Rate Limit](#retransmit-rate-limit)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Initial NAK Backoff Interval](#initial-nak-backoff-interval)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [NAK Backoff Interval](#nak-backoff-interval)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Ignore Interval](#ignore-interval)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Data Rate Limit and Rate Interval](#data-rate-limit-and-rate-interval)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Receiver Socket Buffer](#receiver-socket-buffer)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transmission Window](#transmission-window)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Source-Side Filtering (LBT-RU)](#source-side-filtering-lbt-ru)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Source Socket Buffer (LBT-RU)](#source-socket-buffer-lbt-ru)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [DRO Peer Link](#dro-peer-link)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Special Peer Link Considerations](#special-peer-link-considerations)  
<!-- TOC created by './mdtoc.pl kb/configuring-udp-based-transports.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article gives advice on configuring Ultra Messaging's UDP-based transport
protocols, LBT-RU and LBT-RM.
It assumes you are familiar with the basics of Ultra Messaging's messaging paradigm
and the basics of network data communication.

This article is mainly concerned with configuration related to packet loss prevention and recovery.

UM's LBT-RM and LBT-RU transport types use very similar algorithms,
and are typically configured in the same ways.
Much of this article will focus on LBT-RM, and an LBT-RU user should simply map
the concepts one-to-one.
Corresponding RU links will be included as "(RU)".

Note that this advice assumes the use of regular sources.
Users of
[Smart Sources](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#smartsources)
will need to use the corresponding Smart Source configuration options and
may need to make additional adjustments as well.
[Contact Support](https://ultramessaging.github.io/UM_Support.html) for assistance.

Related articles:
* [[Packet Loss]]
* [[Lost Packet Recovery]]
* [[NAK Storms]]

## Preparation

You should measure or predict the following characteristics of your UM use case:

1. Expected average and peak message rates,
per [transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions).
By "peak" we do not mean microbursts.
We mean short-term (a few seconds) rate, typically associated with some event, like a market open or close.
2. Expected average and maximum microburst duration and message rate.
Microbursts are typically on the order of single-digit milliseconds,
but can extend into several hundred milliseconds.
Message rate will typically be at or near the line rate of the publisher's network connection.
3. Expected average and maximum message sizes being sent. This should be periodically re-measured.
4. Expected maximum round-trip network latency between a publisher and a subscriber.
This can typically be ignored within a single data center,
but in the case of international WAN hops, round-trip latencies can grow to several hundred milliseconds.
5. End-to-end network bandwidth. This can typically be assumed to be the servers' network connection
speed (usually 10 gig),
but it can be different for international WAN hops where data streams must be limited
below the servers' network connection speed. (Note that this is something that the TCP protocol adjusts
for dynamically. UDP does not.)

All of the above should be periodically re-measured and
configuration options adjusted accordingly.

## Retransmit Rate Limit

To avoid [[NAK Storms]], you should set your
[transport_lbtrm_retransmit_rate_limit (context)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmoperation.html#transportlbtrmretransmitratelimitcontext) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtruoperation.html#transportlbtruretransmitratelimitcontext))
to less than 10% of the expected average message rate times the expected average messages size.
Note that this is *not* the same as the data rate limit, which is typically set higher than the expected
average data rate.

## Initial NAK Backoff Interval

To avoid [[NAK Storms]], you should set your
[transport_lbtrm_nak_initial_backoff_interval (receiver)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html#transportlbtrmnakinitialbackoffintervalreceiver) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtrunakinitialbackoffintervalreceiver))
to the maximum expected traffic burst duration plus the round-trip network latency between a publisher and a subscriber.

This adds some latency to the recovery, but helps to avoid [[NAK Storms]].
The reason for the addition of the round-trip network latency is to allow NAK suppression to be effective.

## NAK Backoff Interval

We recommend leaving the [transport_lbtrm_nak_backoff_interval (receiver)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html#transportlbtrmnakbackoffintervalreceiver) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtrunakbackoffintervalreceiver))
at its default value.
If you do change it, ensure that it is not less than the initial NAK backoff interval.

## Ignore Interval

To avoid unnecessary repair delay and NCFs, you should set your
[transport_lbtrm_ignore_interval (source)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html#transportlbtrmignoreintervalsource) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtruignoreintervalsource))
to 1/2 your NAK Backoff Interval.

If you follow our recommendation of leaving the NAK Backoff Interval at its default of 200 ms,
you should set your ignore interval to 100.
Note that it does not default to 100; you need to set it.

## Data Rate Limit and Rate Interval

To avoid [[NAK Storms]], you should set your
[transport_lbtrm_data_rate_limit (context)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmoperation.html#transportlbtrmdataratelimitcontext) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtruoperation.html#transportlbtrudataratelimitcontext))
and
[transport_lbtrm_rate_interval (context)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmoperation.html#transportlbtrmrateintervalcontext) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtruoperation.html#transportlbtrurateintervalcontext))
according to the procedure listed in
[Decrease Packet Rate Using Rate Limiter](https://ultramessaging.github.io/um_kb/html/packet-loss.html#decrease-packet-rate-using-rate-limiter).

Note that the default value for the data rate limiter is 10 megabits/sec,
which is almost certainly too low for most real-world use cases.

Also note that
[Smart Sources](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#smartsources)
do not support data rate limits.
To minimize the chances of packet loss and [[NAK storms]],
it becomes the publishing application's responsibility to control its send rate.

## Receiver Socket Buffer

To avoid [[NAK storms]], you should set your
[transport_lbtrm_receiver_socket_buffer (context)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html#transportlbtrmreceiversocketbuffercontext) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtrureceiversocketbuffercontext))
to somewhere between 8MB and 128MB.
Unfortunately, we have not found an analytical method for calculating
the optimal socket buffer size.
But in our practical experience with our users, a 10gig network should have
at least 20 MB for average workflows, and much higher for heavy workflows.

For example, one of our customers has a twice-daily burst of messages at
full 10G line rate for 700 ms.
This customer uses 128 MB socket buffers and rarely has packet loss.

Remember that the operating system does not statically allocate the
requested socket buffer size.
Rather, it allows the socket buffer to grow to that size before
dropping packets.
So it only uses that much memory if it needs to.

## Transmission Window

To avoid unrecoverable transport loss, you should set your
[transport_lbtrm_transmission_window_size (source)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html#transportlbtrmtransmissionwindowsizesource) ([RU](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtrutransmissionwindowsizesource))
to a minimum of:
```
(peak_message_rate * avg_message_size) * (initial_nak_backoff + 3*nak_backoff + 2*max_round_trip)
```
For example, a peak message rate of 80,000 msgs/sec, average message size of 600 bytes,
initial NAK backoff of .09 sec, nak_backoff of .2 sec, round-trip time of 0 (assume no WAN):
```
(80,000 * 600) * (.09 + .6) = 33,120,000
```

## Source-Side Filtering (LBT-RU)

For LBT-RU, you should set your
[transport_source_side_filtering_behavior (source)](https://ultramessaging.github.io/currdoc/doc/Config/grpmajoroptions.html#transportsourcesidefilteringbehaviorsource)
to "inclusion".
This prevents un-subscribed topics from being sent to the receiver.

## Source Socket Buffer (LBT-RU)

For LBT-RU, you should set your
[transport_lbtru_source_socket_buffer (context)](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrureliability.html#transportlbtrusourcesocketbuffercontext)
to 1,000,000 plus 100,000 times the number of subscribers expected to join.
For example, if you expect 8 subscribers to join the source,
```
1000000 + 100000 * 8 = 1800000
```

## DRO Peer Link

The
[UM Dynamic Routing Option (DRO)](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#umrouter)
can be configured for a
[UDP Peer Link](https://ultramessaging.github.io/currdoc/doc/Gateway/droarchitecture.html#udppeerlink).
This peer link uses the same underlying protocols and code base as the LBT-RU transport type.
However, because it is not associated with regular UM sources and receivers,
it must be configured using the DRO's XML configuration file,
and the configuration options are somewhat different.

The [Router Element "&lt;udp>"](https://ultramessaging.github.io/currdoc/doc/Gateway/xmlconfigurationreference.html#droelementudp)
element has children elements that specify the LBT-RU operating parameters.

For example,
[Router Element "&lt;peer-rate-limit>"](https://ultramessaging.github.io/currdoc/doc/Gateway/xmlconfigurationreference.html#droelementpeerratelimit)
has attributes that control the rate limiter. For example:
```
<portals>
  <peer>
    ...
    <udp>
      ...
      <peer-rate-limit data="10000000" retransmit="5000000" interval="100"/>
    </udp>
  </peer>
  ...
</portals>
```
This is the equivalent of:
```
context transport_lbtru_data_rate_limit 10000000
context transport_lbtru_retransmit_rate_limit 5000000
context transport_lbtru_rate_interval 100
```

### Special Peer Link Considerations

When configuring a UDP peer link for a pair of DROs,
all the same considerations must be made as are discussed above.
However, pay special attention to the items that include network round-trip time,
such as NAK backoff times and transmission window.
For DROs that are widely separated, larger values for both are generally advised.

Also, to ensure a lossless utilization, you should divide up the available bandwidth
and limit each app that sends over the WAN to its share of the bandwidth using
UM's rate limiter.
See 
[Decrease Packet Rate Using Rate Limiter](https://ultramessaging.github.io/um_kb/html/packet-loss.html#decrease-packet-rate-using-rate-limiter).
