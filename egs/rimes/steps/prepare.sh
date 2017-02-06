#!/bin/bash
set -e;
export LC_NUMERIC=C;

# Directory where this script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)/steps" != "$SDIR" ] &&
  echo "Please, run this script from the experiment top directory!" >&2 &&
  exit 1;
[ ! -f "$(pwd)/utils/parse_options.inc.sh" ] &&
  echo "Missing $(pwd)/utils/parse_options.inc.sh file!" >&2 && exit 1;

height=128;
overwrite=false;
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

# Check that all required files exist!
for f in data/a2ia/training_2011.patched.xml data/a2ia/eval_2011_annotated.xml; do
  [ ! -s "$f" ] && echo "ERROR: File \"$f\" does not exist!" >&2 && exit 1;
done;

# Check ImageMagick
which convert &> /dev/null ||
( echo "ERROR: ImageMagick's convert is required, please install it!" >&2 && exit 1 );

# Check Mauricio's imgtxtenh
which imgtxtenh &> /dev/null ||
( echo "ERROR: imgtxtenh tool is required, please install it from https://github.com/mauvilsa/imgtxtenh" >&2 && exit 1 );

# Extract info from the XML files.
mapfile -t xmldata < <(
  for f in data/a2ia/training_2011.patched.xml data/a2ia/eval_2011_annotated.xml; do
    python -c "
import re
import sys
from xml.sax import parse
from xml.sax.handler import ContentHandler
from os.path import basename

class RIMESHandler(ContentHandler):
  def startElement(self, name, attrs):
    if name == 'SinglePage':
      self.filename = attrs['FileName']
      self.linenum  = 0
    elif name == 'Line':
      print basename(self.filename.encode('utf-8')), self.linenum, \
        attrs['Left'], attrs['Top'], attrs['Right'], attrs['Bottom'], \
        attrs['Value'].encode('utf-8')
      self.linenum += 1

h = RIMESHandler()
parse(sys.stdin, h)
" < "$f";
  done;
);

# Create folders.
mkdir -p data/imgproc "data/imgproc_h$height" data/lang/{char,word} data/lists;
mkdir -p train;

# Extract line images and line transcripts.
log="$(mktemp)";
[[ "$overwrite" = false && -s data/lang/word/all.txt &&
    -s "data/imgproc/eval2011-0-0.jpg" &&
    -s "data/imgproc_h$height/eval2011-0-0.jpg" ]] ||
for d in "${xmldata[@]}"; do
  d=($d);
  bn="${d[0]}"; bn="${bn/.png/}";
  n="${d[1]}";
  l="${d[2]}";
  t="${d[3]}";
  r="${d[4]}";
  b="${d[5]}";
  v="${d[@]:6}";
  w=$[r - l + 1];
  h=$[b - t + 1];
  i="data/a2ia/images_gray/$bn.png";
  o="data/imgproc/$bn-$n.jpg";
  # Extract image lines.
  [[ "$overwrite" = false && -s "$o" ]] ||
  convert "$i" -crop "${w}x${h}+${l}+${t}" +repage png:- |
  imgtxtenh -u mm -d 118.1102362205 - "$o";
  # Resize image to have an height of $height pixels, keeping aspect ratio.
  oh="data/imgproc_h$height/$bn-$n.jpg";
  [[ "$overwrite" = false && -s "$oh" ]] ||
  convert "$o" -resize "x$height" +repage "$oh";
  echo "$bn-$n" "${v[@]}";
done 2> "$log" |
sed -r 's|¤||g' |  # This symbol does not actually exist in the images
sort -V > "data/lang/word/all.txt" ||
(echo "ERROR: Processing images failed, see \"$log\"!" >&2 && exit 1);

# Get character-level transcription from the lines
[[ "$overwrite" = false && -s data/lang/char/all.txt ]] ||
awk '{
  printf("%s", $1);
  for (i=2; i<=NF; ++i) {
    for (j=1; j<=length($i); ++j) {
      printf(" %s", substr($i, j, 1));
    }
    if (i < NF) printf(" <space>");
  }
  printf("\n");
}' data/lang/word/all.txt > data/lang/char/all.txt ||
exit 1;

