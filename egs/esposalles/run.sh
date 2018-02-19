
########## OPEN TAG - LINE LEVEL #########################################################
overwrite=false

batch_size=6

echo "Create ground truth kaldi table and files list..."
python create_kaldi_table_complete.py line open #GENERATES GROUND TRUTH FILE IN DESIRED FORMAT

python create_files_list.py line # GENERATES A LIST WITH THE TRAINING EXAMPLE FILE NAMES

echo "Done."

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

num_symbols=$[$(wc -l data/lang/char/symbs.txt | cut -d\  -f1) - 1];

echo -n "Create model and train...">&2;
laia-docker create-model \
     --cnn_batch_norm true \
     --cnn_type leakyrelu \
     --rnn_num_units 300 \
 -- 3 64 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_open_line.t7
cp -r data models/data_open_line

############################## OPEN CLOSE  - LINE LEVEL ##############################################

echo "Create ground truth kaldi table and files list..."
python create_kaldi_table_complete.py line open

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

num_symbols=$[$(wc -l data/lang/char/symbs.txt | cut -d\  -f1) - 1];

echo -n "Create model and train...">&2;
laia-docker create-model \
     --cnn_batch_norm true \
     --cnn_type leakyrelu \
     --rnn_num_units 300 \
 -- 3 64 $num_symbols model.t7


laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_open_close_line.t7
cp -r data models/data_open_close_line


############################### COMBINED TAGS - LINE #############################

python create_kaldi_table_complete.py line combined

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

num_symbols=$[$(wc -l data/lang/char/symbs.txt | cut -d\  -f1) - 1];

echo -n "Create model and train...">&2;
laia-docker create-model \
     --cnn_batch_norm true \
     --cnn_type leakyrelu \
     --rnn_num_units 300 \
 -- 3 64 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_combined_line.t7
cp -r data models/data_combined_line


############################### PERSON CHANGE TAGS - LINE #############################

batch_size=8
python create_files_list.py line

python create_kaldi_table_complete.py line person_change

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

num_symbols=$[$(wc -l data/lang/char/symbs.txt | cut -d\  -f1) - 1];

echo -n "Create model and train...">&2;
laia-docker create-model \
     --cnn_batch_norm true \
     --cnn_type leakyrelu \
     --rnn_num_units 300 \
 -- 3 64 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_person_change_line.t7
cp -r data models/data_person_change_line


########################### COMBINED TAGS - LINE - TRANSFER ##################################
echo -n "Adapt model for transfer learning and train...">&2;
laia-docker reuse-model model-for-transfer-learning.t7 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_combined_line_transfer.t7
cp -r data models/data_combined_line_transfer


########################### COMBINED TAGS - REGISTER - TRANSFER ##################################
python create_kaldi_table_complete.py record combined

python create_files_list.py record

echo -n "Adapt model for transfer learning and train...">&2;
laia-docker reuse-model model-for-transfer-learning.t7 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_combined_register_transfer.t7
cp -r data models/data_combined_register_transfer

########################### COMBINED TAGS - REGISTER - TRANSFER CURRICULUM #############
python create_kaldi_table_complete.py line combined

python create_files_list.py line


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

num_symbols=$[$(wc -l data/lang/char/symbs.txt | cut -d\  -f1) - 1];


echo -n "Adapt model for transfer learning and train...">&2;
laia-docker reuse-model model-for-transfer-learning.t7 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

python create_kaldi_table_complete.py record combined

python create_files_list.py record

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_combined_register_transfer_curriculum.t7
cp -r data models/data_combined_register_transfer_curriculum


########################### COMBINED TAGS - CURRICULUM ##################################
python create_kaldi_table_complete.py line combined

python create_files_list.py line

echo -n "Adapt model for transfer learning and train...">&2;
laia-docker reuse-model model-for-transfer-learning.t7 $num_symbols model.t7

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

python create_kaldi_table_complete.py record combined

python create_files_list.py record

laia-docker train-ctc \
    --adversarial_weight 0.5 \
    --batch_size "$batch_size" \
    --log_also_to_stderr info \
    --log_level info \
    --log_file laia.log \
    --progress_table_output laia.dat \
    --use_distortions true \
    --early_stop_epochs 100 \
    --learning_rate_decay 0.99 \
    --learning_rate 0.0005 \
    model.t7 data/lang/char/symbs.txt \
    data/train.lst data/lang/char/train.txt \
    data/validation.lst data/lang/char/valid.txt;

cp model.t7 models/model_combined_line_curriculum.t7
cp -r data models/data_combined_line_curriculum
