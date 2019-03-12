#!/bin/bash
#
#Login and passwords for services
HAPROXY_IP="192.168.56.13"
MOODLE_IP1="192.168.56.11"
MOODLE_IP2="192.168.56.12"
echo "Check & Install updates"
#
# Install EPEL, update all and restart to apply
sudo yum update -y
#
# Installing HAProxy
sudo yum install haproxy -y
# HAProxy configuration
sudo rm /etc/haproxy/haproxy.cfg
sudo touch /etc/haproxy/haproxy.cfg
#
sudo cat <<EOF | sudo tee -a /etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
frontend  main $HAPROXY_IP:80
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js
    use_backend static          if url_static
    default_backend             app
backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check
backend app
    balance     roundrobin
    server  app1 $MOODLE_IP1:80 check
    server  app2 $MOODLE_IP2:80 check
EOF
#
# Start the HAProxy service
sudo systemctl restart haproxy
# MEMCACHE SERVER (SESSION)
sudo yum install memcached -y
#Configuration MEMCACHE
sudo touch /etc/sysconfig/memcached
sudo cat <<EOF | sudo tee -a /etc/sysconfig/memcached
PORT=”11211″
USER=”memcached”
MAXCONN=”1024″
CACHESIZE=”64″
OPTIONS=””
EOF
# Restart Session servise
sudo systemctl restart memcached
