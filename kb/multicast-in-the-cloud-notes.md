# Multicast in the Cloud Notes

<!-- mdtoc-start -->
&bull; [Multicast in the Cloud Notes](#multicast-in-the-cloud-notes)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Disclaimer](#disclaimer)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Bottom Line](#bottom-line)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Transit Gateway](#transit-gateway)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [swXtch.io](#swxtchio)  
<!-- TOC created by './mdtoc.pl kb/multicast-in-the-cloud-notes.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

## Disclaimer

The Informatica Ultra Messaging group does not have high expertise in Cloud computing.
To the degree that Cloud provide a Windows or Linux execution environment, Ultra Messaging code will run fine on them.
But we cannot help you properly configure your cloud instances.

## Bottom Line

UM is fully supported in the Cloud.
We have customers using a variety of different UM versions in the Cloud.
Most of them are running in AWS, but we have at least one that I know of using Azure.
In most cases, they are able to migrate to the cloud without any changes to their source code.

Most cloud infrastructures do not support true multicast networking.
This article provides some information on the multicast solutions we know of,
but be aware that our information is incomplete and non-authoratative.

## Transit Gateway

AWS offers a multicast-like service, called the Transit Gateway,
that allows applications to invoke standard multicast functionality
(socket calls) and simulates the operation of multicast.
However, some of our customers have expressed dissatisfaction with
the Transit Gateway and have instead chosen to rely on UM's unicast protocols.

One specific issue identified by one of our customers is an extended "join" time.
When a subscriber joins a multicast group,
it can take tens of seconds before the transit gateway starts forwarding the traffic.

This customer was able to "pre-join" the groups using the "mdump" program
from the [mtools](https://github.com/UltraMessaging/mtools) package.
This allows this customer to make very limited use of AWS Transit Gateway multicast,
but only in a specific situation where connectivity is very static.

## swXtch.io

Pronounced "switch dot eye oh",
[swXtch.io](https://swxtch.io) offers cloud-based multicast solutions.
However, to our knowledge, no UM customer has tried using them.
We (Informatica) have had several conversations with them and have been
impressed with their expertise and flexibility,
and their technology sounds very promising.
But we not yet found a UM customer willing to participate in a POC with them.

One potential advantage to their technology is the use of kernel-bypass,
which should reduce latency.
However, this has not been tested with UM to verify this advantage.

[Contact UM Support](https://ultramessaging.github.io/currdoc/doc/Operations/contactinginformaticasupport.html)
if you would like to initiate a three-way POC with swXtch.io.
