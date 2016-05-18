#!/bin/bash -e

DIR=${1:?data dir required}

max=$(ls ${DIR}/ | grep "[0-9]" -o | sort -u | tail -n 1)

for bench in no; do
    echo $bench
    echo "Requests Req/s"
    for i in $(seq 1 $max); do
        requests=$(grep "requests in" ${DIR}/wrk-${bench}-${i}.log | awk '{print $1}')
        reqpers=$(grep "Requests/sec" ${DIR}/wrk-${bench}-${i}.log | awk '{print $2}' | tr . ,)
        echo "$requests $reqpers"
    done
    echo ""
done

for bench in default snaplen buffer snaplen+buffer filter; do
    echo $bench
    echo "Requests Req/s Filtered Dropped"
    for i in $(seq 1 $max); do
        requests=$(grep "requests in" ${DIR}/wrk-${bench}-${i}.log | awk '{print $1}')
        reqpers=$(grep "Requests/sec" ${DIR}/wrk-${bench}-${i}.log | awk '{print $2}' | tr . ,)
        filtered=$(grep "received by filter" ${DIR}/tcpdump-${bench}-${i}.log | awk '{print $1}')
        dropped=$(grep "dropped by kernel" ${DIR}/tcpdump-${bench}-${i}.log | awk '{print $1}')
        echo "$requests $reqpers $filtered $dropped"
    done
    echo ""
done
