#!/bin/sh

BASEDIR=$(dirname "$0")
curl -s -X DELETE http://localhost:9200/poc_categories | cut -b 1-50

curl -s -X PUT \
  http://localhost:9200/poc_categories \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{
  "settings": {
    "analysis": {
      "analyzer": {
        "path_analyzer": {
          "tokenizer": "path_hierarchy"
        }
      }
    }
  },
  "mappings": {
    "doc": {
      "properties": {
        "categories":    {
        	"type": "text",
        	"analyzer": "path_analyzer"
        }
      }
    }
  }
}' | cut -b 1-50

for ES_FILE in ${ES_REQUEST_DIRECTORY}/*.txt; do
    echo "Loading $ES_FILE..."
    cat $ES_FILE | curl -s -H "Content-Type: application/x-ndjson" -XPOST localhost:9200/_bulk --data-binary @- | cut -b 1-50
done


