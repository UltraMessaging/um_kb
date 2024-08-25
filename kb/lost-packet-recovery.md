# Lost Packet Recovery

Overview of Ultra Messaging's lost packet recovery protocol.

<!-- mdtoc-start -->
&bull; [Lost Packet Recovery](#lost-packet-recovery)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Packet Loss Prevention](#packet-loss-prevention)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Recovery Protocols](#recovery-protocols)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [UDP-Based Transport Recovery](#udp-based-transport-recovery)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Delivery Controller Recovery](#delivery-controller-recovery)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Proper Configuration](#proper-configuration)  
<!-- TOC created by './mdtoc.pl kb/lost-packet-recovery.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article gives an overview of Ultra Messaging's lost packet recovery protocol.
It assumes you are familiar with the basics of Ultra Messaging's messaging paradigm
and the basics of network data communication. If any of the following are unfamiliar,
[contact Support](https://ultramessaging.github.io/UM_Support.html) for assistance.
* A UM publisher sends messages to a
[topic](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#topicstructureandmanagement).
The publisher uses a configurable
[transport type](https://ultramessaging.github.io/currdoc/doc/Design/transporttypes.html)
to send the messages.
* The publisher must map topics onto
"[transport sessions](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions)".
* A UM subscriber receives messages on a topic basis.
* A packet is the smallest unit of data to flow through a network.
* A switch is a network device that hosts connect to and transports packets between hosts.
* A NIC (Network Interface Card) is a device in the host that communicates with a switch.
* A network driver is a software stack, usually part of the operating system, that provides
an IP-based protocol layer on the network hardware. Note that the network driver can also
be in user space, for example,
"[Onload](https://github.com/Xilinx-CNS/onload)".
* TCP and UDP are higher-level protocols implemented by the network driver.
* A datagram is a UDP-based message, frequently contained in a single packet,
but sometimes is
[fragmented](https://ultramessaging.github.io/currdoc/doc/Design/umglossary.html#glossaryipfragmentation)
by IP into multiple packets that are reassembled on the
receiving host.
UM normally deals in datagrams, not packets.
* [Multicast](https://en.wikipedia.org/wiki/Multicast)
is a packet addressing scheme for networks where a single packet sent into the
network is replicated by the network and delivered to multiple hosts that are joined
to the multicast address (more properly, "multicast group").

Related articles:
* [[Configuring UDP-Based Transports]]
* [[Packet Loss]]
* [[NAK Storms]]

## Packet Loss Prevention

Everybody should have as their goal to reduce or eliminate packet loss
as much as possible.
See [[Packet Loss]].

But it is usually not possible to completely eliminate all possibility
of packet loss.
In most networks, the most common failure is packet loss.
I.e., a publishing application sends a message,
and the packets never make it to the subscribing application.

Packet loss usually occurs in one of two ways:
* Sporadic packet loss, when some, but not all, sent packets fail to reach their destination,
usually due to network or host overload.
See [Packet Loss Points](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html#packetlosspoints).
* Connectivity failure, resulting in loss of all sent packets,
often caused by malfunctioning hardware such as NIC, switch, router, or WAN link failures.

Packet loss generally happens in "incidents" that are limited in duration.
Sporatdc packet loss might last a few tens of milliseconds to many seconds.
Connectivity failures are typically longer, lasting anywhere from a several seconds to
many hours.

Note that the TCP protocol implements its own lost packet recovery protocol
independent of UM, and usually recovers sporadic loss.
But connectivity failures that last too long will result in TCP disconnects,
with the result that when the connectivity failure is repaired, the messages sent
during the incident will not be automatically recovered by the TCP protocol.

In contrast, UDP-based protocols (like UM's LBT-RU and LBT-RM) 
implement their own reliability protocol that performs the same function as
TCP in recovering lost packets.
Note that UM's UDP-based reliability protocols can provide lower latency and
higher average throughput than TCP in networks where low levels of sporadic loss are endemic.

## Recovery Protocols

UM's lost packet recovery protocols are divided into two layers:
transport protocol and delivery controller.

The transport protocol's recovery is targeted primarily at sporadic packet loss.
The details of the recovery protocols vary depending on the source protocol selected.
For example, the LBT-TCP protocol simply leverages TCP's recovery,
while LBT-RM and LBT-RU use a NAK-based recovery protocol.

The delivery controller recovery layer generally functions when the transport layer
fails to recover.  For example:
* The LBT-TCP protocol might suffer a disconnection due to a long-lasting connectivity failure.
* The LBT-RM protocol's configured recovery time limit is exceeded.
* The subscribing application crashes and restarts.

### UDP-Based Transport Recovery

The LBT-RU and LBT-RM transports have almost identical lost packet recovery protocols.
This section applies to both.

Application messages are inserted into a UM datagram that contains
a transport sequence number specific to the transport session
that the message's topic is mapped to.
This is not the sequence number that is visible to the application;
it is only visible in packet captures.

A subscriber detects loss as a gap in sequence numbers.
I.e., it has to have successfully received messages before
the loss incident and after to see the gap.
* Head loss is defined as packet loss that happens before the first
successfully received datagram. It can sometimes be avoided by
delaying a publisher from sending after it has created its source.
* Tail loss is defined as packet loss that happens after the last
successfully received datagram.
It can sometimes be avoided by delaying the deletion of a publisher
after it has finished sending but before it deletes its source.

UM's transport recovery does not detect or attempt to recover from
head loss or tail loss,
although the Delivery Controller recovery can.

When a subscriber detects a sequence number gap, here is the sequence
of operations performed by the transport recovery protocol:
1. As the publisher sends datagrams, they are saved in the transport session's transmission window.
See note [a].
1. The UM receiver identifies the missing sequence numbers in an internal "loss map" structure.
2. The UM receiver sets a "NAK timer" for the initial NAK backoff. This timer is set to a randomized value.
See note [b].
3. If the missing datagrams arrive before the NAK timer expires, the timer is canceled and the
entries are removed from the loss map. See note [c].
4. If the NAK timer expires, the subscriber will create a "NAK packet" (actually datagram)
which contains one or more sequence numbers that make up the gap. See note [d].
It sends this NAK datagram to the source, and sets a new NAK timer.
5. The source checks each sequence number and its internal state to see if it can send
a retransmission of the missing data. If so, the requested datagrams are re-sent.
If not, the source may send an "NCF" (NAK Confirmation).
See note [e].
6. If the subscriber receives datagrams with sequence numbers in its loss map,
it removes the entries from the loss map and cancels the NAK timer for those
sequence numbers.
7. If the NAK timer expires again, resume step 4.
8. There is also a configurable NAK generation interval that sets the maximum time
the transport will attempt to recover datagrams.
If entries in the loss map are older than this interval, they are declared unrecoverable
and removed from the loss map.

In both LBT-RM and LBT-RU, message retransmissions and NCFs are sent to *all* subscribers,
not just the one(s) that sent NAKs.
(In contrast, the delivery controller recovery protocols only send recovery to the
subscriber(s) that request it.)

Additional description of this protocol is available at
[Transport LBT-RM Reliability Options](https://ultramessaging.github.io/currdoc/doc/Config/grptransportlbtrmreliability.html)

NOTES:

**[a]**: In step 1, the publisher saves transmitted messages in the transport session's
transmission window.
This is a fixed-size data structure that saves previously sent messages up to a size limit.
When the size limit is reached, the oldest messages are removed to make room for the newer
messages.
Each message that is sent contains in its header the current lowest and highest sequence
numbers in the transmission window.

**[b]**: The initial NAK backoff was not originally part of LBT-RU.
It was added in UM version 6.10.
We encourage all users of pre-6.10 versions to upgrade.

**[c]**: In step 3, the missing datagrams might arrive before the initial NAK timer expires
because some other subscriber had the same loss and set a shorter randomized timer and already
sent the NAK and got retransmission. Or it might be because networks and operating systems can
sometimes deliver UDP packets out of order. When UM receives the packets out of order,
it interprets the sequence number discontinuities as loss which is immediately repaired.

**[d]**: In step 4, the receiver assembles a NAK datagram. However, the most recent successfully
received datagram for that transport session contains the current lowest and highest sequence
numbers in the transmission window. If the receiver detects that one or more of its missing
sequence numbers are NOT in the source's transmission window range,
the receiver will declare the sequence numbers unrecoverable loss and will not include them
in the NAK datagram.
This does not necessarily trigger an unrecoverable loss event being delivered to the
subscribing application since the delivery controller may succeed in recovering the missing
messages.

**[e]**: In step 5, the source might determine that it cannot retransmit a requested datagram.
This might be because the datagram is no longer in its transmission window, in which case the request
is ignored and no NCF is sent. Or it might have reached its retransmit rate limit, in which case
it sends an NCF. Or it might have already sent a retransmission within its suppression interval,
in which case it sends an NCF.
Also, note that LBT-RM's NCF algorithm changed in UM version 6.10 to reduce the number of
NCFs sent during periods of heavy loss.
We encourage all users of pre-6.10 versions to upgrade.

### Delivery Controller Recovery

There are two forms of delivery controller recovery:
* [Late join](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#latejoin):
when a newly-created receiver determines that it needs to recover messages sent before the receiver was created.
* [Off-Transport Recovery (OTR)](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#offtransportrecoveryotr):
when the transport is not able to recover packets, the OTR protocol can optionally attempt to.

Note that both late join and OTR use the same underlying protocol, which is TCP-based.
This protocol functions between a source and a receiver in a
"[streaming](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#streaming)"
(non-persisted) use case,
or between a Store and a receiver in a
[persisted](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#persistence) use case.

## Proper Configuration

Proper configuration of sources and receivers will reduce the chances of
loss and [[NAK storms]].
See [[Configuring UDP-Based Transports]].
