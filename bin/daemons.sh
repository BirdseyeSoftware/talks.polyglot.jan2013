#!/bin/bash

ROOT_PATH=`pwd`

PATH=`pwd`/bin:$PATH
source bin/shared.sh


express_server () {
  $ROOT_PATH/bin/run-server.sh 
} 

browserify_bundle () {
  $ROOT_PATH/bin/bundle.sh 
} 

compile_coffee () {
    $ROOT_PATH/bin/coffee -w -c ./{test,lib}/*.coffee 2>&1 | while read line; do 
        echo "$line"
        if [[ $line =~ error ]]; then
            _alert 'COFFEESCRIPT PARSE ERROR'
        fi
    done
}

compile_sass () {
    $ROOT_PATH/bin/sass --scss --unix-newlines --trace \
        --watch assets/ringmaster.scss:assets/ringmaster.css
}

start() {
    compile_sass &
    compile_coffee &
    browserify_bundle &
    sleep 0.5 
    express_server &
    $ROOT_PATH/bin/buster server & # fork to a subshell
    sleep 2 # takes a while for buster server to start
    $ROOT_PATH/bin/phantomjs ./test/phantom.js &
    echo "Started Buster.JS server, Phantom.JS client & sass / coffeescript compilers"
}

stop() {
    pkill -f "$ROOT_PATH/bin/"
    echo "Killed Buster.JS server and Phantom.JS client"
}

case "$1" in
    "start")
        stop
        start
        ;;
    "stop")
        stop
        ;;
    *)
        echo "Usage:
$0 start|stop"
        ;;
esac

