# Saint Gall - IAM Historial Document Database

The Saint Gall database presented in contains a handwritten historical
manuscript from the 9th century, written in Latin by a single writter, using
Carolingian script. The database has been widely used in many publications
in the field of Handwritten Text Recognition and Keyword Spotting.

For additional information, visit the official webpage:
http://www.fki.inf.unibe.ch/databases/iam-historical-document-database/saint-gall-database

**IMPORTANT: You will need to register to the IAM webpage in order to download
the data.** Please, follow the instructions here:
http://www.fki.inf.unibe.ch/DBs/iamHistDB/iLogin/index.php

## Requirements

- Laia
- ImageMagick's convert
- Kaldi's compute-wer (optional)

## Results

| Valid             | Test              |
|-------------------|-------------------|
| 4.35 [4.07, 4.60] | 4.47              |

Bootstrapped confidence intervals at 95% are shown for the validation partition.

## TL;DR

Execute `run.sh' and wait for the results.