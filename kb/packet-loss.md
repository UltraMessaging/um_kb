# Packet Loss

Overview of the causes and treatments for packet loss.

<!-- mdtoc-start -->
&bull; [Packet Loss](#packet-loss)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Causes of Packet Loss](#causes-of-packet-loss)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Avoiding Packet Loss](#avoiding-packet-loss)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Decrease Packet Flow Through Loss Points](#decrease-packet-flow-through-loss-points)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Increase Efficiency of Packet Consumers](#increase-efficiency-of-packet-consumers)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Decrease Packet Rate Using Rate Limiter](#decrease-packet-rate-using-rate-limiter)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Many Subscribers to Few Receivers](#many-subscribers-to-few-receivers)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Proper Configuration](#proper-configuration)  
<!-- TOC created by './mdtoc.pl kb/packet-loss.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article gives an overview of what causes network packet loss and how to treat it.
It assumes you are familiar with the basics of Ultra Messaging's messaging paradigm
and the basics of network data communication.

Related articles:
* [[Lost Packet Recovery]]
* [[Configuring UDP-Based Transports]]
* [[NAK Storms]]

## Causes of Packet Loss

See [Packet Loss Points](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html#packetlosspoints).

## Avoiding Packet Loss

Everybody's goal should be to reduce packet loss as much as possible.
There are four methods of avoiding packet loss:

* Decrease Packet Flow Through Loss Points.
* Increase Efficiency of Packet Consumers.
* Decrease Packet Rate Using Rate Limiter.
* Proper Configuration.

### Decrease Packet Flow Through Loss Points

* [Message Batching](https://ultramessaging.github.io/currdoc/doc/Design/architecture.html#messagebatching).
At most loss points, the number of packets is usually more important than the sizes of the packets.
100 packets of 60 bytes each is much more burdensome to packet consumers than 10 packets of 600 bytes each.
For latency-sensitive applications, consider implementing an
[Intelligent Batching](https://ultramessaging.github.io/currdoc/doc/Design/architecture.html#intelligentbatching)
algorithm.

* Reduce UM discards. Due to how publishers map topics to
[Transport Sessions](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions),
the receiver may have to discard messages it hasn't subscribed to.
The
[LBT-RM transport statistics](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__t__stct.html)
structure for each transport type contains the field "lbm_msgs_no_topic_rcved" which counts the number of data messages discarded.
Also, the
[context statistics](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html)
structure contains the field "lbtrm_unknown_msgs_rcved", which also counts data messages discarded.

  For the LBT-RU transport type, you can get similar discards.
  See the
  [LBT-RU transport statistics](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html)
  structure field "lbm_msgs_no_topic_rcved", and the
  [context statistics](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html)
  structure field "lbtru_unknown_msgs_rcved".

  For the TCP or LBT-RU transport types, you can often decrease discards by turning on
  [Source-Side Filtering](https://ultramessaging.github.io/currdoc/doc/Config/grpmajoroptions.html#transportsourcesidefilteringbehaviorsource).

  With Multicast, the Source-Side Filtering feature is not possible.
  So it is usually necessary to change the topic-to-transport session mapping.
  Ideally, this can be done by taking into account the topic interests of the subscribers.
  But often, it simply means increasing the number of transport sessions.
  In the case of LBT-RM, increasing the number of multicast groups is preferred, but is often limited by the network hardware.
  In that case, you can multiply the number of transport sessions by varying the destination port.

* Limit the packet transmission rate with the UM rate limiter.
With the previous methods, you can reduce the probability of getting loss,
but you still might be operating "close to the edge" such that an unexpected burst of traffic will
cause an overload and packet loss.
The UM rate limiter is intended to reduce the chances of loss close to zero.
See [Decrease Packet Rate Using Rate Limiter](#decrease-packet-rate-using-rate-limiter).

### Increase Efficiency of Packet Consumers

Here are some methods for increasing the efficiency of subscribers:
* Use a [kernel-bypass driver](https://ultramessaging.github.io/currdoc/doc/Design/umglossary.html#glossarykernelbypass).
* For Linux, use [Receive Multiple Datagrams](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivemultipledatagrams).
* Use [Receive Buffer Recycling](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivebufferrecycling).
* For Java and .NET, use [Zero Object Delivery](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#zeroobjectdelivery).
* Consider using a
[Kernel-Bypass Driver](https://ultramessaging.github.io/currdoc/doc/Design/umglossary.html#glossaryk)
(e.g. Onload).
This reduces latency and helps prevent packet loss.
* Migrate to
[TCP-Based Topic Resolution](https://ultramessaging.github.io/currdoc/doc/Design/topicresolutiondescription.html#tcpbasedtopicresolutiondetails).
This reduces jitter and helps prevent packet loss.
* Consider using the
[XSP](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#transportservicesproviderxsp)
feature, especially if you are not using
[TCP-Based Topic Resolution](https://ultramessaging.github.io/currdoc/doc/Design/topicresolutiondescription.html#tcpbasedtopicresolutiondetails).
This reduces jitter and helps prevent packet loss.
* Do not use the
[MIM](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#multicastimmediatemessaging)
feature.
* Be careful with the use of the
[Hot Failover](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#hotfailoverhf)
feature as this will double load on the host's operating system and Ultra Messaging.

These steps, plus optimizing your own message handling code, will enable your subscribers to increase their message
consumption rate without packet loss.
However, as long as your publishers can exceed your subscribers' rate, packet loss is still possible.

### Decrease Packet Rate Using Rate Limiter

It is usually possible for publishers to outpace subscribers, especially when multiple publishers feed a single subscriber.
For example, if multiple client gateways can send to the same order handling process,
it is possible that all of them burst at the same time, overloading the order handler.
To avoid packet loss, those publishers should be prevented from bursting at dangerous rates.

Note that
[Smart Sources](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#smartsources)
do not support rate limits.
To minimize the chances of packet loss and [[NAK storms]],
it becomes the publishing application's responsibility to control its send rate.

1. Measure your subscribers' maximum sustainable message rate (MSMR).
This is usually done empirically by sending test data at progressively
higher rates until you start getting loss.
See [Verifying Loss Detection Tools](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html#verifyinglossdetectiontools)
for information on detecting when that loss happens.
With UDP-based transports, you should run for more than a full minute without loss.
See notes [a] and [b].

2. Identify the sources that will be sending messages to the subscriber.
Let's say there are two publishers, A and B.
Set each publisher's rate limit to 40% of the subscriber's MSMR
(never allow the average send rates to exceed 80% of the MSMR).
Note that this will block the sender if it attempts to exceed this average rate.

3. Traffic tends to be bursty.
You want to allow brief traffic surges above the MSMR so long as
subsequent slower periods bring the average below the MSMR.
This is configured using the rate interval.
A larger rate interval allows longer, more intense bursts,
while a smaller value forces smoother, less-bursty traffic
(at the expense of potentially blocking the sender).
See notes [c] and [d].

NOTES:

**[a]**: Measuring the maximum sustainable message rate (MSMR) can be difficult if
you don't have a consistent execution environment.
For example, if you don't assign your hot threads to specific CPU cores,
your operating system will migrate your threads between cores,
even across NUMA zones, preventing optimal cache and memory usage.
A rate that is easily handled in one test run can cause packet loss in the next.
This measurement can be even harder to characterize if different message types
require different amounts of time to consume.

**[b]**: Your subscriber might handle different message types that require different times to consume.
How do you measure the maximum sustainable message rate in this case?
You might be able to statistically say that X% of messages are type 1 and Y%
are type 2, but unless you can guarantee this breakdown, it is usually safest to
assume 100% of your messages are of the type that requires the maximum consumption time.

**[c]**: The rate interval should be set explicitly according to your needs.
A rate limiter of 500 megabits/sec will essentially be divided into N
equal periods of the rate interval milliseconds each.
During each interval, the application is allowed to send up to
the rate limiter/N bits of data. This can be at the full line rate.
You can allow more intense bursts by increasing the rate interval,
thus decreasing the number N.

**[d]**: The UM documentation warns you against setting the rate interval
to values other than the specific set listed, ranging from 5 to 100.
A rate interval of 100 divides each second into 10 periods (N=10).
If this value blocks your publisher too much,
you can extend it to 200, 500, or possibly even 1000.
However, be aware that this allows the publisher to send very intense
bursts that might lead to queue overflows at
[packet loss points](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html#packetlosspoints)
with small queues,
especially if multiple publishers burst at the same time.
You should test your publishers sending "as fast as they can,"
only constrained by the UM rate limiter.
This will produce the worst-case bursts for the duration of the test.

#### Many Subscribers to Few Receivers

The principle of restricting N publishers to 1/N the maximum sustainable message rate (MSMR)
of the subscriber may not be practical in some use cases.
If N becomes large, the permitted send rates may be too low for your system to function effectively.
In that case, you may have to assume a statistical behavior.
I.e., as N grows, the probability of all of them bursting simultaneously becomes small.
In that case, many users set their rate limiters higher than suggested,
confident that the aggregate rate of the N publishers won't exceed the MSMR for
longer than the queues can hold.

Just be aware that low-probability events do happen occasionally.
UM's [[Lost Packet Recovery]] should handle these occasional loss incidents,
but you will always have some risk of [[NAK Storms]].

### Proper Configuration

Proper configuration of sources and receivers will reduce the chances of
loss and [[NAK storms]].
See [[Configuring UDP-Based Transports]].
