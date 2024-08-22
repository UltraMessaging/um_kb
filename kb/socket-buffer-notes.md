# Socket Buffer Notes

[Socket buffers: more complicated than you think](https://blog.geeky-boy.com/2014/02/socket-buffers-more-complicated-than.html) - interesting information on receive-side UDP socket buffers.

## Default UDP Send Buffer Size

### Solaris
If you’re 5.11, then you should be using the “ipadm” command. For 5.10, “ndd” is right.

Also, here’s a very valuable page: https://docs.oracle.com/cd/E26502_01/html/E29022/appendixa-28.html#glbyv

Notice the name changes. On 5.10, send_buf is called udp_xmit_hiwat (which makes no sense to me, but oh well).

On my 5.10 machine:
````
# ndd -get /dev/udp '?' 
?                             (read only)
udp_wroff_extra               (read and write)
udp_ipv4_ttl                  (read and write)
udp_ipv6_hoplimit             (read and write)
udp_smallest_nonpriv_port     (read and write)
udp_do_checksum               (read and write)
udp_smallest_anon_port        (read and write)
udp_largest_anon_port         (read and write)
udp_xmit_hiwat                (read and write)
udp_xmit_lowat                (read and write)
udp_recv_hiwat                (read and write)
udp_max_buf                   (read and write)
udp_ndd_get_info_interval     (read and write)
udp_extra_priv_ports          (read only)
udp_extra_priv_ports_add      (write only)
udp_extra_priv_ports_del      (write only)
udp_status                    (read only)
udp_bind_hash                 (read only)
# ndd -get /dev/udp udp_xmit_hiwat 
57344
````

Which matches the value documented.
