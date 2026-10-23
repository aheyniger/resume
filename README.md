# Anders Heyniger's Resume

Built with [Typst](https://typst.app) from YAML data.

**Latest PDF:** [aheyniger_resume.pdf](https://github.com/aheyniger/resume/releases/latest/download/aheyniger_resume.pdf)
(tailored versions are on the [latest release](https://github.com/aheyniger/resume/releases/latest)).

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

GitHub Actions (`.github/workflows/build.yml`) builds every version on each
push. Pushes to `main` replace the `latest` release. Pushing a git tag saves
a permanent release, which is handy for recording what was sent where:

```bash
git tag sent/spacex-2026-10 && git push origin sent/spacex-2026-10
```

Fonts (EB Garamond, SIL Open Font License) live in `fonts/`, and builds use only
those, so local and CI PDFs are identical. VS Code's Tinymist preview is
pointed there by `.vscode/settings.json`.
