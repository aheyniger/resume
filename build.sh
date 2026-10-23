#!/usr/bin/env bash
# Builds resume PDFs into out/, named from versions.yaml.
#
#   ./build.sh                    build every version without `build: false`
#   ./build.sh --all              build every version, including `build: false`
#   ./build.sh robotics webdev    build just those versions
#   ./build.sh --watch [version]  rebuild one version on every save
#                                 (default: the default version)
#
# Only the fonts in fonts/ (plus Typst's built-in ones) are used, so builds
# look identical on every machine and a missing font is an error, not a
# silent substitution.
set -euo pipefail
cd "$(dirname "$0")"

out_dir=out

# Read a value from versions.yaml using Typst itself, so no YAML tool is needed.
config() { typst eval "yaml(\"versions.yaml\").$1" --format yaml; }

filename=$(config filename)
default=$(config default)
enabled_versions=$(config 'versions.pairs().filter(((k, v)) => v.at("build", default: true)).map(((k, v)) => k).join(" ")')
all_versions=$(config 'versions.keys().join(" ")')

pdf_path() {
  if [ "$1" = "$default" ]; then
    echo "$out_dir/$filename.pdf"
  else
    echo "$out_dir/${filename}_$1.pdf"
  fi
}

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
  if ! log=$(typst compile "${typst_args[@]}" --input "version=$version" "$out" 2>&1); then
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
