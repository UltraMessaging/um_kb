# Managing LBT-IPC Host Resources

This content was originally in the [Informatica Knowledgebase](https://knowledge.informatica.com/s/article/80201?language=en_US).


<!-- mdtoc-start -->
&bull; [Managing LBT-IPC Host Resources](#managing-lbt-ipc-host-resources)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [How Can LBT-IPC Resources Become Orphaned?](#how-can-lbt-ipc-resources-become-orphaned)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Commands by Type and Platform](#commands-by-type-and-platform)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Suggested Order of Command Usage](#suggested-order-of-command-usage)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Additional Information](#additional-information)  
<!-- TOC created by './mdtoc.pl kb/managing-lbt-ipc-host-resources.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->


LBT-IPC exploits host resources to provide ultra-low latency to LBM source and receiver applications running on the same host.  These resources include semaphores (mutexes and events on Microsoft® Windows®) and shared memory segments, along with internal LBT-IPC components such as the resource allocation database.


In the usual case, managing these resources is best left to LBT-IPC itself.  But there are certain specific situations where these resources can become "orphaned". Therefore, to display and/or clean up these resources a user might want to take advantage of the various commands available.

This article will cover how resources become orphaned, a table of commands by type and platform, and suggested order of command usage.

## How Can LBT-IPC Resources Become Orphaned?

Normally, LBT-IPC cleans up these host resources in the API calls lbm_src_delete() and lbm_rcv_delete() (source and receiver, respectively) along with lbm_context_delete(). Be sure your applications use these calls in the appropriate spots.

If you don't make these delete API calls, or if any type of early termination of an LBT-IPC process skips them, the internal cleanup built into them will also be skipped. This can lead to orphaned resources.

If this happens often enough, eventually one or more resources required to open a new LBT-IPC transport (or another user of these resources) might not be available until the resources are released back to the operating system.

These resources remain orphaned until the next system reboot, which automatically cleans up up all host resources acquired by LBT-IPC.

## Commands by Type and Platform

The preferred command to display and free LBT-IPC resources is the LBM command `lbtipc_resource_manager`. This command works on all supported LBM platforms except Windows, where the underlying host resources are managed exclusively by the Windows operating system.

For a complete description of this command and sample output, see the "Transport LBT-IPC" section of LBM Design Concepts.

When issued with no keywords, the command displays resources in use.

When issued with the `-reclaim` keyword, it cleans up the semaphores, mutexes, and shared memory segments, plus other internal LBT-IPC host resources created to manage them. An added benefit is that if new functionality is added to LBT-IPC, any new host resources introduced will be automatically cleaned up via `lbtipc_resource_manager` as well.

*NOTE*: It is not safe to run the `lbtipc_resource_manager -reclaim` while IPC-enabled applications or daemons are running.  Doing so can result in a crash in the applications which publish to IPC transports.

Various other OS commands that can optionally be used are listed by platform below. Before using them, see notes below in "Suggested Order of Command Usage", and consult your local man pages for full usage details. Also, be very careful when using them, since all processes that use these host resources will be affected, not just LBT-IPC processes.

Windows is not included in the table because no commands to display or manage them are available. However, you can download and run a tool named WinObj to see these shared resources (expand BaseNamedObjects and then look for resources starting with "LBTIPC_").

| Function | Linux | Solaris | OS X | AIX |
| -------- | ----- | ------- | ---- | --- |
| display semaphores | `ipcs -s` | `ipcs -s` | `ipcs -s` | `ipcs -s` |
| remove semaphores | `ipcrm -s` | `ipcrm -s` | `ipcrm -s` | `ipcrm -s` |
| display shared memory segments | `ls /dev/shm` | -- | -- | -- |
| remove shared memory segments | `rm /dev/shm/name` | -- | -- | -- |

## Suggested Order of Command Usage

In order to prevent orphaned resources, the first and most important step is to make sure your applications call `lbm_src_delete()` for each source, `lbm_rcv_delete()` for each receiver, and `lbm_context_delete()` for each context before exiting. This is the recommended practice for all LBM transports.

If necessary to free orphaned resources, however, there are a variety of ways to do this.

The following list is in order of recommended use by 29West. Descriptions and notes for command usage follow the name of the command.

1. Reclaim via 29West command

````
$ lbtipc_resource_manager -reclaim
````

Frees all orphaned resources, including semaphores (or mutexes), shared memory segments, and updates the LBT-IPC resource allocation database to reflect the new cleaned-up state.

Informatica recommends use of this command for all LBT-IPC resource cleanup.  Users may even want to include this in their regular periodic maintenance procedures, but care should be taken to ensure that the IPC-enabled applications and daemons are not running when the reclaim operation is performed.

Note that database resources owned by users other than the user issuing the command may not be freed, unless issued by a user with root authority.

2. List and Free Semaphores via OS Command

````
$ ipcs -s
````

Lists semaphores. May be used before removing semaphores.

````
$ ipcrm -s
````

Removes semaphores. Requires authorization (see local man page for server in question).

3. List and Free Shared Memory Segments via OS Command

````
$ ls /dev/shm
````

(Linux only) Lists shared memory regions.

````
$ rm /dev/shm
````

(Linux only) Removes shared memory regions.

4. Delete via 29West Command

````
$ lbtipc_resource_manager -delete
````

NOTE: Recommended for use only at the direction of 29West Support.

Deletes the IPC resource allocation database. Affects running LBT-IPC processes. This command does not reclaim resources first; for best practices, always issue the command with -reclaim first.

## Additional Information

For more information, see [Ultra Messaging Concepts Guide, LBT-IPC Resource Manager](https://ultramessaging.github.io/currdoc/doc/Design/transporttypes.html#lbtipcresourcemanager).
