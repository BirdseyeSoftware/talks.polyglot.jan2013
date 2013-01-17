#!/bin/bash

_alert () {
    command -v _emacsclient_silent && _emacsclient_silent "(progn (dss/flash-modeline) (message \"$1\"))"
}

_notify () {
    command -v _emacsclient_silent && _emacsclient_silent "(message \"$1\")"
}
