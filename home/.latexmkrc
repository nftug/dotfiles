#!/usr/bin/env perl
$latex            = 'uplatex -shell-escape -synctex=1 -halt-on-error';
$latex_silent     = 'uplatex -shell-escape -synctex=1 -halt-on-error -interaction=batchmode';
$bibtex           = 'pbibtex';
$biber		  = '/usr/bin/vendor_perl/biber --bblencoding=utf8 -u -U --output_safechars';
$dvipdf           = 'dvipdfmx %O -o %D %S';
$makeindex        = 'mendex %O -o %D %S';
$max_repeat       = 5;
$pdf_mode     = 3; # generates pdf via dvipdfmx

# Prevent latexmk from removing PDF after typeset.
# This enables Skim to chase the update in PDF automatically.
$pvc_view_file_via_temporary = 0;

# Use Skim as a previewer
$pdf_previewer    = "xdg-open";
