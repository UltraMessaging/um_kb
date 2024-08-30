# Java Versions

Requirements related to Ultra Messaging and versions of Java

<!-- mdtoc-start -->
&bull; [Java Versions](#java-versions)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [UM Applications](#um-applications)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [SRS](#srs)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [MCS](#mcs)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Illegal Reflective Access Operation](#illegal-reflective-access-operation)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Certification](#certification)  
<!-- TOC created by './mdtoc.pl kb/java-versions.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

Ultra Messaging supports Java applications.
The design of our Java API uses the
[Java Native Interface](https://en.wikipedia.org/wiki/Java_Native_Interface)
(JNI), which consists of a thin Java wrapper around the UM native dynamic library.

There are other UM components that are written in pure Java:
[SRS](https://ultramessaging.github.io/currdoc/doc/Design/topicresolutiondescription.html#srsservice)
and [MCS](https://ultramessaging.github.io/currdoc/doc/Operations/monitoring.html#monitoringcollectorservicemcs).
(See below.)

## UM Applications

For UM applications, the minimum Java version is 8.

For Java 9 and higher, run with "`--add-opens java.base/java.nio=ALL-UNNAMED`".
See [Illegal Reflective Access Operation](#illegal-reflective-access-operation).

## SRS

For the 
[Stateful Resolver Service](https://ultramessaging.github.io/currdoc/doc/Design/topicresolutiondescription.html#srsservice) (SRS),
the minimum Java version is 9.
Since this service also uses UM, it requires
"`--add-opens java.base/java.nio=ALL-UNNAMED`".
See [Illegal Reflective Access Operation](#illegal-reflective-access-operation).

## MCS

For the
[Monitoring Collector Service](https://ultramessaging.github.io/currdoc/doc/Operations/monitoring.html#monitoringcollectorservicemcs) (MCS),
the minimum Java version is 9.
Since this service also uses UM, it requires
"`--add-opens java.base/java.nio=ALL-UNNAMED`".
See [Illegal Reflective Access Operation](#illegal-reflective-access-operation).

## Illegal Reflective Access Operation

Starting in Java 9, the following warning is displayed when using UM's Java API:
```
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by com.latencybusters.lbm.HobByteBuffer (file:/29W/Amun/home/sford/backup_exclude/UMP_6.14/java/UMS_6.14.jar) to field java.nio.Buffer.address
WARNING: Please consider reporting this to the maintainers of com.latencybusters.lbm.HobByteBuffer
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
```

This is because of a programming technique we used to improve the performance
of the Java API greatly.
When our Java API first started using this method,
it was advised against due to being unportable,
but was not documented as having a limited lifetime.
Starting in Java 9, its lifetime was claimed to be limited,
although no specific timetable was given.

Our current solution is to instruct customers to
supply the Java command-line option "`--add-opens java.base/java.nio=ALL-UNNAMED`"

The problem is that all solutions we have investigated result in greater overhead,
which causes lower sustainable throughput.
Our customers want better performance, not worse.

So, our policy is to wait until a version of Java prevents our method before
implementing a different method.
As of Java version 21, UM still functions with the current design.

## Certification

The UM product does not certify against specific versions of Java.

We will perform testing requested by our customers on whatever Java version
they intend to use.
