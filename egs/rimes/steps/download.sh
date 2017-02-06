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

train_img="http://www.a2ialab.com/lib/exe/fetch.php?media=rimes_database:data:icdar2011:line:training_2011_gray.tar";
train_xml="http://www.a2ialab.com/lib/exe/fetch.php?media=rimes_database:data:icdar2011:line:training_2011.xml";

test_img="http://www.a2ialab.com/lib/exe/fetch.php?media=rimes_database:data:icdar2011:line:eval_2011_gray.tar";
test_xml="http://www.a2ialab.com/lib/exe/fetch.php?media=rimes_database:data:icdar2011:line:eval_2011_annotated.xml";

mkdir -p data/a2ia;

for f in "$train_img" "$train_xml" "$test_img" "$test_xml"; do
  [ -s "data/a2ia/${f##*:}" ] && continue;
  cat <<EOF >&2
You first need to download the RIMES dataset from the A2IA webpage. This dataset
was used as a ICDAR 2011 Competition. Please, visit:
http://www.a2ialab.com/doku.php?id=rimes_database:data:icdar2011:line:icdar2011competitionline

You will need to register to A2IA in order to donwload the dataset. Place all
the files in the following directory:
$PWD/data/a2ia

You will need to download the following files:

- $train_img
- $train_xml
- $test_img
- $test_xml
EOF
  exit 1;
done;

# Untar data
[ -s data/a2ia/images_gray/train2011-0.png ] ||
  tar xf data/a2ia/training_2011_gray.tar -C data/a2ia || exit 1;
[ -s data/a2ia/images_gray/eval2011-0.png ] ||
  tar xf data/a2ia/eval_2011_gray.tar -C data/a2ia || exit 1;

# Apply patch to the training XML
[ -s data/a2ia/training_2011.patched.xml ] ||
patch -odata/a2ia/training_2011.patched.xml \
  data/a2ia/training_2011.xml data/a2ia/training_2011.patch ||
exit 1;

exit 0;
