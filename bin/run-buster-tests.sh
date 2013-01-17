#!/bin/bash

STD_ARGS="-c ./buster.js "
[[ -e ~/.buster_selector ]] && \
    TEST_SELECTOR=$(cat ~/.buster_selector) || \
    TEST_SELECTOR=""

node_test() {
    bin/buster-test $STD_ARGS -e node $TEST_SELECTOR
}

browser_test() {
    bin/buster-test $STD_ARGS -e browser $TEST_SELECTOR
}

case "$1" in
    "browser")
       browser_test 
       ;;
    "node")
        node_test
        ;;
    *)
       bin/buster-test $STD_ARGS $TEST_SELECTOR
       ;;
esac
