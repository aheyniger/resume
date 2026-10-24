#!/usr/bin/env bash
# Builds resume PDFs into out/, named from versions.yaml.
#
#   ./build.sh                    build every version without `build: false`
#   ./build.sh --all              build every version, including `build: false`
#   ./build.sh robotics webdev    build just those versions
#   ./build.sh --watch [version]  rebuild one version on every save
#                                 (default: the default version)
#   ./build.sh --list-published   print "<version> <pdf path>" for each version
#                                 that gets published (neither `build: false`
#                                 nor `publish: false`), without building
#
# Add --private to any build or --watch to fill in the details from the
# gitignored private.yaml (e.g. the phone number). Those PDFs go to
# out/private/ instead, so they're never mixed up with the public ones.
#
# Only the fonts in fonts/ (plus Typst's built-in ones) are used, so builds
# look identical on every machine and a missing font is an error, not a
# silent substitution. To try a font installed on your computer, set it in
# template.typ and add --include-system-fonts to any build or --watch; those
# PDFs can look different elsewhere, so it's only for experimenting.
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
typst_args=(template.typ --font-path fonts)
system_fonts=false

# --private and --include-system-fonts can go anywhere in the arguments.
args=()
for arg in "$@"; do
  if [ "$arg" = "--include-system-fonts" ]; then
    system_fonts=true
  elif [ "$arg" = "--private" ]; then
    if [ ! -f private.yaml ]; then
      echo "error: --private needs private.yaml; copy private.example.yaml to private.yaml and fill it in" >&2
      exit 1
    fi
    out_dir=out/private
    typst_args+=(--input private=true)
  else
    args+=("$arg")
  fi
done
set -- "${args[@]+"${args[@]}"}"
if [ "$system_fonts" = true ]; then
  echo "note: using fonts installed on this computer too; these PDFs may not match CI's" >&2
else
  typst_args+=(--ignore-system-fonts)
fi

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
  for version in $published_versions; do echo "$version $(pdf_path "$version")"; done
  exit 0
fi

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
