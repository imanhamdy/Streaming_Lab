#!/usr/bin/env bash
set -u

MEDIA_DIR="/home/principal/media/movies"
JELLYFIN_CONTAINER="jellyfin"
FFPROBE="/usr/lib/jellyfin-ffmpeg/ffprobe"

echo ""
echo "=================================================="
echo " DUOOWATCH MEDIA VALIDATION"
echo "=================================================="

fail=0
pass=0

find "$MEDIA_DIR" -maxdepth 1 -type f | while read -r file; do
    name="$(basename "$file")"

    echo ""
    echo "Testing: $name"
    echo "--------------------------------------------------"

    if [ ! -s "$file" ]; then
        echo "FAIL: file is empty"
        continue
    fi

    ls -lh "$file"
    file "$file"

    if docker exec "$JELLYFIN_CONTAINER" "$FFPROBE" "/media/movies/$name" >/dev/null 2>&1; then
        echo "PASS: Jellyfin ffprobe can read this file"
    else
        echo "FAIL: Jellyfin ffprobe cannot read this file"
    fi
done

echo ""
echo "Done."
echo "If all target videos PASS, rescan Jellyfin library."
