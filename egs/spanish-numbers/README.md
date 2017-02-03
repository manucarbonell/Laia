# Step-by-step Training Guide Using Spanish Numbers Dataset

Spanish Numbers Dataset is a small dataset of 485 images containing handwritten sentences of Spanish numbers (298 for training and 187 for testing).

![Example](example.png "Example")

## Requirements

- Laia
- ImageMagick's convert
- Optionally: Kaldi's compute-wer

## Training

To train a new Laia model for the Spanish Numbers dataset just follow these steps. Given that this dataset does not provide validation partition, we will use the test partition as validation.

- Download the Spanish Numbers dataset:
```bash
mkdir -p data/;
wget -P data/ https://www.prhlt.upv.es/corpora/spanish-numbers/Spanish_Number_DB.tgz;
tar -xvzf data/Spanish_Number_DB.tgz -C data/;
```

- Execute `steps/prepare.sh`. This script assumes that Spanish Numbers dataset is inside `data` folder. This script does the following:
  - Transforms the images from pbm to png.
  - Scales them to 64px height.
  - Creates the auxiliary files necessary for training.

- Execute the `laia-create-model` script to create an "empty" laia model using:
```bash
../../laia-create-model \
  --cnn_batch_norm true \
  --cnn_type leakyrelu \
  -- 1 64 20 model.t7;
```

- Use the `laia-train-ctc` script to train the model:
```bash
../../laia-train-ctc \
  --adversarial_weight 0.5 \
  --batch_size "$batch_size" \
  --log_also_to_stderr info \
  --log_level info \
  --log_file laia.log \
  --progress_table_output laia.dat \
  --use_distortions true \
  --early_stop_epochs 100 \
  --learning_rate 0.0005 \
  model.t7 data/lang/char/symbs.txt \
  data/train.lst data/lang/char/train.txt \
  data/test.lst data/lang/char/test.txt;
```

After 366 epochs the model achieves a CER=~2.08% in test, with a 95% confidence
interval in [1.295%, 2.610%].

## Decoding

You can use laia-decode to obtain the transcripts of any set of images.

```bash
../../laia-decode --symbols_table data/lang/char/symbs.txt \
  model.t7 data/test.lst > test_hyp.char.txt;
```

Once you have created the test_hyp.char.txt you can compute the character
error rate (CER) using Kaldi's compute-wer, for instance:

```bash
compute-wer --mode=strict ark:data/lang/char/test.txt ark:test_hyp.char.txt |
grep WER | sed -r 's|%WER|%CER|g';
```

In order to compute the WER, you will need first to convert the character-level
transcripts into word-level transcripts (you can use a simple AWK script,
for instance). Finally, you can compute the WER using Kaldi's compute-wer
as well.

```bash
# Get word-level hypothesis transcript
awk '{
  printf("%s ", $1);
  for (i=2;i<=NF;++i) {
    if ($i == "{space}")
      printf(" ");
    else
      printf("%s", $i);
  }
  printf("\n");
}' test_hyp.char.txt > test_hyp.word.txt;
# ... and compute WER
compute-wer --mode=strict ark:data/lang/word/test.txt ark:test_hyp.word.txt |
grep WER;
```

## TL;DR

Execute `run.sh`.
