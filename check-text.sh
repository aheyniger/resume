#!/usr/bin/env bash
# Checks that resume PDFs come out right as plain text, which is how resume
# screeners (applicant tracking systems) read them. Run from the repo root:
#
#   ./check-text.sh out/*.pdf
#
# For each PDF it compares two extractions by pdftotext: the words in the
# order Typst drew them (-raw), and the lines pdftotext works out from the
# layout, as a screener does. It fails if
#   - a word is missing or extra, or
#   - a line as read isn't an unbroken run of the drawn text, i.e. it mixes
#     in words from elsewhere or splits a phrase, as when two columns are
#     read across into one line.
# Whole lines may move: some screeners read a stack of right-aligned dates
# after the lines beside them, which is fine. The contact header is only
# compared as a set of words, since its grid may be read across or down.
# It also fails if the name is missing, or on characters that appear when
# text doesn't extract cleanly (ligatures like "ﬁ", unknown glyphs).
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "usage: ./check-text.sh <pdf>..." >&2
  exit 2
fi

# The name, and the first word of each section heading, which is where the
# header ends.
name=$(typst eval 'yaml("content.yaml").name' --format yaml)
read -r -a headings <<< "$(typst eval 'yaml("content.yaml").sections.map(s => upper(s.title).split(" ").first()).join(" ")' --format yaml)"

# One word per line.
words() { pdftotext -enc UTF-8 "$@" - | tr -s '[:space:]' '\n' | sed '/^$/d'; }

# The text as laid out, one line per line with single spaces.
lines() { pdftotext -enc UTF-8 "$1" - | tr -s ' \t\f\r' ' ' | sed 's/^ //; s/ $//; /^$/d'; }

# The line number of the first section heading in a word list.
header_end() {
  local i=0 word heading
  while IFS= read -r word; do
    i=$((i + 1))
    for heading in "${headings[@]}"; do
      if [ "$word" = "$heading" ]; then echo "$i"; return; fi
    done
  done
  echo 1
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
failed=0

for pdf in "$@"; do
  words -raw "$pdf" > "$scratch/drawn"
  words "$pdf" > "$scratch/read"
  lines "$pdf" > "$scratch/lines"
  problems=()

  drawn_end=$(header_end < "$scratch/drawn")
  read_end=$(header_end < "$scratch/read")
  if ! diff -q <(head -n "$((drawn_end - 1))" "$scratch/drawn" | sort) \
               <(head -n "$((read_end - 1))" "$scratch/read" | sort) > /dev/null; then
    problems+=("the header's words differ between drawn and read order")
  fi
  tail -n "+$drawn_end" "$scratch/drawn" > "$scratch/drawn-body"
  if ! word_diff=$(diff -U 0 --label drawn --label read \
                     <(sort "$scratch/drawn-body") <(tail -n "+$read_end" "$scratch/read" | sort)); then
    problems+=("words missing (-) or extra (+) when read; first 40 lines:"$'\n'"$(head -n 40 <<< "$word_diff")")
  fi

  # Each line from the first section heading on must appear, as a whole, in
  # the drawn text.
  broken=$(awk -v headings="${headings[*]}" '
    BEGIN { split(headings, h, " "); for (i in h) is_heading[h[i]] = 1 }
    NR == FNR { drawn = drawn " " $0; next }
    !in_body { split($0, w, " "); if (w[1] in is_heading) in_body = 1; else next }
    index(drawn " ", " " $0 " ") == 0 { print "    " $0 }
    END { if (!in_body) print "    (no section heading found, so nothing was checked)" }
  ' "$scratch/drawn-body" "$scratch/lines")
  if [ -n "$broken" ]; then
    problems+=("lines that mix in words from elsewhere or split a phrase; first 20:"$'\n'"$(head -n 20 <<< "$broken")")
  fi

  if ! tr '\n' ' ' < "$scratch/read" | grep -qF "$name"; then
    problems+=("the name \"$name\" isn't in the extracted text")
  fi
  # U+FFFD (unknown), U+FB00-FB06 (ligatures), and private-use characters,
  # matched as UTF-8 bytes so it works in any locale.
  status=0
  bad=$(LC_ALL=C grep -na $'\xEF\xBF\xBD\|\xEF\xAC[\x80-\x86]\|\xEE\|\xEF[\x80-\xA3]' "$scratch/read") || status=$?
  if [ "$status" -eq 0 ]; then
    problems+=("text that won't extract cleanly (line: word):"$'\n'"$bad")
  elif [ "$status" -ne 1 ]; then
    echo "error: grep failed checking characters in $pdf" >&2
    exit 2
  fi

  if [ ${#problems[@]} -eq 0 ]; then
    echo "ok: $pdf"
  else
    failed=1
    echo "FAILED: $pdf"
    for p in "${problems[@]}"; do echo "  - $p"; done
  fi
done

exit "$failed"
