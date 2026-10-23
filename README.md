# Anders Heyniger's Resume

Built with [Typst](https://typst.app) from YAML data.

**Latest PDF:** [aheyniger_resume.pdf](https://aheyniger.github.io/resume/aheyniger_resume.pdf)
(tailored versions are listed at [aheyniger.github.io/resume](https://aheyniger.github.io/resume/)).

## Files

| File | What it holds |
| --- | --- |
| `resume-info.yaml` | All resume content, with `tags` marking what's specific to a field |
| `versions.yaml` | The output filename and the tailored versions, each a set of tags |
| `resume.typ` | Layout and styling, shared by every version |
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

Add `tags: [robotics]` (any tag names) to an entry, bullet, course, or skill in
`resume-info.yaml`. Untagged items appear everywhere; tagged items only appear
in versions whose `tags` in `versions.yaml` include one of them. To add a
version, add an entry under `versions:` in `versions.yaml`.

## Publishing

GitHub Actions (`.github/workflows/build.yml`) runs on every push. Pushes to
`main` publish the PDFs (minus `build: false` versions) to
[GitHub Pages](https://aheyniger.github.io/resume/).

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
