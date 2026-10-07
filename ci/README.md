# Pending workflows

These belong in `.github/workflows/`. They were not pushed there because the
bot's GitHub token lacks the `workflow` scope. To activate:

    gh auth refresh -h github.com -s workflow
    git mv ci/workflows .github/workflows && git commit -m "ci: activate workflows" && git push
