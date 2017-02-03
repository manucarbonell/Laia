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
[ -f data/parzivaldb-v1.0.zip ] || {
  [ -z "$FKI_USER" -o -z "$FKI_PASSWORD" ] &&
  echo "Please, set the FKI_USER and FKI_PASSWORD variables to download the" \
    "Parzival database from the FKI servers." >&2 && exit 1;
  wget -P data --user="$FKI_USER" --password="$FKI_PASSWORD" \
    http://www.fki.inf.unibe.ch/DBs/iamHistDB/data/parzivaldb-v1.0.zip;
}

## Unzip dataset.
[ -d data/parzivaldb-v1.0 ] ||
( cd data && unzip -uqq parzivaldb-v1.0.zip && rm -rf __MACOSX && cd - &> /dev/null ) ||
exit 1;

## Prepare data for Laia training.
./steps/prepare.sh --height "$height" --overwrite "$overwrite" || exit 1;

## This is the number of output symbols of the NN, including the <ctc> symbol.
num_symbols="$(tail -n1 data/lang/char/syms.txt | awk '{print $2}')";

## Create and train a CNN + LSTM model.
mkdir -p train;
[[ "$overwrite" = true || ! -s train/model.t7 ]] &&
th ../../laia-create-model \
  --cnn_batch_norm true \
  --cnn_type leakyrelu \
  -- 1 "$height" "$num_symbols" train/model.t7 &&
th ../../laia-train-ctc \
  --batch_size "$batch_size" \
  --log_also_to_stderr info \
  --log_level info \
  --log_file train/log \
  --progress_table_output train/dat \
  --use_distortions true \
  --early_stop_epochs 100 \
  --learning_rate 0.0005 \
  train/model.t7 data/lang/char/syms.txt \
  data/lists/tr.txt data/lang/char/tr.txt \
  data/lists/va.txt data/lang/char/va.txt;

## Get character-level transcript hypotheses
mkdir -p decode/no_lm/{char,word};
for p in va te; do
  [[ "$overwrite" = false && -s decode/no_lm/char/$p.txt && \
    train/model.t7 -ot decode/no_lm/char/$p.txt ]] ||
  ../../laia-decode \
    --batch_size "$batch_size" \
    --log_level info \
    --symbols_table data/lang/char/syms.txt \
    train/model.t7 data/lists/$p.txt > decode/no_lm/char/$p.txt ||
  exit 1;
done;

## Compute CER/WER.
if $(which compute-wer &> /dev/null); then
  echo -n "Valid ";
  compute-wer --mode=strict --print-args=false \
    ark:data/lang/char/va.txt ark:decode/no_lm/char/va.txt |
  grep WER | sed -r 's|%WER|%CER|g';

  echo -n "Test ";
  compute-wer --mode=strict --print-args=false \
    ark:data/lang/char/te.txt ark:decode/no_lm/char/te.txt |
  grep WER | sed -r 's|%WER|%CER|g';
else
  echo "ERROR: Kaldi's compute-wer was not found in your PATH!" >&2;
fi;
