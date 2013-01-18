#!/bin/bash

ROOT_PATH=`pwd`
source bin/shared.sh

express_server () {
    $ROOT_PATH/bin/coffee -w lib/server.coffee
}

main () {
    retcode=199
    while [[ ( ! $retcode -eq 0 ) && ( ! $retcode -eq 137 ) ]]; do
        express_server 2>&1; retcode=$? | while read line; do
            echo "$line"
            if [[ $line =~ Error ]]; then
                _notify 'express server error; check its output'
            fi
        done
        exitmsg=">>> Exited with code: $retcode. `date`"
        echo $exitmsg

        if [[ ( ! $retcode -eq 0) ]]; then
            local msg="*** express server crashed, waiting a bit before restart"
            echo $msg
            _alert "$msg"
            sleep 1.5 
        fi
    done
}

control_c () {
    echo "Trapped Ctrl-c: killing express server"
    exit
}
trap control_c SIGINT
main
