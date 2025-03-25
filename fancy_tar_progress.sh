#!/bin/bash

# Color codes
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

# Defaults
GZIP_ENABLED=true
SLOW_MODE=false
OPEN_AFTER=false
OUTPUT_FILE="archive.tar.gz"

show_help() {
    echo -e "${BOLD}Usage:${RESET} $0 [options] file1 [file2 ...]"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  -o <filename>   Output file name (default: archive.tar.gz)"
    echo -e "  -n              No gzip (creates .tar instead of .tar.gz)"
    echo -e "  -s              Slow mode (simulate slower compression)"
    echo -e "  -x              Open folder when done"
    echo -e "  -h              Show help"
    echo
    exit 0
}

# Parse options
while getopts ":o:nsxh" opt; do
    case ${opt} in
        o) OUTPUT_FILE="$OPTARG" ;;
        n) GZIP_ENABLED=false ;;
        s) SLOW_MODE=true ;;
        x) OPEN_AFTER=true ;;
        h) show_help ;;
        \?) echo -e "${RED}Invalid option: -$OPTARG${RESET}" >&2; exit 1 ;;
        :) echo -e "${RED}Option -$OPTARG requires an argument.${RESET}" >&2; exit 1 ;;
    esac
done
shift $((OPTIND -1))

INPUT_FILES=("$@")

# Validate input
if [ "${#INPUT_FILES[@]}" -eq 0 ]; then
    echo -e "${RED}Error: No input files or folders provided.${RESET}"
    show_help
fi

# Check for pv
if ! command -v pv &> /dev/null; then
    echo -e "${RED}Error: 'pv' is not installed. Install it first.${RESET}"
    exit 1
fi

# Timer start
START_TIME=$(date +%s)

# Calculate size and file count
echo -e "${CYAN}Calculating total size and files...${RESET}"
TOTAL_SIZE=$(du -cb "${INPUT_FILES[@]}" 2>/dev/null | grep total | awk '{print $1}')
TOTAL_FILES=$(find "${INPUT_FILES[@]}" -type f | wc -l)

echo -e "${CYAN}Total size:${RESET} $((TOTAL_SIZE / 1024 / 1024)) MB"
echo -e "${CYAN}Total files:${RESET} $TOTAL_FILES"
echo -e "${CYAN}Output file:${RESET} $OUTPUT_FILE"
echo -e "${CYAN}Compression:${RESET} $([ "$GZIP_ENABLED" = true ] && echo "gzip (tar.gz)" || echo "no gzip (tar)")"
[ "$SLOW_MODE" = true ] && echo -e "${CYAN}Mode:${RESET} Slow simulation 🐢"
echo

# Create temporary tar file
TMP_TAR=$(mktemp)
CURRENT_FILE=0

# Begin adding files
echo -e "${CYAN}Archiving files...${RESET}"
for FILE in $(find "${INPUT_FILES[@]}" -type f); do
    ((CURRENT_FILE++))
    echo -e "${BOLD}[$CURRENT_FILE/$TOTAL_FILES]${RESET} Adding: $FILE"
    tar -rf "$TMP_TAR" "$FILE"
    [ "$SLOW_MODE" = true ] && sleep 0.1
done

# Compress and show progress bar
if [ "$GZIP_ENABLED" = true ]; then
    echo -e "${CYAN}Compressing archive...${RESET}"
    pv -s "$TOTAL_SIZE" "$TMP_TAR" | gzip > "$OUTPUT_FILE"
    rm "$TMP_TAR"
else
    echo -e "${CYAN}Finalizing archive...${RESET}"
    pv -s "$TOTAL_SIZE" "$TMP_TAR" > "$OUTPUT_FILE"
    rm "$TMP_TAR"
fi

# Timer end
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MIN=$((ELAPSED / 60))
SEC=$((ELAPSED % 60))

# Done message
echo -e "${GREEN}✅ Done! Archive created: ${BOLD}$OUTPUT_FILE${RESET}"
echo -e "${CYAN}Total time elapsed:${RESET} ${BOLD}${MIN}m ${SEC}s${RESET}"

# Notification
if command -v notify-send &> /dev/null; then
    notify-send "✅ Tar Completed" "Created: $OUTPUT_FILE (${MIN}m ${SEC}s)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"Created: $OUTPUT_FILE in ${MIN}m ${SEC}s\" with title \"✅ Tar Completed\""
fi

# Open folder if requested
if [ "$OPEN_AFTER" = true ]; then
    DIR=$(dirname "$OUTPUT_FILE")
    echo -e "${CYAN}Opening folder: $DIR${RESET}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$DIR"
    else
        xdg-open "$DIR"
    fi
fi

