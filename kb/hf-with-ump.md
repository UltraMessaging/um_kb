# HF with UMP

<!-- mdtoc-start -->
&bull; [HF with UMP](#hf-with-ump)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Benefits](#benefits)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Costs and Considerations](#costs-and-considerations)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Addressing Hardware Issues](#addressing-hardware-issues)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Addressing Application Issues](#addressing-application-issues)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Down To Business](#down-to-business)  
<!-- TOC created by './mdtoc.pl kb/hf-with-ump.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

This article outlines the advantages and disadvantages of using Hot Failover with persistence (UMP) and suggests ways to optimize the benefits of using the two together.

## Benefits

Hot Failover provides zero-latency failover for any component in the path from source to receiver: the source-side application, operating system, or NIC, even the network switches and routers along the way. If one of a pair of Hot Failover sources goes down, any receiving applications listening to that source's topic won't even notice the failure. Receiving applications notice no latency spikes or delay while failing over to a waiting warm backup source; there is practically no change at all, from a receiver's perspective. Business simply continues as usual, and the failed source can be repaired and brought back up when it is convenient.
 
For more details on how Hot Failover works, please see the article LBM Hot Failover.          

## Costs and Considerations

As with any architectural decision, using Hot Failover comes with certain trade-offs. The following issues arise when using Hot Failover independently of UMP.  

* Additional amount of network bandwidth.

  This is the most obvious effect of using Hot Failover. With Hot Failover, two or more sources constantly send duplicate data over the wire.    

* Increased likelihood of switch port oversubscription.

  In a Hot Failover design, two or more independent sources, connected to two or more different switch ingress ports, send packets destined to one receiver, connected to a single switch egress port. The sources send at the same time. This means the switch funnels packets through multiple switch queues (from the sources) into a single queue (for the receiver). If switch queue depths are not well understood, this can cause a switch to simply throw away the packets that don't fit in the egress queue, leading to potentially massive amounts of loss.  

* Added NIC and CPU load.

  A Hot Failover receiver still receives at least two copies of every message. This means the NIC uses at least twice as many receive descriptors, at least twice as many CPU interrupts occur, and the CPU uses at least twice as much kernel time and a small amount of additional user-space time. All this increases the likelihood of receiver-side loss.

* Data-dependent bugs unresolved.

  If a Hot Failover source application contains a deterministic data-dependent bug (that is, a bug triggered by certain input to the application) that causes it to crash, running two or even 10 instances of the Hot Failover source application does not provide any better failover capabilities than running a single instance; given the same bug-producing input, all instances are likely to crash at the same time.
 
Using Hot Failover with UMP poses all of the same issues mentioned above plus the following issues.  

* Additional storage space required for a UMP disk store.

  Streams from each Hot Failover source must be stored independently.

* Higher disk activity.

  Hot Failover with UMP requires at least twice as many disk reads during receiver recovery, and at least twice as many disk writes on every message.

* Higher network activity.

  UME stability ACK messages from the store must be sent to each source application through separate TCP connections. Receivers must send confirmed delivery messages to every source application, again through separate TCP connections to each.

* Significantly increased application complexity.

  Receiving applications, during recovery, pick up several different streams. They typically should only process messages from one, and must be able to choose which messages to process. At least twice as many source application UMP registration IDs must be managed.
 
Even with these considerations, UMP and Hot Failover can successfully be used together, and in fact are used together in daily, business-critical production deployments of Ultra Messaging software.    

## Addressing Hardware Issues

Here are some recommendations to help mitigate or solve the issues associated with using Hot Failover and UMP together.  

* Use network hardware that can keep up with the amount of network traffic generated.

  Consider switch buffers and queue sizes carefully. Even expensive switches like the Cisco 6500 series can have small per-port receive and transmit buffers, depending on how they are configured. Calculate how large your switch receive buffers should be to prevent switch queue loss based on your maximum expected data rates and the maximum length of time traffic bursts are likely to last. Typically, not all buffer space is used before drops begin; check your switch's drop policy to find out how much buffer space is usable.
 
  NIC receive descriptors (on receiving application machines) and socket buffers must be similarly set high enough to handle the maximum expected traffic bursts.   

* Use Ethernet flow control (aka "pause frames") on most switches to essentially extend a receiver's receive buffer slightly. Use the switch's egress port buffer as extra buffer space. This is a poor substitute for sufficient NIC receive descriptors, however.

* Consider using bonded NICs on receivers with 802.3ad link aggregation for increased capacity rather than for failover. This can also alleviate some switch port oversubscription issues.

* Use multiple disks for UME disk stores and spread each Hot Failover source in a pair across different disks. This is a good practice, in general, for both efficiency and fault tolerance reasons.

## Addressing Application Issues

Using UMP and Hot Failover together requires some additional application complexity not needed when using UMP or Hot Failover alone.  

* Enable UMP explicit ACKs and Hot Failover duplicate delivery in each Hot Failover receiving application. This is the most significant required change.

  UMP tracks the last sequence number the receiver acknowledged. Receivers can use two types of receiver acknowledgments: implicit and explicit ACKs. The UMP receiver automatically sends implicit ACKs. When using explicit ACKs, your application, not the UMP receiver, sends message consumption acknowledgements.
 
  A UMP receiver generates an implicit ACK and sends it to the store automatically when a receiving application deletes a message. Unless your application retains the message (using lbm_msg_retain() when using the C API, or keeping a reference to the LBMMessage object when using the .NET or Java APIs), this happens upon return from a UMP receiver's callback.
 
  Unfortunately, due to the way Hot Failover normally works (fastest-first delivery), receivers delete all duplicate messages from "slow" sources before delivery to the application. This means, when using implicit ACKs, they are also acknowledged, even if the application is in the middle of processing the same message sent from a faster source. If the receiver goes down in the middle of processing the message from the faster source, before acknowledging it, when the receiver is brought back up it may receive a stream of "durable subscription" messages from the slower source first. If it does, the slower source's stream starts with a message that is one or more messages past the "fast" source message that  the receiver had been working on when it crashed. This establishes the next message's sequence number as the starting Hot Failover sequence number. When the receiver recovers from the "fast" source's stream, the UMP store dutifully retransmits the message the receiver had been working on when it crashed, but the receiver throws it away before delivering it to the application, because it has a lower Hot Failover sequence number than the messages it has just received from the "slow" source's recovery stream.
 
  To overcome this limitation, turn on the hf_duplicate_delivery receiver option to deliver what appears to be duplicate Hot Failover messages all the way to the application, so the application decides whether or not to process or otherwise handle the duplicate message.
 
  To make the decision easier to manage, the receiving application also should enable explicit ACKs (using the ume_explicit_ack_only receiver option). Combined with duplicate delivery, this option allows a receiving application to control when acknowledgments are sent for each message received from each source. When you enable duplicate delivery, UMP sets a special flag on duplicate incoming messages (meaning their Hot Failover sequence number has already been received by the receiving application). An application might choose to check this flag. If the flag is not set (indicating that this is the first receipt of the message), the application might begin processing the message. If the flag is set, the application might simply place the message on a queue of "messages to be acknowledged," and release and acknowledge the message along with the original message as soon as it processes the original message.
 
  Using duplicate delivery and explicit ACKs means more work for the application. It makes Hot Failover less efficient than it would be otherwise when used without UMP since every message from every source must be delivered to the application code rather than being tossed away earlier. Using duplicate delivery and explicit ACKs is highly recommended, however, when combining Hot Failover with UMP.  

* Implement a good registration ID management system to prevent overlap or confusion.

  Using Hot Failover requires at least twice as many sources to be registered with the UMP store as would otherwise be required. Sources (even Hot Failover sources) cannot share UMP registration IDs, so you need to register each source individually.  
 
For more information about lbm_msg_retain(), please refer to the C API documentation. Information about LBMMessage can be found in the .NET and Java API documentation. Information about hf_duplicate_delivery is in the "Hot Failover Operation Options" section of the LBM Configuration Guide, and ume_explicit_ack_only information is in the "Ultra Messaging Persistence Options" section of the same document.    

## Down To Business

Whether or not to use Hot Failover with UMP is essentially a business decision. Hot Failover provides one massive benefit - zero-latency source failover - at the significant costs of increased hardware expenditures, the necessity of a much more tightly controlled infrastructure, and increased software complexity.
 
To use an exchange as an example, the main questions to ask when making a decision for or against using Hot Failover might be:

* Do I need to ensure that customers do not notice source failure at all, at the cost of slightly higher average per-message latencies?

* Do I want lower average latencies accompanied by perceivable latency spikes in the event of a hot-warm source failover?

Or, to put it more bluntly,

* Will I lose more money and customers if my average execution latencies are slightly higher than my competition's?

* Or will I lose more money if customers experience a rare enormous latency spike but have lower average latencies on the majority of trading days?

*Do not use Hot Failover* if you want lower average latencies with the occasional rare latency spike on a hot-warm source failover.  

*Use Hot Failover* if you want slightly higher average latencies with no latency spikes on source failover.
