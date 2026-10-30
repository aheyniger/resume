# Notes for AI assistants

Anders Heyniger's resume: content in YAML, layout in Typst, built into PDFs by
`scripts/build.sh`. README.md explains the system (files, building, tailoring,
publishing), and the comments at the top of `content.yaml` and `versions.yaml`
document every field. Read those before changing anything.

## Where changes go

- **Content** (wording, entries, dates, skills): `content.yaml` only.
- **Which versions exist and what they include:** `versions.yaml`.
- **Layout and styling:** `layout.typ`. Style values (sizes, gaps, fonts) are
  named near the top.
- **A new field:** add it to the field lists in `checks.typ` and document it in
  the header of the YAML file it belongs to, or the build rejects it.
- **CI:** `.github/workflows/build.yml`. Release steps live in
  `scripts/ci/release.sh`, which two jobs call, so change them there, not in
  the workflow.
- **Scripts:** ones you run go in `scripts/`; ones only CI runs go in
  `scripts/ci/`. Each `cd`s to the repo root, except `check-text.sh`, which
  takes PDF paths and so runs from the root.

## Checking a change

Every change gets checked before it's called done:

```bash
./scripts/build.sh                 # all versions; fails on bad fields, warnings, page limits
./scripts/build.sh --private       # same, with private.yaml filled in -> out/private/
./scripts/check-text.sh out/*.pdf  # the text reads intact, as resume screeners see it
```

Then look at the result, since a valid build can still look wrong. Render
pages to images (out/ is gitignored):

```bash
typst compile --font-path fonts --ignore-system-fonts --input version=full layout.typ "out/preview-{p}.png"
```

Check the result for:
- text that wraps by a word or two onto a new line
- headings left alone at the bottom of a page
- page count changes
- a changed version still looking right in the others

## Content style

Keep new content consistent with what's there:

- **Dates:** abbreviate long months with a period (Jan., Feb., Aug., Sept.,
  Oct., Nov., Dec.), spell out short ones (March, April, May, June, July).
  Ranges use an en dash with spaces: `Aug. 2023 – July 2024`, not a hyphen.
  Semesters are fine for course projects: `Fall 2024`.
- **Bullets:** start with a past-tense action verb, with no "I" and no
  closing period. Be concrete, with numbers where real. Keep each to two
  printed lines at most.
- **Stack lines:** 3–5 items, the technologies that matter most, spelled
  officially (Node.js, PostgreSQL). Keep the names consistent with the Skills
  section.
- **Tailoring:** use `topics`, `variants`, and `exclude` rather than
  copying entries. An item whose topics no version selects (like
  `course_project`) appears only in versions with `topics: all`.
- Never invent experience, numbers, or skills. Ask Anders instead.

## Pitfalls

- **YAML:** quote any value starting with `*` (bold markup), since YAML reads a
  leading `*` as an alias: `- "*GPA: 3.68/4.0*; ..."`. Long bullets use `>-`.
  Write straight quotes; the layout curls them.
- **Typst** (version pinned in `.typst-version`; don't change it casually):
  - A `#let` written in markup ends at the line break. Wrap multi-line
    expressions in `{ }` or `( )`, or the rest of the expression prints as
    text on the page.
  - HTML export drops grids, so it can't stand in for the PDF's text.
- **Fonts:** only `fonts/` is used, by design. Use `--include-system-fonts`
  only for experiments.

## Don't

- Commit `private.yaml` (gitignored), or put private details like a phone
  number in `content.yaml`. They go in `private.yaml` with a stand-in in
  `private.example.yaml`.
- Commit, push, or create tags or releases unless asked. Pushing to `main`
  publishes to GitHub Pages, and a tag makes a public release.
