#!/bin/bash
set -e;
export LC_NUMERIC=C;
export LUA_PATH="$(pwd)/../../?/init.lua;$(pwd)/../../?.lua;$LUA_PATH";

batch_size=16;
height=120;
overwrite=false;

## Directory where the run.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)" != "$SDIR" ] &&
echo "Please, run this script from the directory \"$SDIR\"!" >&2 &&
exit 1;

## Download lines images from FKI.
[ -f data/washingtondb-v1.0.zip ] || {
  [ -z "$FKI_USER" -o -z "$FKI_PASSWORD" ] &&
  echo "Please, set the FKI_USER and FKI_PASSWORD variables to download the" \
    "Washington database from the FKI servers." >&2 && exit 1;
  wget -P data --user="$FKI_USER" --password="$FKI_PASSWORD" \
    http://www.fki.inf.unibe.ch/DBs/iamHistDB/data/washingtondb-v1.0.zip;
}

## Unzip dataset.
[ -d data/washingtondb-v1.0 ] ||
( cd data && unzip -uqq washingtondb-v1.0.zip && rm -rf __MACOSX && cd - &> /dev/null ) ||
exit 1;

## Prepare data for Laia training.
./steps/prepare.sh --height "$height" --overwrite "$overwrite" || exit 1;

## This is the number of output symbols of the NN, including the <ctc> symbol.
num_symbols="$(tail -n1 data/lang/char/syms.txt | awk '{print $2}')";

## Train on each partition.
mkdir -p train/{cv1,cv2,cv3,cv4};
for cv in cv1 cv2 cv3 cv4; do
  [[ "$overwrite" = false && -s train/$cv/model.t7 ]] && continue;
  th ../../laia-create-model \
    --cnn_batch_norm true \
    --cnn_type leakyrelu \
    -- 1 "$height" "$num_symbols" train/$cv/model.t7 &&
  th ../../laia-train-ctc \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file train/$cv/log \
    --progress_table_output train/$cv/dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate 0.0005 \
    train/$cv/model.t7 data/lang/char/syms.txt \
    data/lists/$cv/tr.txt data/lang/char/$cv/tr.txt \
    data/lists/$cv/va.txt data/lang/char/$cv/va.txt;
done;

## Get character-level transcript hypotheses
mkdir -p decode/no_lm/{char,word}/{cv1,cv2,cv3,cv4};
for cv in cv1 cv2 cv3 cv4; do
  for p in va te; do
    [[ "$overwrite" = false && -s decode/no_lm/char/$cv/$p.txt && \
      train/$cv/model.t7 -ot decode/no_lm/char/$cv/$p.txt ]] ||
    ../../laia-decode \
      --batch_size "$batch_size" \
      --log_level info \
      --symbols_table data/lang/char/syms.txt \
      train/$cv/model.t7 data/lists/$cv/$p.txt \
      > decode/no_lm/char/$cv/$p.txt ||
    exit 1;
  done;
done;

## Compute CER/WER.
if $(which compute-wer &> /dev/null); then
  for cv in cv1 cv2 cv3 cv4; do
    echo -n "$cv Valid ";
    compute-wer --mode=strict --print-args=false \
      ark:data/lang/char/$cv/va.txt ark:decode/no_lm/char/$cv/va.txt |
    grep WER | sed -r 's|%WER|%CER|g';

    echo -n "$cv Test ";
    compute-wer --mode=strict --print-args=false \
      ark:data/lang/char/$cv/te.txt ark:decode/no_lm/char/$cv/te.txt |
    grep WER | sed -r 's|%WER|%CER|g';
  done;
else
  echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;
