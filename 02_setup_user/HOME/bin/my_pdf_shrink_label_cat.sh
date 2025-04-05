#!/bin/bash

# Ensure temporary directory is cleaned up on exit (failure or interrupt)
trap 'rm -rf "$TMP_DIR"' EXIT

# Check if at least four command-line arguments are provided (3 fixed + at least 1 PDF)
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <resolution in DPI> <mode: grayscale|bw> <output_file> <pdf1> [pdf2 ...]"
    echo "Example: $0 150 grayscale merged.pdf file1.pdf file2.pdf file3.pdf"
    exit 1
fi

# Check if the first argument is a number
if ! [[ $1 =~ ^[0-9]+$ ]]; then
    echo "Error: The first argument must be a number."
    exit 1
fi

# Check if the second argument is either 'grayscale' or 'bw'
if [[ "$2" != "grayscale" && "$2" != "bw" ]]; then
    echo "Error: The second argument must be either 'grayscale' or 'bw'."
    exit 1
fi

# Assign command-line arguments to variables
RESOLUTION=$1
MODE=$2
OUTPUT_FILE=$3
shift 3  # Shift past the first three arguments
PDF_FILES=("$@")  # Remaining arguments are the PDFs to process

PROCESSED_DIR="processed_pdfs"
TMP_DIR=$(mktemp -d)
SIZE_DATA_FILE="$TMP_DIR/size_data.txt"  # Temporary file for size data
touch "$SIZE_DATA_FILE"  # Create the file upfront
LEFT_MARGIN=20
RIGHT_MARGIN=20
TEXT_Y=816
RECT_Y=812
FONT_SIZE=11
RECT_HEIGHT=$(awk "BEGIN {print $FONT_SIZE * 1.5}")  # Rectangle height is 1.5 * font size
TEXT_X_OFFSET=2
FILL_COLOR="1 1 1"  # White
TEXT_COLOR="1 0 0"  # Red

# Check for dependencies, including GNU parallel and Ghostscript
check_dependencies() {
    local deps=(pdftk convert pdfinfo gs pdftotext enscript parallel awk)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Error: $dep is not installed. Please install it first."
            echo "For parallel, install GNU parallel with 'sudo apt-get install parallel'."
            echo "For gs (Ghostscript), install with 'sudo apt-get install ghostscript'."
            exit 1
        fi
    done
    if ! parallel --version | grep -q "GNU parallel"; then
        echo "Error: This script requires GNU parallel. Install it with 'sudo apt-get install parallel'."
        exit 1
    fi
}

