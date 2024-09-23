#/usr/bin/env bash

FILE=$1
LINE=$2
COLUMN=$3

# open editor with file
$EDITOR $FILE:$LINE:$COLUMN
