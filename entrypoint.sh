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

WEBHOOK_SIGNATURE=$(cat "$GITHUB_EVENT_PATH" | openssl sha1 -hmac "$webhook_secret" -binary | xxd -p)

curl -X POST -H "content-type: $CONTENT_TYPE" \
                 -H "User-Agent: User-Agent: GitHub-Hookshot/610258e" \
                 -H "Expect: " \
                 -H "X-GitHub-Delivery: $GITHUB_RUN_NUMBER" \
                 -H "X-Hub-Signature: sha1=$WEBHOOK_SIGNATURE" \
                 -H "X-GitHub-Event: $GITHUB_EVENT_NAME" \
                 -D - \
                 $webhook_url --data-urlencode @"$GITHUB_EVENT_PATH"