# Check if there are any PDFs specified
if [ ${#PDF_FILES[@]} -eq 0 ]; then
    echo "Error: No PDF files specified."
    exit 1
fi

# Validate that all specified files exist and are PDFs
for pdf in "${PDF_FILES[@]}"; do
    if [ ! -f "$pdf" ] || [[ "$pdf" != *.pdf ]]; then
        echo "Error: '$pdf' is not a valid PDF file or does not exist."
        exit 1
    fi
done

# Handle stat command differences across systems
if [[ "$OSTYPE" == "darwin"* ]]; then
    stat_size() { stat -f %z "$1"; }
else
    stat_size() { stat -c%s "$1"; }
fi

# Function to check and convert PDF to DIN A4
convert_to_din_a4() {
    local input_pdf="$1"
    local output_pdf="$2"
    local size_info=$(pdfinfo "$input_pdf" | grep "Page size:")
    local width=$(echo "$size_info" | awk '{print $3}')
    local height=$(echo "$size_info" | awk '{print $5}')
    
    # DIN A4 is 595 x 842 points
    if [ "$(echo "$width == 595 && $height == 842" | bc)" -eq 1 ]; then
        echo "PDF $input_pdf is already DIN A4, no conversion needed."
        cp "$input_pdf" "$output_pdf" || { echo "Error: cp failed for $input_pdf"; return 1; }
    else
        echo "Converting $input_pdf to DIN A4 (595x842 points)..."
        gs -sDEVICE=pdfwrite -sPAPERSIZE=a4 -dFIXEDMEDIA -dPDFFitPage \
            -o "$output_pdf" "$input_pdf" || {
            echo "Error: Ghostscript failed to convert $input_pdf to DIN A4"
            return 1
        }
    fi
}

# Function to process (convert) a single PDF
process_pdf() {
    local pdf="$1"
    local base_pdf=$(basename "$pdf")
    local processed_pdf="$PROCESSED_DIR/$base_pdf"
    local a4_pdf="$TMP_DIR/a4_${base_pdf}"
    local compressed_pdf="$TMP_DIR/compressed_${base_pdf}"
    local original_size=$(stat_size "$pdf")
    
    # Convert to DIN A4 first
    convert_to_din_a4 "$pdf" "$a4_pdf" || return 1
    local a4_size=$(stat_size "$a4_pdf")
    
    echo "Processing: $pdf -> $processed_pdf (via DIN A4)"
    if pdfinfo "$a4_pdf" | grep -q "Pages" && pdftotext "$a4_pdf" - | grep -q '[[:alnum:]]'; then
        echo "Keeping DIN A4 text-based PDF: $pdf"
        cp "$a4_pdf" "$processed_pdf" || { echo "Error: cp failed for $a4_pdf to $processed_pdf"; return 1; }
        echo "Processed file created: $processed_pdf"
        echo "$base_pdf $original_size $a4_size" >> "$SIZE_DATA_FILE"
    else
        echo "Processing DIN A4 image-based PDF: $pdf"
        if [ "$MODE" == "bw" ]; then
            convert -density "$RESOLUTION" "$a4_pdf" -threshold 50% -quality 85 "$compressed_pdf" || {
                echo "Error: convert failed for $a4_pdf"
                return 1
            }
        else
            convert -density "$RESOLUTION" "$a4_pdf" -colorspace Gray -quality 85 "$compressed_pdf" || {
                echo "Error: convert failed for $a4_pdf"
                return 1
            }
        fi
        
        local compressed_size=$(stat_size "$compressed_pdf")
        echo "Using compressed DIN A4 version of $pdf (size: $compressed_size vs original: $original_size)"
        mv "$compressed_pdf" "$processed_pdf" || { echo "Error: mv failed for $compressed_pdf to $processed_pdf"; return 1; }
        echo "$base_pdf $original_size $compressed_size" >> "$SIZE_DATA_FILE"
        echo "Processed file created: $processed_pdf"
    fi
    chmod 644 "$processed_pdf"
}

# Function to annotate a single PDF
annotate_pdf() {
    local pdf="$1"
    local label_text="${pdf##*/}"
    label_text="${label_text:0:7}"
    local annotated_pdf="$TMP_DIR/annotated_${pdf##*/}"
    local text_overlay="$TMP_DIR/overlay_${pdf##*/}"
    local temp_ps="$TMP_DIR/temp_${pdf##*/}.ps"
    
    echo "Annotating: $pdf"
    cat << EOF > "$temp_ps"
%!PS-Adobe-3.0
/Helvetica-Bold findfont
$FONT_SIZE scalefont
setfont

    % Top-left corner: Rectangle at ($LEFT_MARGIN, $RECT_Y)
    gsave
    $FILL_COLOR setrgbcolor           % White fill
    $LEFT_MARGIN $RECT_Y              % Bottom-left corner
    ($label_text) stringwidth pop 4 add  % Width: text width + 4 points padding
    $RECT_HEIGHT                      % Height: 1.5 * font size
    rectfill                          % Fill rectangle with white
    $TEXT_COLOR setrgbcolor           % Red for border and text
    $LEFT_MARGIN $RECT_Y              % Same coordinates as fill
    ($label_text) stringwidth pop 4 add
    $RECT_HEIGHT                      % Height: 1.5 * font size
    rectstroke                        % Stroke red rectangle outline
    $((LEFT_MARGIN + TEXT_X_OFFSET)) $TEXT_Y moveto  % Text position (top-left)
    ($label_text) show
    grestore

    % Top-right corner: Rectangle 
    gsave
    $FILL_COLOR setrgbcolor           % White fill
    595 $RIGHT_MARGIN sub $TEXT_X_OFFSET sub ($label_text) stringwidth pop sub $RECT_Y  % Bottom-left corner
    ($label_text) stringwidth pop 4 add  % Width: text width + 4 points padding
    $RECT_HEIGHT                      % Height: 1.5 * font size
    rectfill                          % Fill rectangle with white
    $TEXT_COLOR setrgbcolor           % Red for border and text
    595 $RIGHT_MARGIN sub $TEXT_X_OFFSET sub ($label_text) stringwidth pop sub $RECT_Y  % Same coordinates
    ($label_text) stringwidth pop 4 add
    $RECT_HEIGHT                      % Height: 1.5 * font size
    rectstroke                        % Stroke red rectangle outline
    595 $RIGHT_MARGIN sub ($label_text) stringwidth pop sub $TEXT_Y moveto  % Text position (top-right)
    ($label_text) show
    grestore

showpage
EOF
    
    ps2pdf -sPAPERSIZE=a4 "$temp_ps" "$text_overlay" || {
        echo "Error: ps2pdf failed for $pdf"
        return 1
    }
    rm -f "$temp_ps"
    
    pdftk "$pdf" multistamp "$text_overlay" output "$annotated_pdf" || {
        echo "Error: pdftk multistamp failed for $pdf"
        return 1
    }
    mv -f "$annotated_pdf" "$pdf" || { echo "Error: mv failed for $pdf"; return 1; }
    echo "Annotated file updated: $pdf"
}

check_dependencies

# Remove old output directories and files
rm -rf "$PROCESSED_DIR" && mkdir -p "$PROCESSED_DIR"
[ -f "$OUTPUT_FILE" ] && { echo "Removing old merged PDF: $OUTPUT_FILE"; rm -f "$OUTPUT_FILE"; }

# Initialize an associative array to track file sizes
declare -A file_sizes

# Export variables and functions for parallel
export PROCESSED_DIR TMP_DIR RESOLUTION MODE SIZE_DATA_FILE
export LEFT_MARGIN RIGHT_MARGIN TEXT_Y RECT_Y FONT_SIZE RECT_HEIGHT TEXT_X_OFFSET FILL_COLOR TEXT_COLOR
export -f process_pdf annotate_pdf stat_size convert_to_din_a4

# Parallelize the convert loop with specified PDFs
echo "Starting parallel PDF processing..."
parallel -j "$(nproc)" process_pdf ::: "${PDF_FILES[@]}"

# Load size data from the temporary file into file_sizes
while read -r pdf_name orig_size final_size; do
    file_sizes["$pdf_name"]="$orig_size $final_size"
done < "$SIZE_DATA_FILE"

# Build the processed_pdfs array with correct paths
processed_pdfs=()
for pdf in "${PDF_FILES[@]}"; do
    processed_pdf="$PROCESSED_DIR/$(basename "$pdf")"
    if [ -f "$processed_pdf" ]; then
        processed_pdfs+=("$processed_pdf")
    else
        echo "Warning: Processed file $processed_pdf not found, skipping."
    fi
done

# Debug: List processed PDFs
echo "Processed PDFs to annotate: ${processed_pdfs[*]}"

# Parallelize the annotation loop with processed PDFs
if [ ${#processed_pdfs[@]} -gt 0 ]; then
    echo "Starting parallel PDF annotation..."
    parallel -j "$(nproc)" annotate_pdf ::: "${processed_pdfs[@]}"
else
    echo "Error: No processed PDFs available for annotation."
    exit 1
fi

# Ensure there are valid PDFs to merge
if [ ${#processed_pdfs[@]} -eq 0 ] || [ -z "$(ls -A "$PROCESSED_DIR")" ]; then
    echo "Error: No valid PDFs to merge."
    exit 1
fi

# Merge processed PDFs
echo "Merging PDFs: ${processed_pdfs[*]}"
pdftk "${processed_pdfs[@]}" cat output "$OUTPUT_FILE" || {
    echo "Error: Failed to merge PDFs."
    exit 1
}

echo "Final merged PDF saved as $OUTPUT_FILE"

# List all files with their sizes
echo "File sizes [kb] (original -> used):"
for pdf in "${PDF_FILES[@]}"; do
    base_pdf=$(basename "$pdf")
    if [ -n "${file_sizes[$base_pdf]}" ]; then
        original_size=$(printf "%d" $(( ${file_sizes[$base_pdf]%% *} / 1024 )))
        final_size=$(printf "%d" $(( ${file_sizes[$base_pdf]##* } / 1024 )))
        if [ "$original_size" -gt "$final_size" ]; then
            prefix="C"
        else
            prefix="-"
        fi
        echo "$prefix $(printf "%5d" "$original_size") -> $(printf "%5d" "$final_size") : $pdf"
    else
        echo "Warning: Size data missing for $pdf"
    fi
done

# Print summary statistics
total_size=$(stat_size "$OUTPUT_FILE")
total_input_size=0
for pdf in "${PDF_FILES[@]}"; do
    base_pdf=$(basename "$pdf")
    if [ -n "${file_sizes[$base_pdf]}" ]; then
        total_input_size=$((total_input_size + ${file_sizes[$base_pdf]%% *}))
    fi
done
total_pages=$(pdfinfo "$OUTPUT_FILE" | grep "Pages:" | awk '{print $2}')
echo "Merged PDF is saved as $OUTPUT_FILE"
echo "Total size of all input PDFs: $(printf "%'8d" $((total_input_size / 1024))) kB"
echo "Total size of merged PDF:     $(printf "%'8d" $((total_size / 1024))) kB"
echo "Total number of pages in merged PDF: $total_pages"

# Clean up processed_pdfs folder after successful execution
echo "Cleaning up: Removing $PROCESSED_DIR"
rm -rf "$PROCESSED_DIR"