#!/bin/bash

ROOT_PATH=`pwd`
source bin/shared.sh

browserify_ () {
    $ROOT_PATH/bin/browserify \
        --alias 'jquery:jquery-browserify' -r jquery-browserify \
        --alias 'jQuery:jquery-browserify' -r jquery-browserify \
        -w -o build/bundle.js lib/browserify.entry.coffee > /dev/null 
}

main () {
    retcode=199
    while [[ ( ! $retcode -eq 0 ) && ( ! $retcode -eq 137 ) ]]; do
        browserify_ 2>&1; retcode=$? | while read line; do
            echo "$line"
            if [[ $line =~ Error ]]; then
                _notify 'browserify error; check its output'
            fi
        done
        exitmsg=">>> Exited with code: $retcode. `date`"
        echo $exitmsg

        if [[ ( ! $retcode -eq 0) ]]; then
            local msg="*** bundler crashed, waiting 5 seconds before restart"
            echo $msg
            _alert "$msg"
            sleep 3 
        fi
    done
}

control_c () {
    echo "Trapped Ctrl-c: killing browserify"
    exit
}
trap control_c SIGINT
main
