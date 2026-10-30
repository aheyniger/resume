#!/usr/bin/env bash
# Collects the published PDFs from out/ into site/ for GitHub Pages, with an
# index page made from site-template.html. Run ./scripts/build.sh first. CI
# runs this on every run except tags (only main deploys it); locally it's
# handy for previewing site/index.html.
set -euo pipefail
cd "$(dirname "$0")/.."

eval_yaml() { typst eval "$1" --format yaml; }
default=$(eval_yaml 'yaml("versions.yaml").default')
name=$(eval_yaml 'yaml("content.yaml").name')

commit=${GITHUB_SHA:-$(git rev-parse HEAD)}
repo=${GITHUB_REPOSITORY:+${GITHUB_SERVER_URL:-https://github.com}/$GITHUB_REPOSITORY}
repo=${repo:-$(git remote get-url origin | sed 's/\.git$//')}

rm -rf site
mkdir -p site

# One link per published PDF, as listed by `build.sh --list-published`.
main="" tailored=""
while read -r version pdf; do
  if [ ! -f "$pdf" ]; then
    echo "error: $pdf hasn't been built; run ./scripts/build.sh first" >&2
    exit 1
  fi
  cp "$pdf" site/
  file=$(basename "$pdf")
  kb=$(( ($(wc -c < "$pdf") + 1023) / 1024 ))
  label=$(eval_yaml "{
    let topics = yaml(\"versions.yaml\").versions.at(\"$version\").at(\"topics\", default: \"all\")
    if topics == \"all\" { \"Complete resume\" } else { \"Tailored for \" + topics.join(\", \") }
  }")
  item="    <li><a class=\"pdf\" href=\"$file\"><div><strong>$file</strong><span>$label</span></div><span class=\"size\">$kb KB</span></a></li>"
  if [ "$version" = "$default" ]; then
    main+="$item"$'\n'
  else
    tailored+="$item"$'\n'
  fi
done < <(bash scripts/build.sh --list-published)

if [ -n "$tailored" ]; then
  tailored="  <h2>Tailored versions</h2>
  <p class=\"intro\">The same resume, narrowed to the experience most relevant to one field.</p>
  <ul>
${tailored%$'\n'}
  </ul>"
fi

html=$(< site-template.html)
html=${html//'{{name}}'/$name}
html=${html//'{{repo}}'/$repo}
html=${html//'{{commit}}'/$commit}
html=${html//'{{short_commit}}'/${commit::7}}
html=${html//'{{date}}'/$(date -u '+%B %-d, %Y')}
html=${html//'{{main}}'/${main%$'\n'}}
html=${html//'{{tailored}}'/$tailored}
printf '%s\n' "$html" > site/index.html
echo "Wrote site/ ($(ls site/*.pdf | wc -l) PDFs)"
