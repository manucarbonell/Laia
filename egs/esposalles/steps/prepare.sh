#!/bin/bash
set -e;
segmentation_level="line"
# Directory where the prepare.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)/steps" != "$SDIR" ] && \
    echo "Please, run this script from the experiment top directory!" >&2 && \
    exit 1;
[ ! -f "$(pwd)/utils/parse_options.inc.sh" ] && \
    echo "Missing $(pwd)/utils/parse_options.inc.sh file!" >&2 && exit 1;

overwrite=true;
height=64;
dataset_name="Esposalles";

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
echo "Creating Kaldi Table ground truth..."

python create_kaldi_table_complete.py line

echo "Prepare gt files lists..."
python create_files_list.py line

mkdir -p data/lang/{char,word};

echo -n "Creating symbols table..." >&2;
# Generate symbols table from trainining and validation characters.
# This table will be used to convert characters to integers using Kaldi format.
[ -s data/lang/char/symbs.txt -a $overwrite = true ] || (
  for p in train valid; do
    cut -f 2- -d\  data/lang/char/$p.txt | tr \  \\n;
  done | sort -u -V |
  awk 'BEGIN{
    N=0;
    printf("%-12s %d\n", "<eps>", N++);
    printf("%-12s %d\n", "<ctc>", N++);
  }NF==1{
    printf("%-12s %d\n", $1, N++);
  }' > data/lang/char/symbs.txt;
)
echo -e "  \tDone." >&2;
