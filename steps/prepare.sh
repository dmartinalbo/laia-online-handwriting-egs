#!/bin/bash
set -e;

# Directory where the prepare.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)/steps" != "$SDIR" ] && \
  echo "Please, run this script from the experiment top directory!" && \
  exit 1;
[ ! -f "$(pwd)/utils/parse_options.inc.sh" ] && \
  echo "Missing $(pwd)/utils/parse_options.inc.sh file!" >&2 && exit 1;

overwrite=false;
height=64;
help_message="
Usage: ${0##*/} [options]

Options:
  --height     : (type = integer, default = $height)
         Scale lines to have this height, keeping the aspect ratio
         of the original image.
  --overwrite  : (type = boolean, default = $overwrite)
         Overwrite previously created files.
";
source "$(pwd)/utils/parse_options.inc.sh" || exit 1;

[ -d data/corpus/csvs -a -s data/corpus/train.lst \
  -a -s data/corpus/test.lst -a -s data/corpus/ref.txt ] || \
  ( echo "The database is not available!">&2 && exit 1; );

mkdir -p data/lang/chars;

echo -n "Creating transcripts..." >&2;
# Place all character-level transcripts into a single txt table file.
while read line
do
  ident=$(echo "$line" | awk '{print $1}');
  transcript=$(echo "$line" | awk '{print $2}' | sed 's/./& /g');
  echo "$ident $transcript";
done < data/corpus/ref.txt > data/lang/chars/ref.txt;
echo -e "  \tDone." >&2;

echo -n "Creating symbols table..." >&2;
# Generate symbols table from training and validation characters.
# This table will be used to convert characters to integers using Kaldi format.
[ -s data/lang/chars/symbs.txt -a $overwrite = false ] || (
  cut -f 2- -d\  data/lang/chars/ref.txt | tr \  \\n | sort -u -V | \
    awk 'BEGIN{N=1;}NF==1{ printf("%-10s %d\n", $1, N); N++; }' \
  > data/lang/chars/symbs.txt;
)
echo -e "  \tDone." >&2;

## Resize to a fixed height and convert to png.
echo -n "Preprocessing images..." >&2;
mkdir -p data/imgs_proc;
for p in train test; do
  for f in $(< data/corpus/$p.lst); do
    [ -f data/imgs_proc/$f.png -a $overwrite = false ] && continue;
    [ ! -f data/corpus/csvs/$f.csv ] && \
      echo "File data/corpus/csvs/$f.csv is not available!">&2 \
        && exit 1;
      th ./utils/csv2png.lua data/corpus/csvs/$f.csv data/imgs_proc/$f.png
      convert data/imgs_proc/$f.png -colorspace gray data/imgs_proc/$f.png
  done;
  awk '{ print "data/imgs_proc/"$1".png" }' data/corpus/$p.lst > data/$p.lst;
done;
echo -e "  \tDone." >&2;

exit 0;
