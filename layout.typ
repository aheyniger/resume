// Resume layout. All content lives in content.yaml and the list of
// tailored versions in versions.yaml; this file only controls how it looks.
// Build with ./scripts/build.sh (see README), which also supplies the fonts in
// fonts/, the version to build, and strict page limits. Compiling this file
// directly skips those, so use ./scripts/build.sh for any PDF you keep.

#import "checks.typ": check-content, check-versions, fill-private

#let config = yaml("versions.yaml")
#let raw = yaml("content.yaml")

// Items marked `private: <key>` get their fields from the gitignored
// private.yaml in `./scripts/build.sh --private` builds and are left out of
// every other build. The checks run on the content filled in from the committed
// private.example.yaml, so even public builds catch a key missing from it.
#let private = sys.inputs.at("private", default: "false") == "true"
#let checked = fill-private(raw, yaml("private.example.yaml"), "private.example.yaml")
#check-content(checked)
#check-versions(config, checked)
#let data = if private {
  fill-private(raw, yaml("private.yaml"), "private.yaml")
} else {
  fill-private(raw, none, none)
}
#if private { check-content(data, file: "content.yaml + private.yaml") }

// ---- Version selection ----
#let version-name = sys.inputs.at("version", default: config.default)
#assert(
  version-name in config.versions,
  message: "unknown version '" + version-name + "', expected one of: " + config.versions.keys().join(", "),
)
#let version = config.versions.at(version-name)
#let version-topics = version.at("topics", default: "all")
#let version-exclude = version.at("exclude", default: ())
#let max-pages = version.at("max-pages", default: none)
// build.sh passes strict=true for real builds, which turns going over
// `max-pages` into an error. Previews and `--watch` leave it off and mark the
// extra pages instead, so you can see what to cut.
#let strict = sys.inputs.at("strict", default: "false") == "true"

// An item is shown unless its `id` is in the version's `exclude` list, it has
// `hide: true`, or it has `topics` and none of them are selected by the
// current version. Items without topics always show.
#let included(it) = {
  if type(it) != dictionary { return true }
  if it.at("id", default: none) in version-exclude { return false }
  if it.at("hide", default: false) { return false }
  let topics = it.at("topics", default: ())
  version-topics == "all" or topics.len() == 0 or topics.any(t => t in version-topics)
}
#let visible(items) = items.filter(included)

// An item's text for this version: the first of its `variants` (in the order
// written) whose topic the version selects, otherwise its plain `text`.
// Versions with `topics: all` always get the plain text.
#let text-of(item) = {
  if type(item) == str { return item }
  if version-topics != "all" {
    for (topic, wording) in item.at("variants", default: (:)) {
      if topic in version-topics { return wording }
    }
  }
  item.at("text", default: "")
}

// ---- Style knobs ----
#let body-font = "EB Garamond"
#let body-size = 12.25pt // EB Garamond runs narrow, so slightly over 12pt
#let name-size = 28pt
#let contact-size = body-size // shrinks to fit if the contact line is ever too wide
#let rule-stroke = 0.75pt
#let line-gap = 0.42em  // space between lines and between bullets
#let section-gap = 12pt // space above each section heading
#let entry-gap = 9pt    // space between entries in a section

#set document(title: data.name + " Resume", author: data.name)
#set page(
  paper: "us-letter",
  margin: (x: 0.6in, y: 0.4in),
  // Pages past the version's `max-pages` get a red notice in the top margin.
  background: context if max-pages != none and here().page() > max-pages {
    place(top + center, dy: 0.12in, text(fill: red, size: 9pt, font: "EB Garamond", weight: "bold")[
      Over the #max-pages\-page limit for version "#version-name"
    ])
  },
)
#set text(font: body-font, size: body-size, lang: "en")
#set par(leading: line-gap, spacing: line-gap)
// EB Garamond's italic is wider than its roman; shrink it to keep italic
// lines compact.
#show emph: set text(size: 0.91em)
#set list(marker: [•], indent: 0.1in, body-indent: 0.15in, spacing: line-gap)

// ---- Helpers ----

// Straight quotes become curly ones: opening after a space, bracket, dash or
// slash (or at the start), closing everywhere else, so apostrophes come out
// right too.
#let curly(s) = {
  s
    .replace(regex("(^|[\\s(\\[{/–—-])\""), m => m.captures.first() + "“")
    .replace("\"", "”")
    .replace(regex("(^|[\\s(\\[{/–—-])'"), m => m.captures.first() + "‘")
    .replace("'", "’")
}

