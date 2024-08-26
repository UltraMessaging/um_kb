# NAK Storms

NAK storms: the what, why, and now to avoid.

<!-- mdtoc-start -->
&bull; [NAK Storms](#nak-storms)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [What Is a NAK Storm](#what-is-a-nak-storm)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [NAK Storm Prevention](#nak-storm-prevention)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Reduce Packet Loss to Near Zero](#reduce-packet-loss-to-near-zero)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Upgrade to a Recent Version of UM](#upgrade-to-a-recent-version-of-um)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Proper Configuration](#proper-configuration)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Control the Size of a UM Network](#control-the-size-of-a-um-network)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Prevention Vs. Avoidance](#prevention-vs-avoidance)  
<!-- TOC created by './mdtoc.pl kb/nak-storms.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article describes what NAK storms are, their causes, and how
to avoid them.
It assumes you are familiar with
the basics of network data communication
and the basics of Ultra Messaging's NAK-based lost packet recovery protocols
See [[Lost Packet Recovery]] for an overview.

Related articles:
* [[Packet Loss]]
* [[Lost Packet Recovery]]
* [[Configuring UDP-Based Transports]]

## What Is a NAK Storm

All NAK-based UDP protocols (such as Informatica's LBT-RM and LBT-RU) carry some risk of
a "NAK storm," which is defined as a condition where the lost packet recovery protocols
overload the network and/or host infrastructure such that the packet recovery work itself
causes packet loss. This can produce a self-reinforcing feedback loop where loss triggers
loss recovery, which causes additional loss, which triggers more loss recovery, etc.

This self-reinforcing feedback loop is a NAK storm.

It is important to differentiate between successful lost packet recovery and a NAK storm,
given that both can have significant numbers of NAKs sent.
A packet loss incident is generally caused by a temporary burst of incoming network traffic that
overloads a network device, a host's IP drivers, or an application.
During this incoming traffic-based overload, packet loss is inevitable.
The question is: what happens when the incoming traffic burst subsides and returns to normal?

In a successful lost packet recovery, NAKs can continue for hundreds of milliseconds
after incoming traffic returns to normal, possibly multiple seconds.
But importantly, during this recovery period, there should be no new packets lost,
or at least very few.
The lack of significant packet loss after the incoming traffic burst subsides is a sign that UM is
proceeding normally with lost packet recovery.

However, if high packet loss persists after the incoming traffic burst subsides,
this is evidence of a NAK storm.
The packet recovery messages are added to the "normal" incoming traffic.
If the sum of the packet rates of normal traffic plus packet recovery is high enough,
the overload condition can be sustained, and the NAK storm becomes time unbounded.

## NAK Storm Prevention

By definition, a NAK storm is characterized by the lost packet recovery protocols causing
overload and packet loss.
This is usually in the form of extra packets exchanged on the network: control packets
(like NAKs and NCFs) and retransmissions of lost packets.

UM has features intended to prevent NAK storms from happening.
These features will only be effective if the user follows certain guidelines.

### Reduce Packet Loss to Near Zero

The best way to prevent NAK storms is to prevent packet loss.
See [[Packet Loss]] for instructions on reducing and possibly eliminating packet loss.

### Upgrade to a Recent Version of UM

We make frequent improvements to UM that can reduce the chances of a NAK storm.
In particular:

1. UM version 6.9 fixes a problem with the
[Receive Multiple Datagrams](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivemultipledatagrams)
feature. This feature can improve receiver efficiency, reducing the probability of packet loss due to socket buffer overflow.
2. UM version 6.10 contains improvements to NCF handling (see
[NAK Suppression](https://ultramessaging.github.io/currdoc/doc/Design/transporttypes.html#naksuppression)).
This significantly reduces the probability of NAK storms.
3. UM version 6.12 improves receiver efficiency when using the
[Receive Buffer Recycling](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivebufferrecycling)
feature, reducing the probability of packet loss due to socket buffer overflow.
4. UM version 6.15 improves receiver efficiency when using the
[Receive Multiple Datagrams](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivemultipledatagrams)
feature, reducing the probability of packet loss due to socket buffer overflow.

For NAK storm prevention, UM version 6.10 (#2 above) is the most important.

### Proper Configuration

Proper configuration of sources and receivers will reduce the chances of
NAK storms.
See [[Configuring UDP-Based Transports]].

### Control the Size of a UM Network

When multiple UM subscribers experience packet loss, each subscriber must
invoke its lost packet recovery protocols. The most visible part of this
is the sending of NAKs, which triggers the publisher to re-transmit the lost
datagrams.

UM has specific algorithms to avoid unnecessarily retransmitting the same missing
datagram multiple times.
These algorithms decrease in their effectiveness under two conditions:

1. The number of subscribers becomes too large.
2. The round-trip network latency between publisher and subscriber becomes too large.

There is no simple number that represents "too large" because it depends heavily on
message rates and configuration. However, as a rule of thumb, UM's lost packet recovery
algorithms work best when there are less than 1000 subscribers, and the round-trip
network latency between publisher and subscriber is under 50 ms.

These two factors are also interrelated. For example, a much larger round-trip latency
is acceptable if the number of subscribers is much smaller (and vice versa).

For users with larger scales, we recommend subdividing your network into
multiple
[Topic Resolution Domains (TRDs)](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#topicresolutiondomain)
and using our
[Dynamic Routing Option (DRO)](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#umrouter)
component to pass messages between the TRDs. A common way of subdividing a
large network that spans multiple geographically dispersed data centers is to
define each data center as a TRD and use DROs to interconnect them.
[Contact Support](https://ultramessaging.github.io/UM_Support.html)
for advice on how to implement this.

## Prevention Vs. Avoidance

While it is possible to fully prevent NAK storms from happening,
the required tradeoffs are sometimes too costly.
For example, getting packet loss close to zero requires that publishers
be configured to block if they burst their data too intensely.
But some applications cannot tolerate blocking sends - they *must*
send their messages immediately.

The alternative to full prevention is to over-provision your systems.
Ensure your applications can handle double or triple the expected message rate.
Make sure that each data flow has only the messages required by each subscriber.
Ensure that the probability of all publishers bursting to their maximum rate at
the same time is close to zero, and that the duration of their bursts is
controlled.
And when packet loss does happen, don't configure aggressive data recovery.
Keep the retransmission rate limits low.
This will add undesired latency if packet loss does happen,
but if you've done your work well, packet loss will be rare enough that
occasional recovery latencies are worth the benefit of a stable network.
