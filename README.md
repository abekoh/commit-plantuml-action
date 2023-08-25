# Generate and Commit PlantUML Diagrams

This action generate diagrams (`png`) from PlantUML files (`*.puml`), and commit to pull-request. Also this can add review comment of diff files.

**[See sample pull request](https://github.com/abekoh/commit-plantuml-action/pull/33)**

## Usage

example:
```
jobs:
  build:
    steps:
      - uses: actions/checkout@v2
      - name: generate and commit diagrams
        uses: abekoh/commit-plantuml-action@1.0.3
        with:
          botEmail: ${{ secrets.BOT_EMAIL }}
          botGithubToken: ${{ secrets.GITHUB_TOKEN }}
          enableReviewComment: true
          installGoogleFont: Barlow
```

You must set `actions/checkout` before this step, to get source codes.

## Inputs

### botEmail

required: true

E-mail address for committing to git. You can use secrets.

### botGithubToken

required: false

To add review comment. Use default [`secrets.GITHUB_TOKEN`](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token), or generate from [here](https://github.com/settings/tokens/new). (Select `repo` as scope.)

### enableReviewComment

required: false, default: false

If set `true`, diff png files' information are submitted to pull request.

### installGoogleFont

required: false

If set, the value will be use to download and install a font family from
[google](https://fonts.google.com/). To be used in combination with `skinparam
defaultFontName` and other FontName skin settings for plantuml.