// Text from the YAML as it goes on the page: *asterisks* make bold, \* is a
// literal asterisk, and quotes are curled. A * with a space after it (or
// before a closing one) isn't markup, so "a * b" stays as written.
#let rich(s) = {
  if s == none { return none }
  let s = curly(s)
  let out = []
  let pos = 0
  for m in s.matches(regex("\\\\\\*|\\*([^\\s*](?:[^*]*[^\\s*\\\\])?)\\*")) {
    out += s.slice(pos, m.start)
    out += if m.text == "\\*" { "*" } else { strong(m.captures.first()) }
    pos = m.end
  }
  out + s.slice(pos)
}

// The visible items of a list (each a string or `{ text, topics }`), joined
// with commas.
#let join-items(items) = rich(visible(items).map(text-of).join(", "))

// A bullet: plain text, or a bold `label` followed by text or by a
// comma-separated list of `items`.
#let labeled(item) = {
  if type(item) == str { return rich(item) }
  let body = if "items" in item { join-items(item.items) } else { rich(text-of(item)) }
  if "label" in item [#strong(rich(item.label)) #body] else { body }
}

// One line with content on the left and right edges.
#let split-line(lhs, rhs) = grid(
  columns: (1fr, auto),
  column-gutter: 1em,
  lhs, align(right, rhs),
)

// A full-width block with a rule under it.
#let underlined(body) = block(
  width: 100%,
  stroke: (bottom: rule-stroke),
  inset: (bottom: 3pt),
  body,
)

// ---- Header ----
// The name, then every contact on one line separated by bars, all centered.
#let contact-item(c) = {
  let body = rich(text-of(c))
  if "link" in c { link(c.link, body) } else { body }
}
#let contact-line(size) = text(
  size: size,
  visible(data.contact).map(contact-item).join[#h(0.55em)|#h(0.55em)],
)

#underlined(align(center, {
  text(size: name-size, weight: "bold", data.name)
  v(-3pt)
  // One line always: if the contacts are ever too wide for the page, they
  // shrink just enough to fit instead of wrapping. The padding keeps letters
  // like g and y clear of the rule below.
  pad(bottom: 2pt, layout(region => {
    let width = measure(contact-line(contact-size)).width
    let size = if width <= region.width { contact-size } else { contact-size * (region.width / width) * 0.99 }
    contact-line(size)
  }))
}))

// ---- Body ----
#let section-heading(title) = {
  // Sticky, so a heading is never left alone at the bottom of a page.
  block(above: section-gap, below: 4pt, sticky: true, underlined(upper(strong(rich(title)))))
}

// An entry is laid out the same way in every section:
//   Name (note)                         Location
//   Role                                   Dates   (one line per role)
//   Stack: ...
//   • bullets
// An entry with dates but no role shows its dates on the first line instead.
// The first entry in a section sits right under the heading (`first: true`).
#let entry(e, first: false) = block(above: if first { 0pt } else { entry-gap }, below: 0pt, breakable: true, {
  // A single `role` + `dates` is shorthand for one-item `roles`.
  let roles = if "roles" in e { visible(e.roles) } else if "role" in e {
    ((role: e.role, dates: e.at("dates", default: none)),)
  } else { () }

  // The heading lines are kept on the same page as the first bullet.
  if "name" in e or roles.len() > 0 or "stack" in e { block(sticky: true, breakable: false, below: line-gap, {
    if "name" in e {
      let name = strong(rich(e.name))
      if "note" in e { name += [ #emph(rich(e.note))] }
      let right = ()
      if "location" in e { right.push(emph(rich(e.location))) }
      if "dates" in e and roles.len() == 0 { right.push(rich(e.dates)) }
      split-line(name, right.join[, ])
    }
    for role in roles { split-line(emph(rich(role.role)), rich(role.at("dates", default: none))) }
    if "stack" in e { par[#emph[Stack:] #join-items(e.stack)] }
  }) }

  let bullets = visible(e.at("bullets", default: ()))
  if bullets.len() > 0 { list(..bullets.map(labeled)) }
})

// A version can reorder or drop sections by listing their titles (checked in
// checks.typ). A listed section that's hidden or filtered out is skipped.
#let sections = visible(data.sections)
#if "sections" in version {
  sections = version.sections.map(t => sections.find(s => s.title == t)).filter(s => s != none)
}

#for section in sections {
  let entries = visible(section.entries)
  if entries.len() > 0 {
    section-heading(section.title)
    for (i, e) in entries.enumerate() { entry(e, first: i == 0) }
  }
}

#if max-pages != none and strict {
  context {
    let pages = counter(page).final().first()
    assert(
      pages <= max-pages,
      message: "version '" + version-name + "' is " + str(pages) + " pages, over its max-pages of " + str(max-pages)
        + " (preview it with ./scripts/build.sh --watch " + version-name + " to see what spills over)",
    )
  }
}
