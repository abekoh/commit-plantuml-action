#!/bin/bash -le

# verify
if [[ ! ${GITHUB_BASE_REF} ]]; then
  echo "ERROR: This action is only for pull-request events."
  exit 1
fi
BOT_EMAIL=$1
if [[ ! ${INPUT_BOT-EMAIL} ]]; then
  echo "ERROR: Please set inputs.bot-email"
  exit 1
fi
if [[ ! ${INPUT_BOT-GITHUB-TOKEN} ]]; then
  echo "ERROR: Please set inputs.bot-github-token"
  exit 1
fi

# generate
cd "/github/workspace"
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
git config user.email "${INPUT_BOT-EMAIL}"
git remote set-url origin https://${GITHUB_ACTOR}:${BOT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git checkout ${GITHUB_HEAD_REF}
git add .
git commit -m "[skip ci] add generated diagrams"
git push origin HEAD:${GITHUB_HEAD_REF}
echo "comitted png files"

# add review comment
if [[ ${INPUT_ENABLE-REVIEW-COMMENT} -ne "true" ]]; then
  exit 0
fi
GITHUB_SHA_AFTER=$(git rev-parse origin/${GITHUB_HEAD_REF})
DIFF_FILES=`git diff ${GITHUB_SHA} ${GITHUB_SHA_AFTER} --name-only | grep ".png"`
echo $DIFF_FILES
BODY="## Diagrams changed\n"
for DIFF_FILE in $DIFF_FILES; do
  TEMP=`cat << EOS
### [${DIFF_FILE}](https://github.com/${GITHUB_REPOSITORY}/blob/${GITHUB_SHA}/${DIFF_FILE})\n
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
BODY=`echo $BODY | sed -e "s/\:/\\\:/g"`
PULL_NUM=`echo ${GITHUB_REF} | sed -r "s/refs\/pull\/([0-9]+)\/merge/\1/"`
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${INPUT_BOT-GITHUB-TOKEN}" \
  -d "{\"event\": \"COMMENT\", \"body\": \"${BODY}\"}" \
  "${GITHUB_API_URL}/repos/abekoh/domain-model-repository/pulls/${PULL_NUM}/reviews"
echo "added review comments"