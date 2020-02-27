#!/bin/bash

set -ex

if [ -z "$webhook_url" ]; then
    echo "No webhook_url configured"
    exit 1
fi

if [ -z "$webhook_secret" ]; then
    echo "No webhook_secret configured"
    exit 1
fi

if [ -n "$data_type" ] && [ "$data_type" == "csv" ]; then
    CONTENT_TYPE="text/csv"
else
    CONTENT_TYPE="application/json"
fi

if [ "$CONTENT_TYPE" == "text/csv" ]; then
    
    DATA_CSV="\"$GITHUB_REPOSITORY\";\"$GITHUB_REF\";\"$GITHUB_SHA\";\"$GITHUB_EVENT_NAME\";\"$GITHUB_WORKFLOW\""
    if [ -n "$data" ]; then
        WEBHOOK_DATA="$DATA_CSV;$data"
    else
        WEBHOOK_DATA="$DATA_CSV"
    fi

else

   
    if [ -n "$GITHUB_EVENT_PATH" ]; then
        #COMPACT_JSON=$(echo -n "$data" | jq -c '')
        WEBHOOK_DATA=$(jq -c . $GITHUB_EVENT_PATH)
    else
        DATA_JSON="\"repository\":\"$GITHUB_REPOSITORY\",\"ref\":\"$GITHUB_REF\",\"commit\":\"$GITHUB_SHA\",\"trigger\":\"$GITHUB_EVENT_NAME\",\"workflow\":\"$GITHUB_WORKFLOW\""
        WEBHOOK_DATA="{$DATA_JSON}"
    fi

fi

WEBHOOK_SIGNATURE=$(echo -n "$WEBHOOK_DATA" | openssl sha1 -hmac "$webhook_secret" -binary | xxd -p)

if [ -n "$webhook_auth" ]; then
    curl -X POST -H "content-type: $CONTENT_TYPE" \
                 -H "User-Agent: User-Agent: GitHub-Hookshot/610258e" \
                 -H "Expect: " \
                 -H "X-GitHub-Delivery: $GITHUB_RUN_NUMBER" \
                 -H "X-Hub-Signature: sha1=$WEBHOOK_SIGNATURE" \
                 -H "X-GitHub-Event: $GITHUB_EVENT_NAME" \
                 -D - \
                 --data "$WEBHOOK_DATA" -u $webhook_auth $webhook_url
else
    curl -X POST -H "content-type: $CONTENT_TYPE" -H "x-hub-signature: sha1=$WEBHOOK_SIGNATURE" -H "x-github-event: $GITHUB_EVENT_NAME" --data "$WEBHOOK_DATA" $webhook_url
fi

