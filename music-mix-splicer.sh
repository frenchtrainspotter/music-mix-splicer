#!/usr/bin/env bash
# music-mix-splicer: a small shell script to split and name music files with ffmpeg

# Help
show_help() {
    echo "Usage: $(basename $0) [-h|--help] [-i|--input <filepath>] [split-times]"
    echo
    echo "Options:"
    echo " -c, --codec <codec>      Change codec used by FFmpeg (default: copy)"
    echo " -f, --ffmpeg-out         Display FFmpeg output"
    echo " -i, --input <filepath>   Input file"
    echo " -h, --help               Display this help message and quit"
    exit 0
}

# Quick way to make error
err() {
    echo "$1" >&2
    if [[ "$2" == "fatal" ]]; then
        exit 1
    fi
}

# Parse options
options=$(getopt -o "c:fi:h" --long ",codec:,ffmpeg-out,input:,help" -n "$(basename $0)" -- "$@")

if [[ $? -ne 0 ]]; then
    err "Failed to parse options"
    exit 1
fi

eval set -- "$options"

codec="copy"
ffmpeg_out=false
input=""


while true; do
    case "$1" in
        -c | --codec)
          codec="$2"
          shift 2
          ;;
	-f | --ffmpeg-out)
          ffmpeg_out=true
          shift
          ;;
        -i | --input)
          input="$2"
          shift 2
          ;;
        -h | --help)
          show_help
          ;;
        --)
          shift
          break
          ;;
        *)
          err "Internal error - invalid argument!"
          exit 1
          ;;
    esac
done

# Try to catch bad args (incl. positional args)
if [[ -z "$input" ]]; then
    err "No input file specified"
fi

# Generate output
write_out() {
    local filename=""
    read -rp "Filename for track from $1 to $2: " filename
    if [[ -z "$filename" ]]; then
        err "Filename must not be empty!"
        exit 1
    fi
    local ffmpegcmd="ffmpeg -i $input -c $codec -ss $1 -to $2 $filename"
    if [[ $ffmpeg_out = true ]]; then
        $ffmpegcmd
    else
        $ffmpegcmd &>/dev/null
    fi
    # There should be a check added to FFmpeg’s exit code to avoid missing an error
}

# The 1st unnamed arg is the first split, so we need to add 00 as the start time
write_out "00:00:00.00" "$1"
# Call write_out to cover every intermediate track
while [[ $# -gt 1 ]]
do
    write_out "$1" "$2"
    shift
done
# For the last track, there is no end time in args, query file end time w/ ffprobe
write_out "$1" "$(ffprobe $input -show_entries format=duration -sexagesimal -v quiet -of csv="p=0")"

exit 0

