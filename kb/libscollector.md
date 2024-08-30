# libscollector

Tool to collect core file, executable, and required libraries so that you can open the core file on another host.

<!-- mdtoc-start -->
&bull; [libscollector](#libscollector)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
<!-- TOC created by './mdtoc.pl kb/libscollector.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

If one of your Linux processes crashes and generates a core file,
it can be very helpful to examine the core file to diagnose the reason for the crash.
Usually it is not practical to run a core file debugger on the host that experienced the crash,
so the core file must be copied somewhere else.
This is especially true if you want to send the core file to a vendor for investigation.

However, you need to copy more than just the core file.
You need:
* Core file.
* Executable that crashed.
* Dynamic libraries the executable depends on.

Determining the correct dynamic libraries can be difficult,
so we developed a shell script to automate the process.

Usage:
```
./libscollector.sh <path to executable> <path to core>
```
This tool uses "gdb" and "awk" on the host where it is running.

This tool needs write permission to the current working directory.
It creates a compressed file of the form "`<core file name>_libs_all.tar.gz`".
For example, if the core file is named "`core.1234`",
the file will be "`core.1234_libs_all.tar.gz`".

Note that the tool writes temporary files prefixed with "`/tmp/temp_`".

