########################## DECODE ##############################################

#level=$1

#python create_files_list.py $1

batch_size=1

mkdir -p decode/{char,word};

#declare -a modes=("open_line" "open_close_line" "combined_transfer" "open_line_transfer" "open_close_line_transfer" "person_change")
#declare -a modes=("combined_register_transfer_curriculum")
declare -a modes=("open_line" "open_close_line" "combined_line" "combined_line_transfer" "combined_register_transfer" "person change" "combined_register_transfer_curriculum")

# Get character-level transcript hypotheses
echo "RESULTS:" > results.txt
for mode in "${modes[@]}"
do
   echo "$mode" >> ../results.txt
   echo "$mode"
   [ -f models/model_${mode}.t7 ] && echo "File exist" || echo "File does not exist"
   laia-docker decode \
     --batch_size "$batch_size" \
     --symbols_table models/data_${mode}/lang/char/symbs.txt \
     models/model_${mode}.t7 models/data_${mode}/test.lst > decode/char/test.txt;

   sort -nk1 decode/char/test.txt > decode/char/test_sorted.txt

   python kaldi_to_competition.py $mode

   cd $mode
   python ../evaluate2.py "$mode" >> ../results.txt

   cd ..
done

#for f in results*; do echo $f; cat $f; done
cat results.txt
# experiment_id=$1
#
# python ../evaluate2.py "$experiment_id" > ../results_open_line.txt
##########################################################################################################################################
#
#
# laia-docker decode \
#   --batch_size "$batch_size" \
#   --symbols_table data/lang/char/symbs.txt \
#   model.t7 data/test.lst > decode/char/test.txt;
#
# sort -nk1 decode/char/test.txt > decode/char/test_sorted.txt
#
# python kaldi_to_competition.py $mode
#
# cd $mode
# python ../evaluate2.py "$experiment_id" > ../results_${mode}.txt
# cd ..
