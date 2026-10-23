#!/usr/bin/env bash
# Builds resume PDFs into out/, named from versions.yaml.
#
#   ./build.sh                    build every version
#   ./build.sh robotics webdev    build just those versions
#   ./build.sh --watch [version]  rebuild one version on every save
#                                 (default: the default version)
#
# Extra fonts can be dropped in fonts/ and are picked up automatically.
# Set RESUME_FONT to use a different body font than Garamond (CI does this).
set -euo pipefail
cd "$(dirname "$0")"

out_dir=out

# Read a value from versions.yaml using Typst itself, so no YAML tool is needed.
config() { typst eval "yaml(\"versions.yaml\").$1" --format yaml; }

filename=$(config filename)
default=$(config default)
all_versions=$(config 'versions.keys().join(" ")')

pdf_path() {
  if [ "$1" = "$default" ]; then
    echo "$out_dir/$filename.pdf"
  else
    echo "$out_dir/${filename}_$1.pdf"
  fi
}

typst_args=(resume.typ --font-path fonts)
if [ -n "${RESUME_FONT:-}" ]; then
  typst_args+=(--input "font=$RESUME_FONT")
fi

mkdir -p "$out_dir"

if [ "${1:-}" = "--watch" ]; then
  version=${2:-$default}
  exec typst watch "${typst_args[@]}" --input "version=$version" "$(pdf_path "$version")"
fi

if [ $# -gt 0 ]; then
  versions=("$@")
else
  # Building everything: clear out PDFs from versions that no longer exist.
  rm -f "${out_dir:?}"/*.pdf
  read -r -a versions <<< "$all_versions"
fi

for version in "${versions[@]}"; do
  out=$(pdf_path "$version")
  echo "Building $out"
  typst compile "${typst_args[@]}" --input "version=$version" "$out"
done
