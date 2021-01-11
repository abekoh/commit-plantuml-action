#!/bin/bash -le

# verify
if [[ ! "${GITHUB_BASE_REF}" ]]; then
  echo "ERROR: This action is only for pull-request events."
  exit 1
fi
BOT_EMAIL=$1
if [[ ! "${BOT_EMAIL}" ]]; then
  echo "ERROR: Please set inputs.bot-email"
  exit 1
fi
BOT_GITHUB_TOKEN=$2
if [[ ! "${BOT_GITHUB_TOKEN}" ]]; then
  echo "ERROR: Please set inputs.bot-github-token"
  exit 1
fi
ENABLE_REVIEW_COMMENT=$3

# generate
cd ${GITHUB_WORKSPACE}
git fetch
SRC_FILES=$(git diff origin/${GITHUB_BASE_REF} --name-only | grep ".puml")
SRC_DIRS=$(echo ${SRC_FILES} | xargs dirname | sort | uniq)
for SRC_DIR in ${SRC_DIRS}; do
  java -jar /plantuml.jar $SRC_DIR
done
echo "generated diagrams"

# commit
if [[ ! $(git status --porcelain) ]]; then
  exit 0
fi
git config user.name "${GITHUB_ACTOR}"
git config user.email "${BOT_EMAIL}"
git remote set-url origin https://${GITHUB_ACTOR}:${BOT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git checkout ${GITHUB_HEAD_REF}
git add .
git commit -m "[skip ci] add generated diagrams"
git push origin HEAD:${GITHUB_HEAD_REF}
echo "comitted png files"

# add review comment
if [[ "${ENABLE_REVIEW_COMMENT}" = "true" ]]; then
  exit 0
fi
git fetch
GITHUB_SHA_AFTER=$(git rev-parse origin/${GITHUB_HEAD_REF})
DIFF_FILES=`git diff ${GITHUB_SHA} ${GITHUB_SHA_AFTER} --name-only | grep ".png"`
echo $DIFF_FILES
BODY="## Diagrams changed\n"
for DIFF_FILE in ${DIFF_FILES}; do
  TEMP=`cat << EOS
### [${DIFF_FILE}](https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA_AFTER}/${DIFF_FILE})\n
<details><summary>Before</summary>\n
\n
![before](https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA}/${DIFF_FILE}?raw=true)\n
\n
</details>\n
\n
![after](https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA_AFTER}/${DIFF_FILE}?raw=true)\n
\n
EOS
  `
  BODY=${BODY}${TEMP}
done
BODY=`echo ${BODY} | sed -e "s/\:/\\\:/g"`
PULL_NUM=`echo ${GITHUB_REF} | sed -r "s/refs\/pull\/([0-9]+)\/merge/\1/"`
echo "body: ${BODY}"
echo "pull-num: ${PULL_NUM}"
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${BOT_GITHUB_TOKEN}" \
  -d "{\"event\": \"COMMENT\", \"body\": \"${BODY}\"}" \
  "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/${PULL_NUM}/reviews"
echo "added review comments"