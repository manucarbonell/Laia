#!/bin/bash
set -e;
export LC_NUMERIC=C;
export LUA_PATH="$(pwd)/../../?/init.lua;$(pwd)/../../?.lua;$LUA_PATH";

batch_size=16;
height=128;
overwrite=false;

# Directory where the run.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)" != "$SDIR" ] && \
    echo "Please, run this script from the experiment top directory!" >&2 && \
    exit 1;

./steps/download.sh --overwrite "$overwrite" || exit 1;
./steps/prepare.sh --height "$height" --overwrite "$overwrite" || exit 1;
num_symbols="$(tail -n1 train/syms.txt | awk '{print $2}')";

# Train model with 1D-LSTMs
[[ "$overwrite" = false && -s "train/model_h$height.t7" ]] || (
  # Create model
  ../../laia-create-model \
    --cnn_type leakyrelu \
    --cnn_kernel_size 3 \
    --cnn_num_features 16 32 48 64 \
    --cnn_maxpool_size 2 \
    --cnn_batch_norm false \
    --rnn_num_layers 3 \
    --rnn_num_units 128 \
    --rnn_dropout 0.5 \
    --linear_dropout 0.5 \
    --log_level info \
    1 "$height" "$num_symbols" "train/model_h$height.t7";
  # Train model
  ../../laia-train-ctc \
      --use_distortions true \
      --batch_size "$batch_size" \
      --progress_table_output "train/h$height.dat" \
      --early_stop_epochs 50 \
      --learning_rate 0.0005 \
      --log_also_to_stderr info \
      --log_level info \
      --log_file "train/h$height.log" \
    "train/model_h$height.t7" train/syms.txt \
    "data/lists/tr_h$height.txt" data/lang/char/tr.txt \
    "data/lists/va_h$height.txt" data/lang/char/va.txt;
);

exit 0;
