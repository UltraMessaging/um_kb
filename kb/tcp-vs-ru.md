# TCP vs RU

Compare UM transports TCP and LBT-RU.

<!-- mdtoc-start -->
&bull; [TCP vs RU](#tcp-vs-ru)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Pacing](#pacing)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Source-Paced TCP](#source-paced-tcp)  
<!-- TOC created by './mdtoc.pl kb/tcp-vs-ru.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

This article compares and contrasts the UM transport types TCP and LBT-RU.
It assumes you are familiar with the basics of Ultra Messaging's messaging paradigm
and the basics of network data communication.

## Pacing

LBT-RU is "source-paced", which means that the publisher has total control over
when messages are sent.
When your application calls "send", it will go out.

TCP, as a protocol, can be thought of as "receiver-paced", which means that a
slow receiver can push back on a publisher.
If your subscribers can't keep up with your publisher,
when the intervening buffers fill,
the publisher's next call to "send" can block to allow the receives an
opportunity to catch up.

An advantage of TCP's operation is reduced chance of message loss.
A disadvantage is the introduction of latency.
Suppose that you have three subscribers and only one is slow.
The two fast subscribers will have to wait for the slow receiver.
In the most extreme case,
a subscriber might encounter a hang or deadlock condition that
halts the publisher until the hung subscriber is killed.

In contrast, a source-paced protocol will provide the fast subscribers
with the lowest-possible latency at the cost of introducing loss to
the slow receiver.
Note that this scenario is usually short-lived during an intense burst
of traffic, and the slow receiver will typically be able to recover the
lost data later.
So the slow receiver will probably eventually get all the data,
albeit with a high latency.

The issue is more nuanced; see
[Transport Pacing](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportpacing)
for more depth.

### Source-Paced TCP

The configuration option
[transport_tcp_multiple_receiver_behavior (source)](https://ultramessaging.github.io/currdoc/doc/Config/grptransporttcpoperation.html#transporttcpmultiplereceiverbehaviorsource)
can set to "source_paced".
In this mode of operation, if a receiver is slow, the source will simply
drop outgoing messages intended for that receiver.
This makes the behavior similar to LBT-RU,
except that there is no transport-level mechanism to recover the lost data.
[OTR](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#offtransportrecoveryotr)
might be able to recover the data, especially for persisted data.
But for non-persisted,
OTR is generally less successful than LBT-RU's NAK-based recovery.
