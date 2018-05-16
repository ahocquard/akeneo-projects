#!/bin/sh

for REQUEST_FILE in ${ES_REQUEST_DIRECTORY}/es_request_*.txt; do
    echo "Requesting $REQUEST_FILE..."
    NUMBER_CATEGORY=$(echo $REQUEST_FILE | cut -d'_' -f3 | cut -d'.' -f1)
    ELAPSED_TIME=$(cat $REQUEST_FILE | curl -s -H "Content-Type: application/x-ndjson" -XPOST localhost:9200/poc_categories/_search --data-binary @- | jq '.took')

    echo "$NUMBER_CATEGORY $ELAPSED_TIME" >> ${ES_REQUEST_DIRECTORY}/results.txt
done


