#!/bin/bash
while read p; do
echo $p
 {
 /usr/bin/expect <<EOF
 spawn scp $p root@ms-1:/var/tmp
 expect "password:"
 send "123\r"
 expect "#"
 EOF
 }
 done <Lists.txt
