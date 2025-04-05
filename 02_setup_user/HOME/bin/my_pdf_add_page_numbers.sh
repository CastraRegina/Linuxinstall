#!/bin/bash
# Check if a file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 input.pdf"
  exit 1
fi

INPUT_PDF="$1"
OUTPUT_PDF="${INPUT_PDF%.pdf}_numbered.pdf"

# Get the number of pages
NUM_PAGES=$(pdftk "$INPUT_PDF" dump_data | grep "NumberOfPages" | cut -d":" -f2 | tr -d ' ')

# enscript -L1 -b "||Page \$% of \$=" -f "Helvetica@10" -r -o- --margins=15:15:15:15 --borders=0 --word-wrap --line-spacing=0.5 --header="" --footer="75% 15 0 0" < <(for i in $(seq 1 "$NUM_PAGES"); do echo; done) | \
# Generate page numbers with enscript and position them in the bottom right
enscript -L1 -b "||Page \$% of \$=" -f "Helvetica@10" -o- < <(for i in $(seq 1 "$NUM_PAGES"); do echo; done) | \
ps2pdf - | pdftk "$INPUT_PDF" multistamp - output "$OUTPUT_PDF"