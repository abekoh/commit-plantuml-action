#!/bin/bash -le

# verify
if [[ ! "${GITHUB_BASE_REF}" ]]; then
  echo "ERROR: This action is only for pull-request events."
  exit 1
fi
if [[ ! "${INPUT_BOTEMAIL}" ]]; then
  echo "ERROR: Please set inputs.botEmail"
  exit 1
fi
if [[ "${INPUT_ENABLEREVIEWCOMMENT}" = "true" && ! "${INPUT_BOTGITHUBTOKEN}" ]]; then
  echo "ERROR: Please set inputs.botGithubToken"
  exit 1
fi
if [ -z "$INPUT_INSTALLGOOGLEFONT" ]; then
  echo "No font family defined"
else
  echo "Installing $INPUT_INSTALLGOOGLEFONT"
  wget -O $INPUT_INSTALLGOOGLEFONT.zip https://fonts.google.com/download?family=$INPUT_INSTALLGOOGLEFONT
  unzip -d $INPUT_INSTALLGOOGLEFONT/ $INPUT_INSTALLGOOGLEFONT.zip
  mv $INPUT_INSTALLGOOGLEFONT /usr/share/fonts/
  rm -rf $INPUT_INSTALLGOOGLEFONT.zip
  fc-cache -fv
fi

# generate
git config --global --add safe.directory ${GITHUB_WORKSPACE}
cd ${GITHUB_WORKSPACE}
git fetch
SRC_FILES=$(git diff origin/${GITHUB_BASE_REF} --name-only | grep ".puml" || :)
for SRC_FILE in ${SRC_FILES}; do
  java -jar /plantuml.jar $SRC_FILE -charset UTF-8
  echo "generate from $SRC_FILE"
done

# commit
if [[ ! $(git status --porcelain) ]]; then
  echo "No changes to commit"
  exit 0
fi
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${INPUT_BOTEMAIL}"
git checkout ${GITHUB_HEAD_REF}
git commit -am "add generated diagrams"
echo "comitted png files"

# add review comment
if [[ "${INPUT_ENABLEREVIEWCOMMENT}" != "true" ]]; then
  git push origin HEAD:${GITHUB_HEAD_REF}
  exit 0
fi
echo "1"
git fetch
echo "2"
GITHUB_SHA_AFTER=$(git rev-parse origin/${GITHUB_HEAD_REF})
echo "3"
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
echo "4"
BODY=`echo ${BODY} | sed -e "s/\:/\\\:/g"`
PULL_NUM=`echo ${GITHUB_REF} | sed -r "s/refs\/pull\/([0-9]+)\/merge/\1/"`
echo "body: ${BODY}"
echo "pull-num: ${PULL_NUM}"
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${INPUT_BOTGITHUBTOKEN}" \
  -d "{\"event\": \"COMMENT\", \"body\": \"${BODY}\"}" \
  "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/${PULL_NUM}/reviews"
echo "added review comments"
echo "5"
git push origin HEAD:${GITHUB_HEAD_REF}