# Tokenize RIMES data
[[ "$overwrite" = false && -s data/lang/word/all_tokenized.txt &&
    -s data/lang/word/boundaries.txt ]] ||
cut -d\  -f2- data/lang/word/all.txt |
./steps/rimes_tokenize.py --write-boundaries=data/lang/word/boundaries.txt |
paste -d\  <(cut -d\  -f1 data/lang/word/all.txt) - \
  > data/lang/word/all_tokenized.txt || exit 1;

# Extract lists of IDs for validation, training and test.
tmpd="$(mktemp -d)";
awk '$1 ~ /train/{ print $1}' data/lang/word/all.txt |
shuf --random-source=data/lang/word/all.txt | head -n1130 > "$tmpd/va.lst";
awk '$1 ~ /train/{ print $1}' data/lang/word/all.txt |
shuf --random-source=data/lang/word/all.txt | tail -n+1131 > "$tmpd/tr.lst";
awk '$1 ~ /eval/{ print $1}' data/lang/word/all.txt > "$tmpd/te.lst";

for p in te tr va; do
  # Split char transcripts into three partitions.
  [[ "$overwrite" = false && -s data/lang/char/$p.txt &&
      ! data/lang/char/$p.txt -ot data/lang/char/all.txt ]] ||
  awk -v VF="$tmpd/$p.lst" \
    'BEGIN{ while((getline < VF) > 0) V[$1]=1; }($1 in V)' \
    data/lang/char/all.txt > data/lang/char/$p.txt ||
  exit 1;
  # Split raw word transcripts into three partitions.
  [[ "$overwrite" = false && -s data/lang/word/$p.txt &&
      ! data/lang/word/$p.txt -ot data/lang/word/all.txt ]] ||
  awk -v VF="$tmpd/$p.lst" \
    'BEGIN{ while((getline < VF) > 0) V[$1]=1; }($1 in V)' \
    data/lang/word/all.txt > data/lang/word/$p.txt ||
  exit 1;
  # Split tokenized word transcripts into three partitions.
  [[ "$overwrite" = false && -s data/lang/word/${p}_tokenized.txt ||
      ! data/lang/word/${p}_tokenized.txt -ot data/lang/word/all_tokenized.txt ]] ||
  awk -v VF="$tmpd/$p.lst" \
    'BEGIN{ while((getline < VF) > 0) V[$1]=1; }($1 in V)' \
    data/lang/word/all_tokenized.txt > data/lang/word/${p}_tokenized.txt ||
  exit 1;

  # Create list of files.
  [[ "$overwrite" = false && -s "data/lists/$p.txt" ]] ||
  awk '{ print "data/imgproc/"$1".jpg" }' "$tmpd/$p.lst" |
  sort -V > "data/lists/$p.txt" ||
  exit 1;
  [[ "$overwrite" = false && -s "data/lists/${p}_h$height.txt" ]] ||
  awk -v H="$height" '{ print "data/imgproc_h"H"/"$1".jpg" }' "$tmpd/$p.lst" |
  sort -V > "data/lists/${p}_h$height.txt" ||
  exit 1;
done;

# Create list of symbols for Laia training.
[[ "$overwrite" = false && -s train/syms.txt &&
    ( ! train/syms.txt -ot data/lang/char/tr.txt ) &&
    ( ! train/syms.txt -ot data/lang/char/va.txt ) ]] ||
cut -d\  -f2-  data/lang/char/{tr,va}.txt | tr \  \\n | sort -V | uniq |
awk '
BEGIN{
  N = 0;
  printf("%-12s %d\n", "<eps>", N++);
  printf("%-12s %d\n", "<ctc>", N++);
}{
  printf("%-12s %d\n", $1, N++);
}' > train/syms.txt || exit 1;



exit 0;
