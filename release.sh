#!/usr/bin/env bash
# Creates the GitHub release for the tag a CI run was started by, holding the
# one PDF built for it, under the plain filename a recruiter sees. The tag's
# message, if it has one, becomes the release notes, and a release already
# made for that tag is replaced. CI runs this; it needs the GitHub CLI signed
# in (GH_TOKEN) and GITHUB_REF_NAME set to the tag:
#
#   bash release.sh out/<pdf>
set -euo pipefail
cd "$(dirname "$0")"

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "usage: bash release.sh <pdf> (one PDF, already built)" >&2
  exit 2
fi
tag=${GITHUB_REF_NAME:?set GITHUB_REF_NAME to the tag to release}

filename=$(typst eval 'yaml("versions.yaml").filename' --format yaml)
mkdir -p out/release
cp "$1" "out/release/$filename.pdf"

git fetch --force origin "refs/tags/$tag:refs/tags/$tag"
notes=""
if [ "$(git cat-file -t "$tag")" = tag ]; then # annotated tag
  notes=$(git tag -l --format='%(contents)' "$tag")
fi
# No --cleanup-tag: the tag that triggered this run must stay.
gh release delete "$tag" --yes 2>/dev/null || true
gh release create "$tag" "out/release/$filename.pdf" \
  --title "$tag" \
  --notes "${notes:-Resume as of tag $tag.}"
