#!/usr/bin/sh

set -e

DATE_COVER=$(date "+%d %B %Y")

SOURCE_FORMAT="markdown_strict\
+pipe_tables\
+backtick_code_blocks\
+auto_identifiers\
+strikeout\
+yaml_metadata_block\
+implicit_figures\
+all_symbols_escapable\
+link_attributes\
+smart\
+fenced_divs"

DATA_DIR="pandoc"
PDF_ENGINE="lualatex"

case "$1" in
"-preamble")
	OUTPUT=presentation_nice_formatting.pdf
	pandoc -s --dpi=300 --slide-level 2 --toc --listings --shift-heading-level=0 --data-dir="${DATA_DIR}" --template default_mod.latex -H pandoc/templates/preamble.tex --pdf-engine "${PDF_ENGINE}" -f "$SOURCE_FORMAT" -M date="$DATE_COVER" -V classoption:aspectratio=169 -t beamer presentation.md -o $OUTPUT
	;;
*)
	OUTPUT=presentation.pdf
	pandoc -s --dpi=300 --slide-level 2 --toc --listings --shift-heading-level=0 --data-dir="${DATA_DIR}" --template default_mod.latex --pdf-engine "${PDF_ENGINE}" -f "$SOURCE_FORMAT" -M date="$DATE_COVER" -V classoption:aspectratio=169 -t beamer presentation.md -o $OUTPUT
	;;
esac

echo Successfully generated slides in $OUTPUT
