mkdir -p FEATS

for filename in data/imgs_proc/*.png; do
	textFeats -o ./FEATS --cfg ./feats.cfg $filename
done
