#!/bin/bash
#
# Finds instances of Prophecy running in the QA lab and 
# determines the version installed.
# __author__: "Richard Calvert"
set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

DEBUG=${1:-}  # syntax means if $1 arg present, use that, otherwise leave variable emtpy
TEMP_FILE="ip_list.txt";
pad='________________________________________________________'
width=40
cblue=$'\e[1;34m'
cend=$'\e[0m'
ip_list=""

printf "Looking up Prophecy versions..."

debug () {
    set +e
    [[ ${DEBUG} ]] && printf "DEBUG: %s: %s\n" ${FUNCNAME[0]} $1
    set -e
}

delete_temp_file () {
    set +e
    [[ -f ${TEMP_FILE} ]] && rm -f ${TEMP_FILE}
    set -e
}


err () {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
    delete_temp_file
    exit $1
}


make_ip_list () {
    wait_for_file_write_complete &
    ip_list=$(nmap -p 9999 -T5 -oG - --open 10.1.150.0/24 \
                | grep -v nmap \
                | awk '$0 ~ /9999/ {print $2}'
              )

    delete_temp_file  # this is to let wait_for_file_write_complete know the function completed.
    sleep 1
    debug ${ip_list}
    if [ -z "$ip_list" ]
    then
        printf "\nNo ips found on nmap call.  Are you connected to the lab?  Exiting..."
        err 2
    fi
}


set_net_host () {
    local host_ip=$1

    set +e
    local version=$(curl  "http://$host_ip:9999/versions_10" \
                      | grep prophecy \
                      | egrep -o "\d+\..*\d"
                   )
    set -e

    debug "current ip ${host_ip}, version=${version}"

    if [ -n "$version" ]
    then
        printf "%s"     "${cblue}${host_ip}${cend}"

        printf "%*.*s"  0 \
                        $(($width - ${#host_ip} - ${#version} )) \
                        "$pad"

        printf "%*s\n"  ${#version} \
                        "${cblue}${version}${cend}"
    fi
}


wait_for_file_write_complete () {
    touch ${TEMP_FILE}

    set +e
    while [[ -f ${TEMP_FILE} && \
                $(( $(date +%s) - $(stat -f "%c" ${TEMP_FILE}) )) -lt 10 ]]
    do
        printf "."
        sleep 1
    done
    set -e
}

build_resource_file () {
    wait_for_file_write_complete &
    for host_ip in ${ip_list}
    do
        ( set_net_host ${host_ip} ) 1>>${TEMP_FILE} 2>/dev/null &
        sleep 0.25;
    done
}

print_results () {
    printf "\n"
    cat ${TEMP_FILE}
}

trap err SIGHUP SIGINT SIGTERM

# __Main steps completed below this point__:
delete_temp_file
make_ip_list
build_resource_file
print_results
delete_temp_file
