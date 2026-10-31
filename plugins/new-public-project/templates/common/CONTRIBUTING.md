# Contributing

1. Fork, then create a branch. Direct pushes to `main` are blocked.
2. Run `git config core.hooksPath .githooks` so secrets are blocked before commit.
3. Open a PR. The title must follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`), because PRs are squash-merged and the title becomes the commit message.
4. All checks must pass, review threads must be resolved, and the code owner must approve.

Never commit secrets, tokens, `.env` files or personal data.
