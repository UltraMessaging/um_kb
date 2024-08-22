# UM in the Cloud Notes

<!-- mdtoc-start -->
&bull; [UM in the Cloud Notes](#um-in-the-cloud-notes)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Disclaimer](#disclaimer)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Bottom Line](#bottom-line)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Multicast](#multicast)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [IP Addresses](#ip-addresses)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Connectivity to Your Data Center](#connectivity-to-your-data-center)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Latency](#latency)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Containers](#containers)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Next Steps](#next-steps)  
<!-- TOC created by './mdtoc.pl kb/um-in-the-cloud-notes.md' (see https://github.com/fordsfords/mdtoc) -->
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

Porting to any kind of different environment brings with it the possibility of some kind of incompatibility,
so naturally you will need to test your system before going live.
But based on our experience, there should be no incompatibilities with UM.

Here are the high-level topics that need to be considered when migrating to the Cloud.

## Multicast

Most cloud infrastructures do not support multicast networking.
I know that AWS does offer multicast, but only as an add-on option.
It is not enabled by default.
I don’t know if Azure supports Multicast in their network.
If you are not using Multicast today for either your data transports or your topic resolution,
then you have no worries here.
You can skip this section.

So, assuming that you are using multicast for topic resolution and/or data transports,
you will probably need to at least change your configuration.

THE GOOD NEWS: UM can be used in non-multicast environments.
You may need to deploy some extra services (one or more instances our “lbmrd” service,
if you’re not already using it).
Then you can change your configuration to use unicast topic resolution and a unicast transport.
We can help you with modifying your configuration.

THE BAD NEWS: There is a fairly low probability that you will need to make a small change to your code.
In particular, your publisher may be written to respond to what are called “source events”.
If that’s the case, then switching to a unicast transport will introduce two new source events:
“connect” and “disconnect”.
Most of our customers can handle these new events without code change.
But there is a possibility (low) that your code will treat the new
events as an error and will malfunction as a result.
We can help you analyze your software to determine if you are at risk of this.

## IP Addresses

There are different ways to deploy an application system in the cloud.
Unfortunately, we Ultra Messaging engineers are not experienced with the different methods,
so we can only rely on reports from our successful customers.
In particular, I believe there are some deployment methods where you do not have
any control over the IP addresses of the hosts that your services run on.
Today it might be one IP address; tomorrow it might be a different IP address.
In fact, I believe that in some cases,
a given application could have a different IP address every time it is invoked,
so it could be changing continuously during the day.

UM was not written with this kind of non-deterministic addressing in mind.
UM normally expects applications to be long-running with a stable IP address.
I know that it is possible to configure your cloud deployment to have stable IP addresses,
but I don’t know how to do it.

## Connectivity to Your Data Center

If you need Ultra Messaging connectivity between your cloud and your own data center,
you will probably need our DRO component.
This component bridges across networks and provides transparent messaging connectivity.
I.e. no source code changes are needed in your applications.

## Latency

Due to the nature of the cloud environment,
we cannot guarantee the same low latencies that you have today.
Cloud can increase latencies for a number of reasons.
And they tend to also increase variation of latency (jitter),
so your latency deviations from the average will be higher.

There are some third-party products that claim to mitigate this somewhat.
But we have not tested these products so we cannot give any advice concerning their use.

## Containers

Some customers decide to containerize their applications at the same time they
move to the cloud.
We recommend that this be done as two separate steps.
First containerize your applications in your own data center,
and once that is working to your satisfaction, migrate to the cloud.

See [UM in Containers Notes](UM-in-Containers-Notes.md).

## Next Steps

To effectively support you,
UM Support would like to have a meeting where you describe the architecture of the system,
as it exists today and as you envision it existing in the Cloud.
Your primary publishers and subscribers would be good to know.
Approximate data rates would also be good to know.

We would also want to see your configuration.
1. Application configuration for UM. This is typically supplied using configuration files.
2. UM Service configuration. Do you use our Persistence functionality?
If so, then you have “Store” processes running. We’ll want to see those configurations too.
3. Are you running the “lbmrd” service today?
If so, when we’ll want that configuration file too
(although sometimes the process can be run without a configuration file,
with all operating parameter supplied on the command line).
