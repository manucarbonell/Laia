# Washington - IAM Historial Document Database

The Washington database was created from the George Washington Papers at the
Library of Congress and has been widely used in many publications in the field
of Handwritten Text Recognition and Keyword Spotting.

For additional information, visit the official webpage:
http://www.fki.inf.unibe.ch/databases/iam-historical-document-database/washington-database

**IMPORTANT: You will need to register to the IAM webpage in order to download
the data.** Please, follow the instructions here:
http://www.fki.inf.unibe.ch/DBs/iamHistDB/iLogin/index.php

## Requirements

- Laia
- ImageMagick's convert
- Kaldi's compute-wer (optional)

## Results

|       |    CV1 CER (%)    |    CV2 CER (%)    |    CV3 CER (%)    |    CV4 CER (%)    | Avg. |
|-------|-------------------|-------------------|-------------------|-------------------|------|
| Valid | 5.47 [4.76, 6.14] | 4.02 [3.31, 4.64] | 5.12 [4.33, 5.90] | 5.87 [5.05, 6.61] | 5.12 |
| Test  | 5.31              | 4.39              | 6.22              | 5.92              | 5.46 |

Bootstrapped confidence intervals at 95% are shown for the validation partition.

## TL;DR

Execute `run.sh' and wait for the results.