# Monitoring Notes

<!-- mdtoc-start -->
&bull; [Monitoring Notes](#monitoring-notes)  
&bull; [Introduction](#introduction)  
&bull; [Library Statistics](#library-statistics)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Context Statistics](#context-statistics)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Receiver Statistics](#receiver-statistics)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transport LBT-RM Receiver](#transport-lbt-rm-receiver)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transport LBT-RU Receiver](#transport-lbt-ru-receiver)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Source Statistics](#source-statistics)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transport LBT-RM Source](#transport-lbt-rm-source)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transport LBT-RU Source](#transport-lbt-ru-source)  
&bull; [Store Statistics](#store-statistics)  
&bull; [DRO Statistics](#dro-statistics)  
&bull; [SRS Statistics](#srs-statistics)  
<!-- TOC created by './mdtoc.pl kb/monitoring-notes.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

# Introduction

Best practices for monitoring an Ultra Messaging network are talked about at length
[here](https://ultramessaging.github.io/currdoc/doc/Operations/monitoring.html).
To summarize:

* You should monitor your hosts (memory, CPU, network utilization) and network
(packet drops).
UM doesn't help you with this; there are many third-party tools availalbe.

* As part of network monitoring, many customers run "always on" packet capture,
like [Corvil](https://www.pico.net/corvil-analytics/).

* UM components, like the Store and DRO, generate log files.
These should be monitored for problems.

* When an application uses UM, that UM instance can also generate logs.
Your application has a responsibility to save those logs somewhere.
Some customers save them to a database, others just write them to a disk file.

* Your application also is also delivered events from UM.
Most of these events, including unexpected events, should be logged.
For example, [receiver BOS and EOS events](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#receiverbosandeosevents).

* The UM library maintains internal statistics.
These should be collected and saved.
The recommended method of doing this is to configure your applications to publish their statistics periodically
to a central collector.
UM components, like the Store and DRO, also run on top of the UM library,
and they should also be configured to publish their statistics to the central statistics collector.

* UM components, like the Store and DRO, also generate "daemon statistics",
which is information specific to the component type.
For example, the Store publishes Store statistics,
and the DRO publishes DRO statistics.
These should also be published to the central statistics collector.

# Library Statistics

The UM Library maintains statistics related to contexts, sources,
receivers, and event queues that the application creates.
Note that the statistics are organized by
[transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions),
not individual topic.

There are a large number of counters maintained for each transport session being used.
Many of those fields will be of direct interest to customers (e.g. "lost"),
while many others are typically only interesting to UM Support engineers.
We request that you save *all* of the fields, not just the ones you are especially interested in.
(Some of our customers write the whole record in the form of a BLOB, and specific fields of special
interest as separate columns.)

The fields referenced below are of particular interest to customers.
We recommend that customers trigger alerts to operations staff if
any of the field values are abnormal.

Please click each link to the documentation for information about
the field.
For example, the documentation will tell if the field is
"cumulative" (most of them) or a "snapshot" (a few).

The documentation links below are for the C API.
The same statstics and descriptions apply for Java and .NET,
although the field names will be different.
For example, the C field
[tr_dgrams_dropped_ver](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#a4af77dcdede237ff289bf1085f4d9030)
is the same as the Java/.NET getter
[topicResolutionDatagramsDroppedVersion()](https://ultramessaging.github.io/currdoc/doc/JavaAPI/classcom_1_1latencybusters_1_1lbm_1_1LBMContextStatistics.html#ae5e01a9a35f3772733390e20343f985d).

## Context Statistics

The following context statistics should be proactively monitored by customers:
* [tr_dgrams_dropped_ver](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#a4af77dcdede237ff289bf1085f4d9030),
[tr_dgrams_dropped_type](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#a9477e4a48c6cceabea9450e0f85276da)
[tr_dgrams_dropped_malformed](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#aaba67cae496b93572e2455a25776babe) -
None of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

* [tr_rcv_unresolved_topics](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#ad2fd3379b1a47479c7b64e873118be5c) -
This field is a snapshot of the topics subscriptions that have not discovered any sources.
This value can be non-zero during normal operation during the initial topic resolution phase,
but it typically should not remain non-zero for any significant time.
A long-lasting non-zero value might indicate topic deafness, possibly due to a failure of topic resolution,
and should trigger an alert to the operator..

* [lbtrm_unknown_msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#ad2fd3379b1a47479c7b64e873118be5c),
[lbtru_unknown_msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#aaba67cae496b93572e2455a25776babe) -
Messages received over a transport session that was not subscribed to.
For RM it typically means overloading multicast address:port across multiple publishers.
Ideally these counters should either be zero, or be growing only slowly.
Fast growth typically means sub-optimal configuration of publishers'
[transport sessions](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions),
and should trigger an alert.

* [fragments_unrecoverably_lost](https://ultramessaging.github.io/currdoc/doc/API/structlbm__context__stats__t__stct.html#a368bb93a5038b98e6e59b62c34a3d5b4) -
This is supposed to be a count of unrecoverable loss seen at the delivery controller.
However, as of UM version 6.16, this field will under-count the unrecoverable loss.
In fact, it can be zero even though multiple unrecoverable loss events have been delivered.
Nevertheless, if this valus is greater than zero,
it should trigger an investigation.


## Receiver Statistics

Transport types LBT-RM and LBT-RU require the most proactive monitoring.
Other transport types typically do not require active monitoring.

### Transport LBT-RM Receiver

* [msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a9c6f317be17cafd8678ac556217657cd) -
This shows how many datagrams have been received on the
[transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions)
since its creation.
Note that it is an aggregate across all topics mapped to that transport session.
There is no abnormal value,
but tracking message load over time can be useful for detecting increases in traffic,
which can eventually lead to overload and data loss.

* [lost](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#ac0a27c8589c7062ba030e5a4dfc041f3) -
The number of datagrams on the transport session not received when they were supposed to be.
See [Packet Loss](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html) for
an anlaysis of why packets are lost.
Note that a lost packet that is successfully recovered via NAK/retransmission will still
be counted as a lost packet.
It should be an aspirational goal to keep this counter at zero,
but few of our customers can fully achieve that.
Since this is a cumulative statistic,
we advise calculating a loss rate based on the previous value,
and alerting if the rate is above a "normal" threshold.
That threshold should match your application requirements,
and might be anywhere from a few per hour to a few per second.

* [unrecovered_txw](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a677ea15bc8a2621f13a774a1a2514899),
[unrecovered_tmo](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#aec81f344ce20a3485bbf2f5a65b5c61e) -
Datagrams that were lost and could not be recovered by NAK/retransmission.
(Note that [OTR](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#offtransportrecoveryotr)
might still recover messages that could not be recovered from the transport.)
Neither of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

* [lbm_msgs_no_topic_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a62c19c1a782919ff9ef69cc72ff0a853) -
number of messages received for topics that the receiving application has not subscribed to.
An application might subscribe to a topic that is carried on a transport session with
ten topics mapped to it.
The nine topics on the transport session that the application is not subscribed to will
increment this counter.
If this value is a significant persentage of the
[lbm_msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a44b91569d70c2c5d30e7ec0dcf987b14) value,
the topic/transport mappings should be examined.

* [dgrams_dropped_size](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a1c209454ba9fe6b52f903021b14d1e9c),
[dgrams_dropped_type](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#acad07e2da34793dbaf3dac991f0d997a),
[dgrams_dropped_version](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#af2fe38df948b4166b599fb7e58bdf027),
[dgrams_dropped_hdr](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#a8df967fc7b7c8a0a864709c07a1772aa),
[dgrams_dropped_other](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtrm__t__stct.html#add62b45ed2e496c7856cdabfcbd56d1f) -
These represent received datagrams that do not parse correctly.
None of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

### Transport LBT-RU Receiver

* [msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a5c2054b4aa164bf7619b97f955f00d54) -
This shows how many datagrams have been received on the
[transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions)
since its creation.
Note that it is an aggregate across all topics mapped to that transport session.
There is no abnormal value,
but tracking message load over time can be useful for detecting increases in traffic,
which can eventually lead to overload and data loss.

* [lost](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a9717bf76222b09c31cbc3d48d79860f3) -
The number of datagrams on the transport session not received when they were supposed to be.
See [Packet Loss](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html) for
an anlaysis of why packets are lost.
Note that a lost packet that is successfully recovered via NAK/retransmission will still
be counted as a lost packet.
It should be an aspirational goal to keep this counter at zero,
but few of our customers can fully achieve that.
Since this is a cumulative statistic,
we advise calculating a loss rate based on the previous value,
and alerting if the rate is above a "normal" threshold.
That threshold should match your application requirements,
and might be anywhere from a few per hour to a few per second.

* [unrecovered_txw](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#aa549f88cacfa672176746a6643c37a2f),
[unrecovered_tmo](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a9c6f09ca548af94cc5e0c83257ec3a5f) -
Datagrams that were lost and could not be recovered by NAK/retransmission.
(Note that [OTR](https://ultramessaging.github.io/currdoc/doc/Design/umfeatures.html#offtransportrecoveryotr)
might still recover messages that could not be recovered from the transport.)
Neither of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

* [lbm_msgs_no_topic_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a83c799da110d0f2036111dd7de4fce56) -
number of messages received for topics that the receiving application has not subscribed to.
An application might subscribe to a topic that is carried on a transport session with
ten topics mapped to it.
The nine topics on the transport session that the application is not subscribed to will
increment this counter.
If this value is a significant persentage of the
[lbm_msgs_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a076b988c5320c520222eed5e29bfe8e0) value,
the topic/transport mappings should be examined.

* [dgrams_dropped_size](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a2cb0c80324a1b038de32baae0367bedf),
[dgrams_dropped_type](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#ab14a9ed18d2f4c52f22d1e3a200ebc5b),
[dgrams_dropped_version](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a3bc35b655534753f990b1ac3d1bf434d),
[dgrams_dropped_hdr](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#afd3d754cff49f6f9317c1a5e82e7d5e9),
[dgrams_dropped_sid](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a3e01c4f5f70e0b7b94d8787308c0367c),
[dgrams_dropped_other](https://ultramessaging.github.io/currdoc/doc/API/structlbm__rcv__transport__stats__lbtru__t__stct.html#a19058480206858399c4820c799ebd35d) -
These represent received datagrams that do not parse correctly.
None of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

## Source Statistics

Transport types LBT-RM and LBT-RU require the most proactive monitoring.
Other transport types typically do not require active monitoring.

### Transport LBT-RM Source

* [msgs_sent](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtrm__t__stct.html#afdb40daed5c3da97e44b495649d063be) -
This shows how many datagrams have been sent on the
[transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions)
since its creation.
Note that it is an aggregate across all topics mapped to that transport session.
There is no abnormal value,
but tracking message load over time can be useful for detecting increases in traffic,
which can eventually lead to overload and data loss.

* [naks_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtrm__t__stct.html#a363c5c9c4b5a44e1eced9ad7a2892473) -
Number of individual datagrams that were NAKed by receivers.
See [Packet Loss](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html) for
an anlaysis of why packets are lost.
It should be an aspirational goal to keep this counter at zero,
but few of our customers can fully achieve that.
Since this is a cumulative statistic,
we advise calculating a loss rate based on the previous value,
and alerting if the rate is above a "normal" threshold.
That threshold should match your application requirements,
and might be anywhere from a few per hour to a few per second.

* [naks_rx_delay_ignored](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtrm__t__stct.html#a93605cc2dcfac90aecd4736439c3bdea),
[naks_shed](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtrm__t__stct.html#accf51bbd30c14ed1c88582aa6f0400b6),
[naks_rx_delay_ignored](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtrm__t__stct.html#a93605cc2dcfac90aecd4736439c3bdea) -
Numbers of different types of NCFs sent.
NCFs are sent when the publisher is required to refuse a retransmission request.
None of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

### Transport LBT-RU Source

* [msgs_sent](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtru__t__stct.html#a33977a0a14846929f481fa61b10a45fe) -
This shows how many datagrams have been sent on the
[transport session](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#transportsessions)
since its creation.
Note that it is an aggregate across all topics mapped to that transport session.
There is no abnormal value,
but tracking message load over time can be useful for detecting increases in traffic,
which can eventually lead to overload and data loss.

* [naks_rcved](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtru__t__stct.html#a9833ac2f8d6a9e6708a6848b641a6a4c) -
Number of individual datagrams that were NAKed by receivers.
See [Packet Loss](https://ultramessaging.github.io/currdoc/doc/Design/packetloss.html) for
an anlaysis of why packets are lost.
It should be an aspirational goal to keep this counter at zero,
but few of our customers can fully achieve that.
Since this is a cumulative statistic,
we advise calculating a loss rate based on the previous value,
and alerting if the rate is above a "normal" threshold.
That threshold should match your application requirements,
and might be anywhere from a few per hour to a few per second.

* [naks_rx_delay_ignored](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtru__t__stct.html#a3f2a675528727a6d758cc41a8d8f5201),
[naks_shed](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtru__t__stct.html#a8b27273ad2887a0d7d11a91d6cd28258),
[naks_rx_delay_ignored](https://ultramessaging.github.io/currdoc/doc/API/structlbm__src__transport__stats__lbtru__t__stct.html#a1c46665e5d1c207ff52d5bdc5777a8c6) -
Numbers of different types of NCFs sent.
NCFs are sent when the publisher is required to refuse a retransmission request.
None of these counters should be greater than zero; alert the operator if they are.
If any of these counts increase, it usually due to interference from a non-UM packet source.
[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html).

# Store Statistics

TBD

# DRO Statistics

TBD

# SRS Statistics

The SRS also publishes statistics related to its operation.
These normally do not need to be proactively monitored.
If you have problems with TCP-based topic resolution,
then the statistics might be useful for diagnosing.
