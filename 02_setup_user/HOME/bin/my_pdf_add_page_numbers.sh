#!/bin/bash
# Check if both input and output files are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 input.pdf output.pdf"
    exit 1
fi

INPUT_PDF="$1"
OUTPUT_PDF="$2"
TEMP_PS="temp_numbers.ps"
TEMP_PDF="temp_numbers.pdf"
export FONT_SIZE=11
export TEXT_X_OFFSET=4   # Horizontal offset to the right inside rectangle (in points)
export TEXT_Y_OFFSET=4   # Vertical offset upward inside rectangle (in points)
export RECT_HEIGHT=$(awk "BEGIN {print $FONT_SIZE * 1.5}")  # Rectangle height is 1.5 * font size

# Get the number of pages
NUM_PAGES=$(pdftk "$INPUT_PDF" dump_data | grep "NumberOfPages" | cut -d":" -f2 | tr -d ' ')

# Define margins (in points, 1 inch = 72 points)
LEFT_MARGIN=20   # 0.5 inch from left edge
BOTTOM_MARGIN=17 # 0.5 inch from bottom edge

# Create a PostScript file with red, bold page numbers and a red rectangle with white background
cat << EOF > "$TEMP_PS"
/Helvetica-Bold findfont $FONT_SIZE scalefont setfont
EOF

for i in $(seq 1 "$NUM_PAGES"); do
    echo "%%Page: $i $i" >> "$TEMP_PS"
    echo "gsave" >> "$TEMP_PS"
    # Define text
    echo "/text ($i / $NUM_PAGES) def" >> "$TEMP_PS"
    # Estimate text width and height
    echo "text stringwidth pop 10 add /width exch def" >> "$TEMP_PS"  # Width + padding
    echo "/height $RECT_HEIGHT def" >> "$TEMP_PS"                    # Use RECT_HEIGHT
    # Draw white filled rectangle at fixed position
    echo "1 1 1 setrgbcolor" >> "$TEMP_PS"                          # White background
    echo "$LEFT_MARGIN $BOTTOM_MARGIN width height rectfill" >> "$TEMP_PS"
    # Draw red rectangle border at fixed position
    echo "1 0 0 setrgbcolor" >> "$TEMP_PS"                          # Red color
    echo "1.0 setlinewidth" >> "$TEMP_PS"                           # Line thickness
    echo "$LEFT_MARGIN $BOTTOM_MARGIN width height rectstroke" >> "$TEMP_PS"
    # Draw red text with offsets relative to rectangle
    echo "1 0 0 setrgbcolor" >> "$TEMP_PS"                          # Red text
    echo "$LEFT_MARGIN $TEXT_X_OFFSET add $BOTTOM_MARGIN $TEXT_Y_OFFSET add moveto text show" >> "$TEMP_PS"
    echo "grestore" >> "$TEMP_PS"
    echo "showpage" >> "$TEMP_PS"
done

# Convert PostScript to PDF
ps2pdf "$TEMP_PS" "$TEMP_PDF"

# Stamp the page numbers onto the original PDF
pdftk "$INPUT_PDF" multistamp "$TEMP_PDF" output "$OUTPUT_PDF"

# Clean up temporary files
rm "$TEMP_PS" "$TEMP_PDF"