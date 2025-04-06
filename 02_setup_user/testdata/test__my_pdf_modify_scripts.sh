#!/bin/bash

../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_10a_testdata_text_80x150.pdf                    input/testdata_text_80x150.pdf 
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_11a_testdata_text_80x150_rotate_180.pdf  -r 180 input/testdata_text_80x150_rotate_180.pdf
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_12a_testdata_text_80x150_rotate_ccw.pdf  -r cw  input/testdata_text_80x150_rotate_ccw.pdf
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_13a_testdata_text_80x150_rotate_cw.pdf   -r ccw input/testdata_text_80x150_rotate_cw.pdf 

../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_20a_testdata_image_80x150.pdf                   input/testdata_image_80x150.pdf 
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_21a_testdata_image_80x150_rotate_180.pdf -r 180 input/testdata_image_80x150_rotate_180.pdf
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_22a_testdata_image_80x150_rotate_ccw.pdf -r cw  input/testdata_image_80x150_rotate_ccw.pdf
../HOME/bin/my_pdf_rotate_resizeDINA4_cat.sh -o output/A25_23a_testdata_image_80x150_rotate_cw.pdf  -r ccw input/testdata_image_80x150_rotate_cw.pdf 


../HOME/bin/my_pdf_shrinksize_label_cat.sh 30 grayscale output/testdata_merged.pdf output/A25_*.pdf

../HOME/bin/my_pdf_add_page_numbers.sh output/testdata_merged.pdf output/testdata_merged_numbered.pdf 

