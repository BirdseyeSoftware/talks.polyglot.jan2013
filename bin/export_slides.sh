#!/bin/bash

emacs -batch -Q -l ringmaster.el -f ringmaster-prepare-slides 
mv slides.html build/slides.html.tmp
BODY_LN=`grep -n '/body>' build/slides.html.tmp | cut -f1 -d':'`
head -n$(($BODY_LN-1)) build/slides.html.tmp > build/slides.html
cat assets/slides_js_tags >> build/slides.html
sed -i -e's/<body>/<body style="display: none">/' build/slides.html
