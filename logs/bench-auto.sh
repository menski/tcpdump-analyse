#!/bin/bash

set -x
set -e

iter=${1:?Iterations required}
offset=${2:?Offset required}

NGINX=/root/menski/nginx-1.9.15/build/sbin/nginx
TCP_DUMP=/root/menski/tcpdump-4.3.0/build/sbin/tcpdump
WRK=/root/menski/wrk-4.0.2/wrk
LOGS=/root/menski/logs
DUMP=/root/menski/dump.pcap
DURATION=5m
DELAY=1m
THREADS=4
CONNECTIONS=1024

function start_nginx {
    ssh ib6 "$NGINX"
}

function stop_nginx {
    ssh ib6 "$NGINX -s quit"
}

function run_wrk {
    local log_file="${LOGS}/wrk-${1}-${2}.log"
    $WRK -t $THREADS -c $CONNECTIONS -d $DURATION http://ib6 > $log_file
    cat $log_file
}

function start_tcpdump {
    ssh ib6 "$TCP_DUMP -i eth1 -w $DUMP $3 &> ${LOGS}/tcpdump-${1}-${2}.log &"
}

function stop_tcpdump {
    ssh ib6 "pkill tcpdump"
}

function rm_dump {
    ssh ib6 "rm -f $DUMP"
}

for n in $(seq 1 $iter); do
    let i=n+offset

    bench="no"
    start_nginx
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_nginx
    sleep $DELAY

    bench="default"
    start_nginx
    start_tcpdump $bench $i "-s 65535 -B 2048 ip dst host 172.16.0.26 and tcp dst port 80"
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_tcpdump
    stop_nginx
    rm_dump
    sleep $DELAY

    bench="snaplen"
    start_nginx
    start_tcpdump $bench $i "-s 142 -B 2048 ip dst host 172.16.0.26 and tcp dst port 80"
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_tcpdump
    stop_nginx
    rm_dump
    sleep $DELAY

    bench="buffer"
    start_nginx
    start_tcpdump $bench $i "-s 65535 -B 4096 ip dst host 172.16.0.26 and tcp dst port 80"
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_tcpdump
    stop_nginx
    rm_dump
    sleep $DELAY

    bench="snaplen+buffer"
    start_nginx
    start_tcpdump $bench $i "-s 142 -B 4096 ip dst host 172.16.0.26 and tcp dst port 80"
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_tcpdump
    stop_nginx
    rm_dump
    sleep $DELAY

    bench="filter"
    start_nginx
    start_tcpdump $bench $i "-s 142 -B 4096 ip dst host 172.16.0.26 and tcp dst port 80 and 'tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420'"
    sleep 5s
    run_wrk $bench $i
    sleep 5s
    stop_tcpdump
    stop_nginx
    rm_dump
    sleep $DELAY
done

