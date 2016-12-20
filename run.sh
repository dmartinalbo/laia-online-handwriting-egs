#!/bin/bash
set -e;
export LC_NUMERIC=C;
export LUA_PATH="$(pwd)/../../?/init.lua;$(pwd)/../../?.lua;$LUA_PATH";

overwrite=false;
height=64;
num_labels=67;
batch_size=150;

# Directory where the run.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)" != "$SDIR" ] && \
    echo "Please, run this script from the experiment top directory!" && \
    exit 1;

#./steps/prepare.sh --height "$height" --overwrite "$overwrite";

../../laia-create-model \
    --cnn_type leakyrelu \
    --log_level info \
    1 "$height" "$num_labels" model.t7;

../../laia-train-ctc \
    --use_distortions false \
    --display_progress_bar true \
    --batch_size "$batch_size" \
    --progress_table_output train.csv \
    --early_stop_epochs 50 \
    --learning_rate 0.001 \
    --log_also_to_stderr info \
    --log_level info \
    --log_file train.log \
    model.t7 data/lang/chars/symbs.txt \
    data/train.lst data/lang/chars/ref.txt \
    data/test.lst data/lang/chars/ref.txt;

