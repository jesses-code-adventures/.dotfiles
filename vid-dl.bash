#!/bin/bash

if [ $# -lt 2 ]; then
  echo "usage: $0 <video_url> <output_filename_without_extension> [--audio-only] [--url]"
  exit 1
fi

VIDEO_URL="$1"
OUTPUT_FILENAME="$2"
AUDIO_ONLY=true
SAVE_URL=true

if [ "$3" == "--audio-only" ] || [ "$4" == "--audio-only"  ]; then
  AUDIO_ONLY=true
fi

if [ "$3" == "--no-url" ] || [ "$4" == "--no-url" ]; then
  SAVE_URL=false
fi

if [ "$AUDIO_ONLY" = true ]; then
  yt-dlp -f 'bestaudio' -x --audio-format mp3 -o "${OUTPUT_FILENAME}.mp3" "$VIDEO_URL"
else
  yt-dlp -f 'bv*[vcodec^=avc]/b[ext=mp4]/b' -o "${OUTPUT_FILENAME}.mp4" "$VIDEO_URL"
fi

if [ "$SAVE_URL" = true ]; then
  echo "$VIDEO_URL" > "${OUTPUT_FILENAME}.url"
fi
