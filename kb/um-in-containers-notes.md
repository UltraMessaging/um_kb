# UM in Containers Notes

<!-- mdtoc-start -->
&bull; [UM in Containers Notes](#um-in-containers-notes)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Disclaimer](#disclaimer)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Bottom Line](#bottom-line)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Cloud](#cloud)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Network](#network)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Tools](#tools)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Next Steps](#next-steps)  
<!-- TOC created by './mdtoc.pl kb/um-in-containers-notes.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

## Disclaimer

The Informatica Ultra Messaging group does not have high expertise in the container environment.
To the degree that containers provide a Windows or Linux execution environment, Ultra Messaging code will run fine in them.
But we cannot help you properly configure your container instances.

## Bottom Line

UM is fully supported in containers.
We have customers using a variety of different UM versions in Docker containers.
In most cases, they are able to migrate to containers without any changes to their source code.

Porting to any kind of different environment brings with it the possibility of some kind of incompatibility,
so naturally you will need to test your system before going live.
But based on our experience, there should be no incompatibilities with UM.

Here are the high-level topics that need to be considered when migrating to the Cloud.

## Cloud

Some customers decide to containerize their applications at the same time they
move to the cloud.
We recommend that this be done as two separate steps.
First containerize your applications in your own data center,
and once that is working to your satisfaction, migrate to the cloud.

See [UM in the Cloud Notes](UM-in-the-Cloud-Notes.md).

## Network

In general, UM expects its services to be run in environments with stable IP
addresses that are directly accessible from all processes in the same
[topic resolution domain](https://ultramessaging.github.io/currdoc/doc/Design/fundamentalconcepts.html#topicresolutiondomain)
(TRD).
For example, if you run an "lbmrd" process,
your applications will expect it to be available on a configured IP address.
If that IP address changes, you must reconfigure your applications.

By default, containers sheild the applications from the real network,
providing instead a virtual network.
We recommend configuring your container to NOT use the virtual network.
Instead, give the container direct access to the physical network interface.
In a non-cloud environment, this gives you low latency, a stable IP address,
and access to multicast.

In some cases, customers desire to use the virtual network provided by
their container orchestrator (e.g. Kubernettes).
We have evidence that multicast can still work (in a non-cloud environment),
but will have higher latency.

## Tools

In our experience, most containers are constructed to be "bare bones",
without many diagnostic tools.

We recommend adding the following tools to your containers to assist
in troubleshooting problems:
* "ifconfig" (or its more modern form, "ip").
* "netstat" (or its more modern form, "ss").
* "ping"
* "msend" and "mdump" (part of the [mtools](https://github.com/UltraMessaging/mtools) set).
* "lbmtrreq", "lbmsrc", "lbmrcv" (part of the UM "bin" directory tools).

## Next Steps

To effectively support you,
UM Support would like to have a meeting where you describe the architecture of the system,
as it exists today and as you envision it existing containerized.
Your primary publishers and subscribers would be good to know.
Approximate data rates would also be good to know.

We would also want to see your configuration.
There are typically two kinds of configuration that we’ll need:
1. Application configuration for UM. This is typically supplied using configuration files.
2. UM Service configuration. Do you use our Persistence functionality?
If so, then you have “Store” processes running. We’ll want to see those configurations too.
3. Are you running the “lbmrd” service today?
If so, when we’ll want that configuration file too
(although sometimes the process can be run without a configuration file,
with all operating parameter supplied on the command line).
