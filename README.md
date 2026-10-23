# Anders Heyniger's Resume

Built with [Typst](https://typst.app) from YAML data.

**Latest PDF:** [aheyniger_resume.pdf](https://aheyniger.github.io/resume/aheyniger_resume.pdf)
(tailored versions are listed at [aheyniger.github.io/resume](https://aheyniger.github.io/resume/)).

## Files

| File | What it holds |
| --- | --- |
| `content.yaml` | All resume content, with `topics` marking what's specific to a field |
| `versions.yaml` | The output filename and the tailored versions, each a set of topics |
| `template.typ` | Layout and styling, shared by every version |
| `checks.typ` | Checks on the two YAML files, so typos stop the build instead of dropping text |
| `build.sh` | Builds the PDFs into `out/` with the right names |

## Building

Run from Git Bash (or `bash build.sh ...` from PowerShell):

```bash
./build.sh                  # every version -> out/aheyniger_resume*.pdf
./build.sh --all            # including versions with `build: false`
./build.sh robotics         # just one version
./build.sh --watch          # rebuild the default version on every save
./build.sh --watch webdev   # same, for one tailored version
```

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
  `./build.sh --watch <version>` and the VS Code preview mark the extra pages
  in red instead, so you can see what to cut.

Misspelled field names, topics that don't appear anywhere in `content.yaml`, and
unknown section names stop the build with a message saying where the problem is.

## Publishing

GitHub Actions (`.github/workflows/build.yml`) runs on every push to `main` and
every pull request. It builds every version without `build: false`, so a broken
version fails the run right away. Pushes to `main` then publish the versions
that don't have `publish: false` to
[GitHub Pages](https://aheyniger.github.io/resume/).

| Version setting | `./build.sh` | CI checks | Pages |
| --- | --- | --- | --- |
| (neither) | yes | yes | yes |
| `publish: false` (e.g. for one application) | yes | yes | no |
| `build: false` (set aside for now) | no | no | no |

`publish: false` PDFs never leave the build machine in CI: the run's
downloadable artifact holds only the published ones too.

### Saving a release for an application

Pushing a git tag named `<version>/<label>` creates a permanent GitHub release
holding just that version, as `aheyniger_resume.pdf`, exactly as it was at the
tagged commit. The tag's message (with `-a -m`) becomes the release notes. The
version can be one marked `build: false`, so one-off versions stay off Pages.

A tag points at a commit, so commit any changes first. Then:

```bash
git tag -a amazon/2026-10-sde-intern -m "Amazon SDE Intern, Summer 2027"  # tags the latest commit
git push origin amazon/2026-10-sde-intern
```

To tag an older commit, add its hash after the tag name. A plain `git push`
doesn't push tags. `git tag -l "amazon/*"` lists every release made from a
version, and `git checkout <tag>` then `./build.sh <version>` rebuilds one
locally.

Fonts (EB Garamond, SIL Open Font License) live in `fonts/`, and builds use only
those, so local and CI PDFs are identical. VS Code's Tinymist preview is
pointed there by `.vscode/settings.json`.
