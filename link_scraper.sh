#!/bin/bash

# Link Scraper & Bookmarker
# Usage: bash link_scraper.sh [--csv] [--bookmarks] [--group] [--dead-links] [--all]

# --- Configuration ---
INPUT_FILE="html_links.txt"
CSV_OUTPUT="titles_by_source.csv"
BOOKMARK_OUTPUT="bookmarks.html"
DEAD_LINKS_FILE="dead_links.txt"

# --- Parse Flags ---
DO_CSV=false
DO_BOOKMARKS=false
DO_GROUP=false
DO_DEADLINKS=false

if [[ $# -eq 0 || "$1" == "--all" ]]; then
    DO_CSV=true
    DO_BOOKMARKS=true
    DO_GROUP=true
    DO_DEADLINKS=true
else
    for arg in "$@"; do
        case $arg in
            --csv) DO_CSV=true ;;
            --bookmarks) DO_BOOKMARKS=true ;;
            --group) DO_GROUP=true ;;
            --dead-links) DO_DEADLINKS=true ;;
            *) echo "Unknown flag: $arg"; exit 1 ;;
        esac
    done
fi

# --- Step 0: Extract HTML links from JSON files ---
echo "🔍 Extracting links from JSON files..."
> "$INPUT_FILE"
find . -name "*.json" | while read -r file; do
    grep -oE 'https?://[^"]+\.html' "$file" | while read -r url; do
        echo "$file:$url" >> "$INPUT_FILE"
    done
done

# --- Step 1: Process links ---
echo "🚀 Processing links..."
> "$CSV_OUTPUT"
> "$BOOKMARK_OUTPUT"
> "$DEAD_LINKS_FILE"

total=$(wc -l < "$INPUT_FILE")
count=0

declare -A GROUPED

while IFS=: read -r source url; do
    ((count++))
    progress=$((count * 100 / total))
    printf "\rProgress: [%-50s] %d%%" $(head -c $((progress / 2)) < /dev/zero | tr '\0' '#') "$progress"

    # Follow redirects and fetch page title
    final_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$url")
    html=$(curl -Ls "$final_url")
    title=$(echo "$html" | grep -oP '(?<=<title>).*?(?=</title>)' | head -n 1)

    # Error handling
    if [[ -z "$title" ]]; then
        echo "$url" >> "$DEAD_LINKS_FILE"
        continue
    fi

    # Store in associative array for grouped output
    if $DO_GROUP; then
        key=$(basename "$source")
        GROUPED["$key"]+="$title,$final_url"$'\n'
    fi

    # CSV Output
    if $DO_CSV && ! $DO_GROUP; then
        echo "\"$source\",\"$title\",\"$final_url\"" >> "$CSV_OUTPUT"
    fi

done < "$INPUT_FILE"

# --- Step 2: Export Grouped CSV ---
if $DO_GROUP && $DO_CSV; then
    for key in "${!GROUPED[@]}"; do
        while IFS= read -r line; do
            title=$(echo "$line" | cut -d',' -f1)
            link=$(echo "$line" | cut -d',' -f2-)
            echo "\"$key\",\"$title\",\"$link\"" >> "$CSV_OUTPUT"
        done <<< "${GROUPED[$key]}"
    done
fi

# --- Step 3: Generate Bookmarks ---
if $DO_BOOKMARKS; then
    echo '<!DOCTYPE NETSCAPE-Bookmark-file-1>' > "$BOOKMARK_OUTPUT"
    echo '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">' >> "$BOOKMARK_OUTPUT"
    echo '<TITLE>Bookmarks</TITLE>' >> "$BOOKMARK_OUTPUT"
    echo '<H1>Bookmarks</H1>' >> "$BOOKMARK_OUTPUT"
    echo '<DL><p>' >> "$BOOKMARK_OUTPUT"

    if $DO_GROUP; then
        for key in "${!GROUPED[@]}"; do
            echo "  <DT><H3>$key</H3>" >> "$BOOKMARK_OUTPUT"
            echo "  <DL><p>" >> "$BOOKMARK_OUTPUT"
            while IFS= read -r line; do
                title=$(echo "$line" | cut -d',' -f1)
                link=$(echo "$line" | cut -d',' -f2-)
                echo "    <DT><A HREF=\"$link\">$title</A>" >> "$BOOKMARK_OUTPUT"
            done <<< "${GROUPED[$key]}"
            echo "  </DL><p>" >> "$BOOKMARK_OUTPUT"
        done
    else
        while IFS=: read -r source url; do
            final_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$url")
            html=$(curl -Ls "$final_url")
            title=$(echo "$html" | grep -oP '(?<=<title>).*?(?=</title>)' | head -n 1)
            [[ -z "$title" ]] && continue
            echo "  <DT><A HREF=\"$final_url\">$title</A>" >> "$BOOKMARK_OUTPUT"
        done < "$INPUT_FILE"
    fi

    echo '</DL><p>' >> "$BOOKMARK_OUTPUT"
fi

# --- Final Output ---
echo -e "\n✅ Done!"
[[ -s "$CSV_OUTPUT" ]] && echo "📝 CSV saved to $CSV_OUTPUT"
[[ -s "$BOOKMARK_OUTPUT" ]] && echo "🔖 Bookmarks saved to $BOOKMARK_OUTPUT"
[[ -s "$DEAD_LINKS_FILE" ]] && echo "❌ Dead links saved to $DEAD_LINKS_FILE"
