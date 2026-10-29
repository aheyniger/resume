# Anders Heyniger's Resume

Built with [Typst](https://typst.app) from YAML data.

**Latest PDF:** [Anders_Heyniger_Resume.pdf](https://aheyniger.github.io/resume/Anders_Heyniger_Resume.pdf)
(tailored versions are listed at [aheyniger.github.io/resume](https://aheyniger.github.io/resume/)).

## Files

| File | What it holds |
| --- | --- |
| `content.yaml` | All resume content, with `topics` marking what's specific to a field |
| `versions.yaml` | The output filename and the tailored versions, each a set of topics |
| `layout.typ` | Layout and styling, shared by every version |
| `private.example.yaml` | Stand-ins for private details; copy to `private.yaml` (gitignored) with the real ones |
| `checks.typ` | Checks on the two YAML files, so typos stop the build instead of dropping text |
| `scripts/build.sh` | Builds the PDFs into `out/` with the right names |
| `scripts/check-text.sh` | Checks the PDFs' text comes out intact, as resume screeners read it |
| `scripts/make-site.sh`, `site-template.html` | Build the GitHub Pages site: the published PDFs plus an index page |
| `scripts/ci/release.sh` | Creates the GitHub release for a tag (`scripts/ci/` holds the scripts only CI runs) |
| `.typst-version` | The Typst release every build uses, locally and in CI |

## Building

Needs the Typst version in `.typst-version`; `build.sh` stops if yours differs,
since layout can change between releases. To install that exact version:
`winget install --id Typst.Typst --version <version>`. To upgrade, change the
file and commit it; CI reads it too.

Run from Git Bash (or `bash scripts/build.sh ...` from PowerShell):

```bash
./scripts/build.sh                         # every version -> out/Anders_Heyniger_Resume*.pdf
./scripts/build.sh --all                   # including versions with `build: false`
./scripts/build.sh robotics                # just one version
./scripts/build.sh --watch                 # rebuild the default version on every save
./scripts/build.sh --watch webdev          # same, for one tailored version
./scripts/build.sh --private               # with private details -> out/private/
./scripts/build.sh --include-system-fonts  # also allow fonts installed on this computer
```

`--private` and `--include-system-fonts` work with any of the others.

### Private details

Details that shouldn't be in a public repo, like the phone number, live in
`private.yaml`, which git ignores. In `content.yaml` the item is just
`private: phone`, and its fields come from `private.yaml` under that key.
`--private` builds (which work with `--watch` and version names too) fill
them in; every other build, including CI, Pages, and tagged releases, leaves
those items out. On a new machine, copy `private.example.yaml` to
`private.yaml` and fill in the real values. Add each new key to both files;
the example one is what CI checks against.

## Tailoring

Add `topics: [robotics]` (any topic names) to an entry, bullet, course, or skill
in `content.yaml`. Items without topics appear everywhere; items with topics only
appear in versions whose `topics` in `versions.yaml` include one of them. To add
a version, add an entry under `versions:` in `versions.yaml`.

Two more tools for tailoring (details in the comments at the top of each file):

- **Leaving things out:** give an item an `id` in `content.yaml`, then list it
  under a version's `exclude`, e.g. `exclude: [interests]`.
- **Different wording:** give an item `variants`, wordings keyed by topic. A
  version uses the first one whose topic it selects, otherwise the plain `text`.
- **Page limit:** give a version `max-pages: 1`. Going over fails the build;
  `./scripts/build.sh --watch <version>` and the VS Code preview mark the extra pages
  in red instead, so you can see what to cut.

In any text, `*asterisks*` make bold (`\*` for a literal asterisk), and straight
quotes and apostrophes come out curly.

Misspelled field names, topics that don't appear anywhere in `content.yaml`, and
unknown section names stop the build with a message saying where the problem is.

## Publishing

GitHub Actions (`.github/workflows/build.yml`) runs on every push to `main` and
every pull request. It builds every version without `build: false`, so a broken
version fails the run right away, and runs `scripts/check-text.sh` on the PDFs: it
extracts their text with `pdftotext` and fails if a word goes missing, a
line gets mixed with words from elsewhere (e.g. two columns read across), the
name is missing, or some text won't extract cleanly. Whole lines may move, as
when a screener reads the right-aligned dates after the lines beside them. To
run it locally after a build: `./scripts/check-text.sh out/*.pdf` (Git Bash comes
with a `pdftotext`, though a different one from CI's, so results can differ).

### When the text check fails

On a PR, a failed check just fails the run. On `main` and on tags, the run
instead stops before publishing and waits for approval, in case what it
flagged is fine:

1. GitHub emails you, and the run's page shows **Review deployments**.
2. Read what the check flagged on the run's summary page (or in the build
   job's "Check PDF text" step).
3. **Approve** (pick `text-check-override`) to publish anyway: Pages deploys
   the files already built, or for a tag, a fresh machine rebuilds that
   version and creates the release. **Reject**, or leave it for 30 days, and
   nothing is published; the run fails.

Passing runs never wait. Approval comes from the `text-check-override`
environment (Settings > Environments), whose required reviewers are the
people who can approve. Its deployment history in the repo's sidebar is a
log of every approved failure.

Pushes to `main` then publish the versions that don't have `publish: false` to
[GitHub Pages](https://aheyniger.github.io/resume/), with an index page made
from `site-template.html` (light and dark). To preview it, run `./scripts/build.sh`
then `./scripts/make-site.sh` and open `site/index.html`.

| Version setting | `./scripts/build.sh` | CI checks | Pages |
| --- | --- | --- | --- |
| (neither) | yes | yes | yes |
| `publish: false` (e.g. for one application) | yes | yes | no |
| `build: false` (set aside for now) | no | no | no |

`publish: false` PDFs never leave the build machine in CI: the run's
downloadable artifact holds only the published ones too.

### Saving a release for an application

Pushing a git tag named `<version>/<label>` creates a permanent GitHub release
holding just that version, as `Anders_Heyniger_Resume.pdf`, exactly as it was at the
tagged commit (see `scripts/ci/release.sh`). The tag's message (with `-a -m`) becomes the
release notes. The version can be one marked `build: false`, so one-off
versions stay off Pages.

A tag points at a commit, so commit any changes first. Then:

```bash
git tag -a amazon/2026-10-sde-intern -m "Amazon SDE Intern, Summer 2027"  # tags the latest commit
git push origin amazon/2026-10-sde-intern
```

To tag an older commit, add its hash after the tag name. A plain `git push`
doesn't push tags. To redo a release, move the tag and force-push it; the new
release replaces the old one:

```bash
git tag -a -f amazon/2026-10-sde-intern -m "Amazon SDE Intern, Summer 2027"
git push -f origin amazon/2026-10-sde-intern
```

`git tag -l "amazon/*"` lists every release made from a version, and
`git checkout <tag>` then `./scripts/build.sh <version>` rebuilds one locally.

Fonts (EB Garamond, SIL Open Font License) live in `fonts/`, and builds use only
those, so local and CI PDFs are identical. To try a font installed on your
computer, set `body-font` in `layout.typ` and build with
`--include-system-fonts`. To keep it, add its files to `fonts/` so CI has it too. VS Code's Tinymist preview is
pointed there by `.vscode/settings.json`. Tinymist bundles its own Typst rather
than the installed one, so `.typst-version` doesn't apply to the preview and it
can occasionally lay out slightly differently; `build.sh` output is what counts.
