import os
import sys
from PIL import Image
#-----------------------------------------------------------
# This script generates a list of the images file's paths
# that are going to be used by LAIA for train valid and
# test partitions. On the way it also generates a textFeats
# preprocessed version of the images


basedir='/home/mcarbonell/Documents/DATASETS/OfficialEsposalles'

partitions=['train','test','validation']
output_dir='data'

image_height=64


image_segmentation_level=sys.argv[1]
if image_segmentation_level=="record":
    if not os.path.exists('/tmp/FEATS_record'):
        os.mkdir('/tmp/FEATS_record')


if not os.path.exists('/tmp/FEATS'):
    os.mkdir('/tmp/FEATS')

print "CREATE FILES LIST ",image_segmentation_level,"LEVEL"

def create_list(dataset):
    for record in sorted(os.listdir(dataset['dir'])):
        if not os.path.isdir(os.path.join(dataset['dir'],record)):
            #print record,"Not dir"
            continue
        #print record
        file_dir=os.path.join(dataset['dir'],record,'lines')

        for name in sorted(os.listdir(file_dir)):
            file_path = os.path.join(file_dir, name)
            #print file_path


            if 'png' in file_path and 'words' not in file_path:

                if not os.path.exists('/tmp/FEATS/'+name):
                    #print "\rPreprocessing file ",file_path,
                    os.system("textFeats -o /tmp/FEATS --cfg ./feats.cfg " + file_path)



                dataset['list'].write(os.path.join('/tmp/FEATS', name) + '\n')

    # Add record images to lists
    if image_segmentation_level == 'record':
        os.system('rm '+'data/'+dataset['partition']+'.lst')
        dataset['list']=open('data/'+dataset['partition']+'.lst','w')
        for record in sorted(os.listdir(os.path.join(basedir,partition))):
            if len(record.split('.'))==1: # make sure we only get record directories and not other files
                dataset['list'].write(os.path.join('/tmp/FEATS_record',record+'.png')+'\n')

if image_segmentation_level=='record' and not os.path.exists(basedir):
     os.system('python create_record_level_dataset.py')

for partition in partitions:
    dataset={}
    dataset['partition']=partition
    dataset['dir']=os.path.join(basedir,dataset['partition'])
    dataset['list']=open('data/'+dataset['partition']+'.lst','w')

    create_list(dataset)
