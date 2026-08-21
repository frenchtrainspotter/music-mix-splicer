#!/usr/bin/env bash

show_help() {
    echo "Usage: $(basename $0) [-h|--help] [-i|--input <filepath>] [split-times]"
    echo
    echo "Options:"
    #echo " -c, --codec <codec>      Change codec used by FFmpeg. Defaults to copying without re-encoding."
    echo " -h, --help               Display this help message"
    echo " -i, --input <filepath>   Input file"
    exit 0
}

options=$(getopt -o "hi:" --long "help,input:" -n "$(basename $0)" -- "$@")

if [ $? -ne 0 ]; then
    echo "Failed to parse options" >&2
    exit 1
fi

eval set -- "$options"

#codec="copy"
help=false
input=""

while true; do
    case "$1" in
	    -h | --help)
              show_help
              ;;
            -i | --input)
              input="$2"
              shift 2
              ;;
            --)
              shift
              break
              ;;
            *)
              echo "Invalid argument!"
              exit 1
              ;;
    esac
done
