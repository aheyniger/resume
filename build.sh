#!/usr/bin/env bash
# Builds resume PDFs into out/, named from versions.yaml.
#
#   ./build.sh                    build every version without `build: false`
#   ./build.sh --all              build every version, including `build: false`
#   ./build.sh robotics webdev    build just those versions
#   ./build.sh --watch [version]  rebuild one version on every save
#                                 (default: the default version)
#   ./build.sh --list-published   print the PDF paths of versions that get
#                                 published (neither `build: false` nor
#                                 `publish: false`), without building anything
#
# Only the fonts in fonts/ (plus Typst's built-in ones) are used, so builds
# look identical on every machine and a missing font is an error, not a
# silent substitution.
set -euo pipefail
cd "$(dirname "$0")"

# Layout can change between Typst releases, so every build uses the version in
# .typst-version (CI reads the same file). Stop rather than warn: a warning is
# easy to miss, and a mismatch means local PDFs may not match published ones.
wanted_typst=$(tr -d '[:space:]' < .typst-version)
local_typst=$(typst --version | awk '{print $2}')
if [ "$local_typst" != "$wanted_typst" ]; then
  echo "error: Typst $local_typst is installed, but .typst-version asks for $wanted_typst." >&2
  echo "  To match it:            winget install --id Typst.Typst --version $wanted_typst" >&2
  echo "  To upgrade on purpose:  put $local_typst in .typst-version and commit it, so CI switches too" >&2
  exit 1
fi

out_dir=out

# Read a value from versions.yaml using Typst itself, so no YAML tool is needed.
config() { typst eval "yaml(\"versions.yaml\").$1" --format yaml; }

filename=$(config filename)
default=$(config default)
enabled_versions=$(config 'versions.pairs().filter(((k, v)) => v.at("build", default: true)).map(((k, v)) => k).join(" ")')
published_versions=$(config 'versions.pairs().filter(((k, v)) => v.at("build", default: true) and v.at("publish", default: true)).map(((k, v)) => k).join(" ")')
all_versions=$(config 'versions.keys().join(" ")')

pdf_path() {
  if [ "$1" = "$default" ]; then
    echo "$out_dir/$filename.pdf"
  else
    echo "$out_dir/${filename}_$1.pdf"
  fi
}

if [ "${1:-}" = "--list-published" ]; then
  for version in $published_versions; do pdf_path "$version"; done
  exit 0
fi

typst_args=(template.typ --font-path fonts --ignore-system-fonts)

mkdir -p "$out_dir"

if [ "${1:-}" = "--watch" ]; then
  version=${2:-$default}
  exec typst watch "${typst_args[@]}" --input "version=$version" "$(pdf_path "$version")"
fi

if [ $# -eq 0 ] || [ "$1" = "--all" ]; then
  # Building everything: clear out PDFs from versions that no longer exist.
  rm -f "${out_dir:?}"/*.pdf
  if [ $# -eq 0 ]; then
    read -r -a versions <<< "$enabled_versions"
  else
    read -r -a versions <<< "$all_versions"
  fi
else
  versions=("$@")
fi

for version in "${versions[@]}"; do
  out=$(pdf_path "$version")
  echo "Building $out"
  # Treat warnings (e.g. an unknown font) as errors so they can't slip into CI output.
  # strict=true makes going over a version's max-pages an error (see template.typ).
  if ! log=$(typst compile "${typst_args[@]}" --input "version=$version" --input strict=true "$out" 2>&1); then
    echo "$log"
    exit 1
  fi
  if [ -n "$log" ]; then
    echo "$log"
    if grep -q "^warning:" <<< "$log"; then
      echo "error: warnings are treated as errors"
      exit 1
    fi
  fi
done
