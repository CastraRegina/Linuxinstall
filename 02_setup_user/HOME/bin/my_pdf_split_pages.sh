#!/bin/bash

# Filename: split_pdf_pages.sh
# Description: Splits a PDF into individual pages using pdftk. The output folder must be specified as a parameter.
# Existing files are not overwritten.

# Check if pdftk is installed
if ! command -v pdftk &>/dev/null; then
    echo "Error: pdftk is not installed. Install it using 'sudo apt install pdftk'."
    exit 1
fi

# Check for proper arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <pdf-file> <output-directory>"
    exit 1
fi

# Input PDF file
input_pdf="$1"

# Output directory
output_dir="$2"

# Verify the input file exists
if [ ! -f "$input_pdf" ]; then
    echo "Error: File '$input_pdf' does not exist."
    exit 1
fi

# Create the output directory if it does not exist
if [ ! -d "$output_dir" ]; then
    echo "Output directory '$output_dir' does not exist. Creating it..."
    mkdir -p "$output_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Could not create output directory '$output_dir'."
        exit 1
    fi
fi

# Get the base name of the input file without extension
base_name=$(basename "$input_pdf" .pdf)

# Split the PDF into individual pages
echo "Splitting '$input_pdf' into individual pages..."
page_number=1
while true; do
    # Generate the output file name, avoiding overwriting existing files
    output_file="${output_dir}/${base_name}_page_$(printf '%02d' "$page_number").pdf"
    while [ -f "$output_file" ]; do
        echo "File '$output_file' already exists. Incrementing page number to avoid overwriting..."
        page_number=$((page_number + 1))
        output_file="${output_dir}/${base_name}_page_$(printf '%02d' "$page_number").pdf"
    done

    # Extract the next page
    pdftk "$input_pdf" cat "$page_number" output "$output_file" 2>/dev/null
    if [ $? -ne 0 ]; then
        # Stop when there are no more pages
        break
    fi

    echo "Page $page_number saved as '$output_file'."
    page_number=$((page_number + 1))
done

echo "PDF split successfully! Pages saved in '$output_dir/'."

