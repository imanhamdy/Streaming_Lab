#!/usr/bin/env bash
set -u

MEDIA_DIR="/home/principal/media/movies"
JELLYFIN_CONTAINER="jellyfin"
FFPROBE="/usr/lib/jellyfin-ffmpeg/ffprobe"

mkdir -p "$MEDIA_DIR"
cd "$MEDIA_DIR" || exit 1

download() {
    local url="$1"
    local name="$2"

    echo ""
    echo "=================================================="
    echo "Downloading: $name"
    echo "URL: $url"
    echo "=================================================="

    rm -f "$name"

    if ! wget --progress=bar:force:noscroll --timeout=30 --tries=3 -O "$name" "$url"; then
        echo "WARN: download failed: $name"
        rm -f "$name"
        return 0
    fi

    if [ ! -s "$name" ]; then
        echo "WARN: empty file: $name"
        rm -f "$name"
        return 0
    fi

    echo "Downloaded:"
    ls -lh "$name"

    if docker exec "$JELLYFIN_CONTAINER" "$FFPROBE" "/media/movies/$name" >/dev/null 2>&1; then
        echo "OK: valid media: $name"
    else
        echo "WARN: ffprobe failed, deleting: $name"
        rm -f "$name"
        return 0
    fi
}

echo ""
echo "=================================================="
echo " DUOOWATCH DEMO MEDIA INSTALLER"
echo "=================================================="

# Remove old broken placeholders
find "$MEDIA_DIR" -maxdepth 1 -type f -size 0 -print -delete

# Reliable small/medium demo files
download "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4" \
"Big_Buck_Bunny_320x180.mp4"

download "https://download.blender.org/demo/movies/BBB/bbb_sunflower_1080p_30fps_normal.mp4" \
"Big_Buck_Bunny_1080p.mp4"

download "https://media.xiph.org/tearsofsteel/tears_of_steel_720p.webm" \
"Tears_of_Steel_720p.webm"

# Small public-domain WebM samples from Xiph derf collection
download "https://media.xiph.org/video/derf/y4m/FourPeople_1280x720_60.webm" \
"Four_People_720p.webm"

download "https://media.xiph.org/video/derf/y4m/Johnny_1280x720_60.webm" \
"Johnny_720p.webm"

download "https://media.xiph.org/video/derf/y4m/KristenAndSara_1280x720_60.webm" \
"Kristen_And_Sara_720p.webm"

echo ""
echo "=================================================="
echo " MEDIA SUMMARY"
echo "=================================================="
find "$MEDIA_DIR" -maxdepth 1 -type f -size +0c -printf "%f — %s bytes\n"

echo ""
echo "Restarting Jellyfin..."
docker restart "$JELLYFIN_CONTAINER"

echo ""
echo "COMPLETE"
echo "Next: Jellyfin Dashboard → Libraries → Scan All Libraries"
