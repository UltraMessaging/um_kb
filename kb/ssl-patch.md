# SSL Patch

Older versions of UM are linked with old, vulnerable versions of the OpenSSL
libraries "libssl.so" and "libcrypto.so".
Customers wishing to eliminate the vulnerable files from their systems may
follow these instuctions.

<!-- mdtoc-start -->
&bull; [SSL Patch](#ssl-patch)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Introduction](#introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Is Patching Necessary?](#is-patching-necessary)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [UM Versions 6.8 and Below](#um-versions-68-and-below)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [CentOS: UM 6.8 and Below](#centos-um-68-and-below)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Ubuntu: UM 6.8 and Below](#ubuntu-um-68-and-below)  
<!-- TOC created by './mdtoc.pl kb/ssl-patch.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


## Introduction

Older versions of Ultra Messaging library (liblbm.so) are linked with old,
vulnerable versions of the OpenSSL libraries "libssl.so" and "libcrypto.so".
System administrators frequently deploy automated security checkers
which flag the UM-supplied OpenSSL libraries as vulnerable.
They request that we either remove the vulnerable files or upgrade to
a newer, more-secure version of OpenSSL.

This article describes procedures for older UM version up to and including 6.8.*,
and newer versions 6.12 and above.
In all cases, it is assumed that UM encryption features are not being used.

For UM versons 6.9.* - 6.11.*, there is no usable patch; users
must upgrade to version 6.12 or beyond.

### Is Patching Necessary?

It could be argued that for customers that are not using the UM encryption
features, there is no compelling need to make any changes.
It doesn't matter if the OpenSSL functions are vulnerable since the UM library
won't call any of them.

However, we understand that IT departments establish policies to ensure
their systems aren't vulnerable.
It's one thing to say that UM won't call the functions, but it's another thing
to prove cannot happen.

So, in an abundance of caution, the following procedures eliminate the
vulerable code altogether.

ATTENTION: in some cases we replace the older vulnerable library with a
symbolic link of the same name.
This might trigger a false positive on an automated system scan that
assumes the name of the file alone indicates the library version.
Unfortunately, for older versions of UM, the name of the link
cannot be changed.
Please rest assured that the link references an acceptable version.

## UM Versions 6.8 and Below

The principle is to replace UM's OpenSSL libraries with your system's
resident versions.
It is assumed that the OpeSSL version resident on your system complies with
your policies.

Two examples will be given, one on a CentOS system and the other on Ubuntu.

### CentOS: UM 6.8 and Below

1. Determine where your system stores the OpenSSl libraries.
   ```
   $ ldd `which ssh` | egrep libcrypto
           libcrypto.so.1.1 => /lib64/libcrypto.so.1.1 (0x00007facbd1ff000)
   ```
   The desired libcrypto is after the "=>": /lib64/libcrypto.so.1.1.
   Note the directory "/lib64".


2. Using the directory determined from step 1, identify the latest libssl.so.* file.
   ```
   $ ls -F /lib64/libssl.so.*
   /lib64/libssl.so.1.1@  /lib64/libssl.so.1.1.1g*
   ```
   The "-F" flag adds a suffix character. Ignore the "@" file since it's a symbolic
   link. The "*" means executable, so the desired library is /lib64/libssl.so.1.1.1g
   (without the "*").

3. Move the vulnerable files to /tmp.
   Substitute your UM location on the "cd" command.
   ```
   $ cd $HOME/UMP_6.7.1.7/Linux-glibc-2.5-x86_64/lib
   $ ls libssl.so.* libcrypto.so.*
   libcrypto.so.1.0.0   libssl.so.1.0.0
   $ mv libcrypto.so.1.0.0   libssl.so.1.0.0 /tmp/
   ```

4. Create symbolic links for the files.
   ```
   $ ln -s /lib64/libssl.so.1.1.1g libssl.so.1.0.0
   $ ln -s /lib64/libcrypto.so.1.1 libcrypto.so.1.0.0
   ```

### Ubuntu: UM 6.8 and Below

1. Determine where your system stores the OpenSSl libraries.
   ```
   $ ldd `which ssh` | egrep libcrypto
           libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007ff30e7e3000)
   ```
   The desired libcrypto is after the "=>": /lib/x86_64-linux-gnu/libcrypto.so.1.1.
   Note the directory "/lib/x86_64-linux-gnu".

2. Using the directory determined from step 1, identify the latest libssl.so.* file.
   ```
   $ ls -F /lib/x86_64-linux-gnu/libssl.so.*
   /lib/x86_64-linux-gnu/libssl.so.1.1
   ```
   No symbolic link was found, and the library is not executable.
   But that's OK, it's the right one.

3. Move the vulnerable files to /tmp.
   Substitute your UM location on the "cd" command.
   ```
   $ cd $HOME/UMP_6.7.1.7/Linux-glibc-2.5-x86_64/lib
   $ ls libssl.so.* libcrypto.so.*
   libcrypto.so.1.0.0   libssl.so.1.0.0
   $ mv libcrypto.so.1.0.0   libssl.so.1.0.0 /tmp/
   ```

4. Create symbolic links for the files.
   ```
   $ ln -s /lib/x86_64-linux-gnu/libssl.so.1.1 libssl.so.1.0.0
   $ ln -s /lib/x86_64-linux-gnu/libcrypto.so.1.1 libcrypto.so.1.0.0
   ```

