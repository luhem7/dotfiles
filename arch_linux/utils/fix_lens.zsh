#!/bin/zsh
# This script is used to undistort distortions caused by recording videos in 0.5x mode on an iPhone 16 Pro help in portrait mode.

# Check if a prefix was provided
if [[ -z "$1" ]]; then
  echo "Usage: ./fix_lens.zsh [FILE_PREFIX]"
  echo "Example: ./fix_lens.zsh 202512"
  exit 1
fi

PREFIX="$1"
OUT_DIR="corrected"

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Enable nullglob so the script doesn't crash if no files match
setopt nullglob

# Find files matching the prefix (case insensitive for extension)
files=(${PREFIX}*.(mp4|MP4|mov|MOV|mkv|MKV))

if (( ${#files} == 0 )); then
  echo "No files found with prefix: $PREFIX"
  exit 1
fi

echo "Found ${#files} files. Engaging RTX 4080 engines..."
echo "---------------------------------------------------"

for f in $files; do
  # Extract filename without extension for the output
  filename=$(basename "$f")
  basename="${filename%.*}"
  outfile="$OUT_DIR/${basename}.mp4"

  echo "Processing: $f -> $outfile"

  # -vf "lenscorrection=k1=0.3" This is the main parameter used to undistort the videos, a higher value = more distortion
  #        There are a TON of options that can go here to fix the distortion
  # -map_metadata 0: Copies all internal tags (Date, GPS, etc.)
  # -c:v hevc_nvenc: Use NVIDIA H.265 Encoder
  # -preset p7: Slowest/Best quality preset on Ada Lovelace
  # -tier high: Allows higher bitrates for complex scenes (Sports)
  # -cq 16: Constant Quality 16 (Lower is higher quality. 19 is standard, 16 is archival)
  # -b:v 0: Let the CQ parameter control the bitrate entirely
  
  ffmpeg -hide_banner -loglevel error -i "$f" \
    -vf "lenscorrection=k1=0.3" \
    -map_metadata 0 \
    -c:v hevc_nvenc \
    -preset p7 \
    -tier high \
    -cq 16 -b:v 0 \
    -c:a copy \
    "$outfile"

  if [[ $? -eq 0 ]]; then
    # Clone the file modification time from the original to the new file
    touch -r "$f" "$outfile"
    echo "✅ Success: $filename (Metadata & Timestamps preserved)"
  else
    echo "❌ Error processing $filename"
  fi
done

echo "---------------------------------------------------"
echo "Job complete. Files are located in the '$OUT_DIR' folder."
