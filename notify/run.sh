#!/bin/bash
#
# Notify
#
if [[ -z $SLACK_WEBHOOK ]]; then
  echo "No Slack webhook provided! Skipping notification."
  echo "::warning title=Notify::Missing Slack webhook value"
  exit 0
fi

COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | head -n1 | sed 's/"/\\"/g')

if [[ -n "$DEFINED_JOB_STATUS" ]]; then
  JOB_STATUS="$DEFINED_JOB_STATUS"
fi

case $JOB_STATUS in
  success)
    STATUS=":tada: Succeeded"
    COLOR="good" # Green
    ;;
  failure)
    STATUS=":this-is-fine-fire: Failed"
    COLOR="danger" # Red
    ;;
  running)
    STATUS=":woman-running: Running"
    COLOR="#ffbf00" # Amber
    ;;
  cancelled)
    STATUS=":heavy_multiplication_x: Cancelled"
    COLOR="#cddbda" # Grey
    ;;
  *)
    STATUS=":grey_question: Unknown"
    COLOR="#cddbda" # Grey
    ;;
esac

IFS='' read -r -d '' PAYLOAD <<EOF
{
  "channel": "$SLACK_CHANNEL",
  "attachments": [
    {
      "color": "$COLOR",
      "title": "$GITHUB_REPOSITORY (#$GITHUB_RUN_NUMBER)",
      "title_link": "https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID",
      "fields": [
        {
          "title": "Status",
          "value": "$STATUS",
          "short": true
        },
        {
          "title": "Date",
          "value": "$(date)",
          "short": true
        },
        {
          "title": "Tag",
          "value": "$RELEASE_TAG",
          "short": true
        },
        {
          "title": "Committer",
          "value": "$COMMIT_AUTHOR",
          "short": true
        },
        {
          "title": "Commit",
          "value": "$COMMIT_MESSAGE\n(<https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA|${GITHUB_SHA: -6}> / <https://github.com/$GITHUB_REPOSITORY/compare/$GITHUB_REF_NAME|$GITHUB_REF_NAME>)",
          "short": false
        }
      ]
    }
  ]
}
EOF

RESULT=$(curl -s -XPOST -H "Content-Type: application/json" "$SLACK_WEBHOOK" -d "$PAYLOAD")

if [[ "$RESULT" != "ok" ]]; then
  echo "Error returned by Slack: $RESULT"

  if [[ "$RESULT" == "invalid_payload" ]]; then
    echo -e "Payload\n==========\n${PAYLOAD}\n==========="
  fi

  exit 1
fi
