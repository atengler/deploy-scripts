#!/bin/bash

# INCREMENTS ALL SEQUENCES IN SINGLE PSQL DATABASE
# Example: ./increment_sequences.sh my_database

DATABASE=$1

for TABLE in $(psql ${DATABASE} -c '\dt' | awk '/table/ {print $3}'); do
    psql ${DATABASE} -c "SELECT max(nextval('"$TABLE"_id_seq')) FROM generate_series(1,200000);"
done

