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

height=;
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

mapfile -t xmldata < <(
  for f in data/a2ia/training_2011.xml data/a2ia/eval_2011_annotated.xml; do
    python -c "
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

mkdir -p data/imgproc data/lang/{char,word};

txt="$(mktemp)";
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
  imgtxtenh -u mm -d 118.1102362205 - "$o" || exit 1;
  echo "$bn-$n" "${v[@]}";
done | sort -V > "$txt";
echo $txt
#[[ "$overwrite" = false && -s "data/lang/transcripts.txt"
