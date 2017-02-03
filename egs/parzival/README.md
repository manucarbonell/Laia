# Parzival - IAM Historial Document Database

The Parzival database contains handwritten historical manuscripts from the
13th century, written in medieval German by three different writers.
It has been widely used in many publications in the field of Handwritten
Text Recognition and Keyword Spotting.

For additional information, visit the official webpage:
http://www.fki.inf.unibe.ch/databases/iam-historical-document-database/parzival-database

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
| 1.50 [1.21, 1.74] | 1.67              |

Bootstrapped confidence intervals at 95% are shown for the validation partition.

## TL;DR

Execute `run.sh' and wait for the results.