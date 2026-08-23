#!/usr/bin/env bash
# music-mix-splicer: a small shell script to split and name music files with ffmpeg

# Help
show_help() {
    echo "Usage: $(basename $0) [-h|--help] [-i|--input <filepath>] [split-times]"
    echo
    echo "Options:"
    echo " -a, --automatic              Run non-interactively, requires -e to determine filename"
    echo " -c, --codec          <codec> Change codec used by FFmpeg (default: copy)"
    echo " -e, --extension      <ext>   File extension for output, allows automatic operation"
    echo " -f, --ffmpeg-out             Display FFmpeg output"
    echo " -i, --input          <path>  Input file"
    echo " -h, --help                   Display this help message and quit"
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
options=$(getopt -o "ac:e:fi:h" --long "automatic,codec:,extension,ffmpeg-out,input:,help" -n "$(basename $0)" -- "$@")

if [[ $? -ne 0 ]]; then
    err "Failed to parse options" fatal
fi

eval set -- "$options"

automatic=false
codec="copy"
extension=""
ffmpeg_out=false
input=""


while true; do
    case "$1" in
        -a | --automatic)
          automatic=true
          shift
          ;;
        -c | --codec)
          codec="$2"
          shift 2
          ;;
        -e | --extension)
          extension=".$2"
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
          err "Internal error - invalid argument" fatal
          ;;
    esac
done

# Try to catch bad args (incl. positional args)
# No input
if [[ -z "$input" ]]; then
    err "No input file specified" fatal
fi
# Automatic without extension
if [[ $automatic = true && -z $extension ]]; then
    err "No extension specified, but automatic operation enabled" fatal
fi

# Initialize non-argument variables
tracknumber=1

# Generate output
write_out() {
    local filename=""
    if [[ -z "$extension" ]]; then
        read -rp "Filename for track $tracknumber (with extension): " filename
    elif [[ $automatic = true ]]; then
        filename="$(printf %02d $tracknumber)"
        echo "${filename}${extension}"
    else
        read -erp "Filename for track $tracknumber (without extension): " -i "$(printf %02d $tracknumber)" filename
    fi
    ((tracknumber++))
    if [[ -z "$filename" ]]; then
        err "Filename must not be empty!" fatal
    fi
    filename="${filename}${extension}"
    local ffmpegcmd="ffmpeg -i $input -c $codec -ss $1 -to $2 $filename"
    if [[ $ffmpeg_out = true ]]; then
        $ffmpegcmd
    else
        # This command should be made so /dev/stderr isn’t flushed to /dev/null
        # Also, if possible, progress should be kept on screen
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

