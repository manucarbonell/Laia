# CONVERT DECODED OUTPUT OF TEST IMAGES TO IEHHR COMPETITION FORMAT

import json
import editdistance
import re
import os
import sys
f=open("decode/char/test_sorted.txt","r")
fcompetition=open("iehhr_predicted.csv",'w')
lines=f.readlines()
data=json.load(open("/home/mcarbonell/Documents/EsposallesCompetit/category_person_database.json"))
regex = re.compile('[^a-zA-Z]')
output_dir=sys.argv[1]

persons=['husband','wife','wifes_father','wifes_mother','husbands_father','husbands_mother','other_person']
categories=['name','surname','location','state','occupation']
if os.path.exists(output_dir):
    os.system("rm -rf "+output_dir)
    os.mkdir(output_dir)
else:
    os.mkdir(output_dir)

mode=sys.argv[1]

def correct_transcription_with_vocab(transcription,category,person,record_id):
    correction=""
    #transcription=regex.sub('',transcription)
    if len(transcription)<1:
        return transcription

    correction_distance=editdistance.eval(transcription,correction)
    if data.get(category):
        #print "CORRECTING",transcription,person,category
        for w in data[category]:
            current_word_distance = editdistance.eval(transcription,w)
            if current_word_distance < correction_distance:
                correction=w
                correction_distance = current_word_distance
        # if correction<>transcription:
        #     print "New closest word",correction

    else:
        return transcription

    if editdistance.eval(transcription,correction)<3:

        if transcription<>correction:
            print "WORD",category,person,"CORRECTED:",transcription,"->",correction,record_id
            # os.system("eog /tmp/FEATS_record/"+record_id+".png")
            # raw_input()
        return correction
    else:
        #print "WORD NOT CORRECTED",transcription,correction
        # raw_input()
        return transcription

prev_rec=""
for line in lines:
    line_id=line.split(' ')[0]
    line=' '.join(line.split(' ')[1:])
    words=line.split('{space}')

    record_id="_".join(line_id.split("_")[0:2])
    #print "RECORD ID",record_id

    fout=open(os.path.join(output_dir,record_id+"_output.csv"),"a")
    #print words
    for word in words:

        category="other"
        if prev_rec<>record_id:
            person="none"
        symbs = word.split(" ")
        transcription=[]
        for symb in symbs:
            if len(symb)>2:
                tag=symb.strip('</>')
                #print tag
                if tag in categories:
                    category=tag
                elif tag in persons:
                    person=tag
                elif tag.split('_')[0] in categories:
                    category=tag.split('_')[0]
                    #print "CATEG",category
                    person="_".join(tag.split('_')[1:])
                    #print "PERS",person
            elif len(symb)==1:
                transcription.append(symb)
            else:
                continue


        transcription="".join(transcription)
        transcription,category,person
        #print transcription,category,person
        #raw_input()
        # if category!="other":
        #     transcription=correct_transcription_with_vocab(transcription,category,person,record_id)
        if(len(transcription)>0):
            try:
                if person=='none' or category=='other':
                    continue
                #print line_id+","+transcription+","+category+","+person
                if len(line_id.split('_'))<3:
                    line_id=line_id+'_Line0'
                fout.write(line_id+","+transcription+","+category+","+person+"\n")

            except ValueError:
                continue
        prev_rec=record_id
