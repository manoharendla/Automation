#!/usr/bin/env expect
set timeout -1
spawn rm -rf /var/tmp/*
spawn df -kh /var/tmp
if { $::env(TRIAL_RUN) == true } {
        puts "Trial Run is true"
		spawn scp  -oStrictHostKeyChecking=no $::env(HUB_USER:/installgz.exp /var/tmp/install.exp
} else {
        puts "Trial run is false"
        spawn scp -oStrictHostKeyChecking=no $::env(HUB_USER):/home/elephant/monitoring/install_monitoring_7z.exp /var/tmp/install_monitoring.exp
}
expect {
        "yes/no" {send "yes\r"}
        "assword" {send "$::env(HUB_PASS)\r"}
}
expect "100%"

#scp package from hub to /var/tmp
spawn scp  -oStrictHostKeyChecking=no $::env(HUB_USER)@ /var/tmp/

expect {
        "yes/no" {send "yes\r";exp_continue}
       "Enter Windows password:" {send "$::env(HUB_PASS)\r"}
}
expect {
     "100%" {}
     "%" {exp_continue}
}


spawn scp -oStrictHostKeyChecking=no file root@$::env(SERVER_HOSTNAME):/var/tmp/
expect {
                "yes/no" {send "yes\r"exp_continue}
                "assword" {send "$::env(VAPP_PASS)\r";exp_continue}
                "y,n" {send "y\r";exp_continue}
                 -re {Removal of .* was successful} {}
                 "ERROR: no package associated with" {}
        }

spawn scp  file  root@$::env(SERVER_HOSTNAME):/var/tmp/
expect {
                "yes/no" {send "yes\r"exp_continue}
                "assword" {send "$::env(VAPP_PASS)\r";exp_continue}
                "y,n" {send "y\r";exp_continue}
                 -re {Removal of .* was successful} {}
                 "ERROR: no package associated with" {}
        }




spawn ssh root@$::env(SERVER_HOSTNAME) "chmod 777 file ; /var/tmp/install_monitoring.exp"

expect {
                "yes/no" {send "yes\r"exp_continue}
                "assword" {send "$::env(VAPP_PASS)\r";exp_continue}
                "y,n" {send "y\r";exp_continue}
        }
