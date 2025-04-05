#!/bin/bash

usage() {
    echo "Usage: $0 -o outputfile [-r rotation] [inputfile1 [inputfile2 ...]]"
    echo "  -r rotation: Specify cw (clockwise) or ccw (counter-clockwise) or 180 (upside down) rotation."
    echo "  example: bash $0 -r cw -o combined_output.pdf $(ls -r *.pdf)"
    exit 1
}

while getopts "o:r:" opt; do
    case "$opt" in
        o) outputfile="$OPTARG" ;;
        r) rotation="$OPTARG" ;;
        *) usage ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$outputfile" ]; then
    usage
fi

inputfiles=("$@")

if [ ${#inputfiles[@]} -eq 0 ]; then
    echo "Error: No input files specified."
    exit 1
fi

# Remove existing temporary directory if it exists
rm -rf temp_rotated
mkdir -p temp_rotated

# Remove existing output file if it exists
if [ -f "$outputfile" ]; then
    rm -f "$outputfile"
fi

declare -a processed_files

# Rotate all PDF files according to the specified rotation and save to temp directory
for file in "${inputfiles[@]}"; do
    if [ -f "$file" ]; then
        rotated_file="temp_rotated/rotated_$(basename "$file")"
        if [ -z "$rotation" ]; then
            cp "$file" "$rotated_file"
        else
            case "$rotation" in
                cw)
                    pdftk "$file" cat 1-endright output "$rotated_file"
                    ;;
                ccw)
                    pdftk "$file" cat 1-endleft output "$rotated_file"
                    ;;
                180)
                    pdftk "$file" cat 1-enddown output "$rotated_file"
                    ;;
                *)
                    echo "Error: Invalid rotation option. Use cw, ccw, or 180."
                    exit 1
                    ;;
            esac
        fi
        processed_files+=("$rotated_file")
    fi
done

final_files=()

# Center the content of the rotated PDFs on A4 page
for file in "${processed_files[@]}"; do
    centered_file="temp_rotated/centered_$(basename "$file")"
    pdfjam "$file" --outfile "$centered_file" --paper a4paper --scale 1.0 --noautoscale true
    final_files+=("$centered_file")
done

# Concatenate all centered PDFs into one file while maintaining order
pdftk "${final_files[@]}" cat output "$outputfile"

# Clean up temporary directory
chmod -R u+w temp_rotated
rm -rf temp_rotated

echo "PDFs have been rotated and combined into $outputfile"
