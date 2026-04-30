# Contributing

Thanks for opening this. A few ground rules so we can move fast.

## Before you write code

1. **Open an issue first** for anything bigger than a typo or a one-line fix. Lets us tell you whether it's already in flight or out of scope.
2. **Read the relevant repo's `goals.md` / `STATUS.md` / `DECISIONS/` if they exist.** A lot of the "why" lives there.
3. **No drive-by AI-generated patches.** We can spot them. If you used an assistant, that's fine; the human author still has to understand and stand behind every line.

## Pull requests

- One concern per PR. A bug fix and a refactor in the same PR get the bug fix merged and the refactor sent back.
- Tests with the change. Behaviour changes ship with regression tests. Lint clean.
- Commit messages explain the *why*, not the *what*. Imperative mood.
- No `Co-Authored-By: Claude` (or any AI co-author trailer). The human committer is the author.

## Style

- Be terse. Comments explain *why*, not *what*. Names do the work.
- Don't add error handling for things that can't happen. Trust internal contracts.
- Don't add backwards-compatibility shims if you can just change the code.
- Don't apologise in PR descriptions. State what you did.

## Code of Conduct

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Security

If you've found a vulnerability, **don't open an issue.** See [SECURITY.md](SECURITY.md).
