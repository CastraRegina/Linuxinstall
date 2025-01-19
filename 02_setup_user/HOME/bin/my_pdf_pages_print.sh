#!/bin/bash

# Filename: print_pdfs.sh
# Description: Sends each PDF in a folder to a printer, one at a time, ensuring no scaling, shrinking, or rotation.

# Check if the lp command is installed
if ! command -v lp &>/dev/null; then
    echo "Error: lp command is not installed. Install it with 'sudo apt install cups'."
    exit 1
fi

# Check for proper arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <printer-name>"
    echo "Printers:"
    lpstat -a
    exit 1
fi

# Input directory containing PDF files
pdf_dir="$1"

# Printer name
printer_name="$2"

# Verify the input directory exists
if [ ! -d "$pdf_dir" ]; then
    echo "Error: Directory '$pdf_dir' does not exist."
    exit 1
fi

# Get a sorted list of PDF files in the directory
pdf_files=("$pdf_dir"/*.pdf)

# Check if there are PDF files in the directory
if [ "${#pdf_files[@]}" -eq 0 ]; then
    echo "No PDF files found in directory '$pdf_dir'."
    exit 0
fi

# Process each PDF file
for pdf_file in "${pdf_files[@]}"; do
    echo "Sending '$pdf_file' to printer '$printer_name'..."

    # Send the PDF to the printer with options to disable scaling and rotation
    # lp -d "$printer_name" -o fit-to-page=false -o media=Custom -o scaling=100 -o page-left=0 -o page-right=0 "$pdf_file"
    # lp -d "$printer_name" -o fit-to-page=false -o scaling=100 -o media=A4 -o page-top=0 -o page-bottom=0 -o page-left=0 -o page-right=0 "$pdf_file"
    lp -d "$printer_name" -o fit-to-page=false -o scaling=100 -o media=A4 -o page-top=0 -o page-bottom=0 -o page-left=0 -o page-right=0 -o print-quality=5 -o resolution=600dpi -o toner-save-mode=off "$pdf_file"

    if [ $? -eq 0 ]; then
        echo "Successfully sent '$pdf_file' to the printer."
    else
        echo "Failed to send '$pdf_file' to the printer."
        exit 1
    fi

    # Wait for the printer to finish the job
    while true; do
        # Get printer status
        printer_status=$(lpstat -p "$printer_name" 2>/dev/null)

        if [[ $printer_status == *"ist im Leerlauf"* ]]; then
            echo "Printer is idle. Proceeding to the next file..."
            break
        fi

        echo "Waiting for printer to finish the current job..."
        sleep 15
    done

    # Wait an additional 5 seconds before sending the next job
    echo "Waiting 5 seconds before printing the next file..."
    sleep 5
done

echo "All PDF files have been sent to the printer."

