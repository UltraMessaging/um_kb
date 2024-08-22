# Static Linking

<!-- mdtoc-start -->
&bull; [Static Linking](#static-linking)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [The Problem](#the-problem)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Root Cause](#root-cause)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Solution](#solution)  
<!-- TOC created by './mdtoc.pl kb/static-linking.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

## The Problem

We had a customer who built their Linux application with UM
successfully and the program seemed to work fine.
After some discussion, they decided to enable the
[Receive Multiple Datagrams](https://ultramessaging.github.io/currdoc/doc/Design/advancedoptimizations.html#receivemultipledatagrams)
feature to improve their latency and throughput.
However, they got the warning:
````
Core-10383-2: WARNING: multiple_receive_maximum_datagrams or transport_lbtrm_source_timestamp specified but recvmmsg is NOT supported
````
and althought the program still functioned correctly,
the feature was not enabled.

## Root Cause

The program was linked with "-static",
which forces the whole executable static,
including the system libraries like glibc.

However, UM's Receive Multiple Datagrams feature uses the
[recvmmsg()](https://linux.die.net/man/2/recvmmsg) system call,
which was introduced to Linux in 2010.
We wanted UM to work with older versions of Linux while
still taking advantages of new features,
so we use [dlopen()](https://linux.die.net/man/3/dlopen)
to look up the "recvmmsg" symbol.
But that doesn't work right for statically linked
executables; hence the "recvmmsg is NOT supported" warning.

Static linking can slightly improve performance,
so many customers want to statically link as much of
their program as feasible, including the UM library.
However, there are several potential problems with statically linking glibc,
so except for
[special circumstances](https://developers.redhat.com/articles/2023/08/31/how-we-ensure-statically-linked-applications-stay-way),
Informatica generally recommends not statically linking glibc.
In particular, some UM features are unavailable if glibc is statically linked
due to those features' use of dlopen().

## Solution

Our recommended solution to the customer was to remove "-static" from
their application link and include individual ".a" libraries for
those libraries that are safe to statically include.

With more-recent versions of Linux,
you may also need to include "-no-pie" to prevent the linker from
trying to build a position-independent executable (UM is not built with PIC).

Here is an example build command that includes UM's static library:
````
g++ -no-pie -Wall -Wextra -g -std=c++2a -fPIC \
  -I $LBM/include -I $LBM/include/lbm -pthread \
  -Wl,--whole-archive $LBM/lib/liblbm.a -Wl,--no-whole-archive \
  /usr/lib/x86_64-linux-gnu/librt.a /usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.a \
  -l dl -l m \
  -o main main.cpp
````
Note the "-Wl,--whole-archive" and "-Wl,--no-whole-archive"
wrapping the UM library.
This is needed to ensure proper initialization when
statically linking with UM.

Note also that while librt and libstdc++ are safe to statically link,
libdl and libm are typically not.
