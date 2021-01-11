# Commit PlantUML Action

This action generate diagrams (png) from PlantUML files (*.puml), and commit to pull-request.

## Usage

example:
```
jobs:
  build:
    steps:
      - uses: actions/checkout@v2
      - name: generate and commit diagrams
        uses: abekoh/commit-plantuml-action@v3
        with:
          botEmail: ${{ secrets.BOT_EMAIL }}
          botGithubToken: ${{ secrets.BOT_GITHUB_TOKEN }}
          enableReviewComment: true
```

You must set `actions/checkout` before this step, to get source codes.

## Inputs

### botEmail

required: true

E-mail address for committing to git. You can use secrets.

### botGithubToken

required: false

To add review comment. Please generate from [here](https://github.com/settings/tokens/new). (Select `repo` as scope.)

### enableReviewComment

required: false, default: false

If set `true`, diff png files' information are submitted to pull request.