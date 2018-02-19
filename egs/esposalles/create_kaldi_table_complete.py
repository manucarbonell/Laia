from itertools import izip
import os
import re
import sys
data_path='data/lang/char'
basedir='/home/mcarbonell/Documents/DATASETS/OfficialEsposalles/'
if not os.path.exists(data_path):
    os.makedirs(data_path)

train_fout=open(os.path.join(data_path,'train.txt'),'w')
test_fout=open(os.path.join(data_path,'test.txt'),'w')
valid_fout=open(os.path.join(data_path,'valid.txt'),'w')

level=sys.argv[1] #{record,line}

mode=sys.argv[2] #{open_close,open,combined,person_change}

print "CREATE KALDI TABLE AT ",level,"LEVEL, WITH ",mode,"LABELING"

def generate_table(partition,fout):
    gt_path=basedir+partition+'/groundtruth_full.txt'
    gt_file=open(gt_path,'r')
    prev_rec=-1
    file_start=True
    lines=gt_file.readlines()

    for line in lines:

        cols=line.split(":")
        word_id=cols[0]
        word_transcript=cols[1]
        #word_transcript=re.sub(r'\W+', '', word_transcript) #REMOVE NON ALPHANUMERIC
        #word_transcript=word_transcript.lower()
        word_category=cols[2]
        word_person=cols[3].rstrip()
        #print word_person,word_category,word_transcript


        if level=='line':
            record_id = "_".join(word_id.split('_')[0:3])
            current_rec=record_id

        elif level =='record':
            record_id = "_".join(word_id.split('_')[0:2])
            current_rec=record_id

        # WRITE WORD CHARACTERS TO FILE AND
        if current_rec <> prev_rec:
            if not file_start:
                fout.write('\n')
            #print current_rec,prev_rec
            fout.write(current_rec+" {space} ")
            file_start = False
            current_pers='none'

        #print current_rec,current_pers

        if word_category in ['name', 'surname', 'state', 'location', 'occupation']:


            if word_person in ['wife','husband','wifes_father','wifes_mother','husbands_father','husbands_mother','other_person']:
                if mode=="open_close" or mode=="open":
                    fout.write('<' + word_category + '> ')
                    fout.write('<' + word_person + '> ')

                elif mode=="combined":
                    fout.write('<'+word_category+'_'+word_person+'> ')

                elif mode=='person_change':
                    if word_person<>current_pers:
                        fout.write('<' + word_person + '> ')
                    fout.write('<' + word_category + '> ')

                else:
                    #print "**************************\n\n\n\n\nCHOSE MODE (open_close,open,combined)\n\n\n\********************************************"
                    sys.exit()
                for letter in word_transcript:
                    fout.write(letter + ' ')

                if mode=="open_close":

                    fout.write('</' + word_person + '> ')
                    fout.write('</' + word_category + '> ')

        else:
            for letter in word_transcript:
                fout.write(letter + ' ')

        fout.write('{space} ')
        current_pers=word_person
        prev_rec = current_rec

generate_table("train",train_fout)
generate_table("test",test_fout)
generate_table("validation",valid_fout)
