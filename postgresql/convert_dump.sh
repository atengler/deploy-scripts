#!/bin/bash

# CONVERT STOCK PSQL DUMP TO DUMP COMPATIBLE WITH 2ndQuadrant BDR CLUSTER
# Example: ./convert_dump.sh mydb_dump.sql mybd_bdr_dump.sql

IN_FILE=$1
OUT_FILE=$2

sed '/^CREATE SEQUENCE/ s/$/ USING bdr;/' $IN_FILE > $OUT_FILE
sed -i -e '/^CREATE SEQUENCE/{n;N;N;N;N;d}' $OUT_FILE
sed -i '/SELECT pg_catalog.setval/d' $OUT_FILE

