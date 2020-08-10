#!/bin/sh
#
#  only doing all the sudos as cloud-init doesn't run as root, likely better to use Azure VM Extensions
#
#  $1 is the forwarder, $2 is the vnet IP range
#

touch /tmp/forwarderSetup_start
echo "$@" > /tmp/forwarderSetup_params

#  Install Bind9
#  https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-14-04
sudo apt-get update -y
sudo apt-get install bind9 -y

# configure Bind9 for forwarding
sudo cat > named.conf.options << EndOFNamedConfOptions
acl goodclients {
    $2;
    localhost;
    localnets;
};

options {
        directory "/var/cache/bind";

        recursion yes;

        allow-query { goodclients; };
        deny-answer-addresses {
        // Unconfigured
        0.0.0.0;
        // 0.0.0.0 - 7.255.255.255
        0.0.0.0/5;
        // 8.0.0.0 - 9.255.255.255
        8.0.0.0/7;
        // 11.0.0.0 – 11.255.255.255
        11.0.0.0/8;
        // 12.0.0.0 - 13.255.255.255
        12.0.0.0/7;
        // 14.0.0.0 - 15.255.255.255
        14.0.0.0/7;
        // 16.0.0.0 – 31.255.255.255
        16.0.0.0/4;
        // 32.0.0.0 – 63.255.255.255
        32.0.0.0/3;
        // 64.0.0.0 – 128.255.255.255
        64.0.0.0/2;
        // 128.0.0.0 – 255.255.255.255
        128.0.0.0/1;
        }except-from { "black.list"; };

        forwarders {
            $1;
        };
        forward only;

        dnssec-validation auto;

        auth-nxdomain no;    # conform to RFC1035
        listen-on { any; };
};
EndOFNamedConfOptions

sudo cp named.conf.options /etc/bind
sudo service bind9 restart

touch /tmp/forwarderSetup_end
