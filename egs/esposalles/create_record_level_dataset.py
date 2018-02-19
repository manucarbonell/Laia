import os
import sys
import numpy as np
from PIL import Image
import glob
esposalles_basedir='/tmp/FEATS'

IM_HEIGHT=64
dir_out='/tmp/FEATS_record'
if not os.path.exists(dir_out):
	os.mkdir(dir_out)
def paste_lines_in_record(record_id):
	images_in_record=sorted(glob.glob(os.path.join(esposalles_basedir,record_id+'*.png')))
	record_image=np.zeros(1)
	for image in images_in_record:
		im=Image.open(image)
		im=im.resize((im.size[0]*IM_HEIGHT/im.size[1],IM_HEIGHT))
		im=np.array(im)
		if len(record_image)==1:
			record_image=np.array(im)
		else:
			record_image=np.hstack((record_image,im))
	recim=Image.fromarray(record_image)
	recim.save(os.path.join(dir_out,record_id)+'.png')

prev_record_id=""
for line_image in sorted(os.listdir(esposalles_basedir)):
	current_record_id="_".join(line_image.split('_')[0:2])
	if current_record_id!=prev_record_id:
		paste_lines_in_record(current_record_id)


	prev_record_id=current_record_id
