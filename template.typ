// Resume layout. All content lives in content.yaml and the list of
// tailored versions in versions.yaml; this file only controls how it looks.
// Build with ./build.sh (see README), or directly:
//   typst compile template.typ --input version=robotics

#import "checks.typ": check-content, check-versions

#let data = yaml("content.yaml")
#let config = yaml("versions.yaml")
#check-content(data)
#check-versions(config, data)

// ---- Version selection ----
#let version-name = sys.inputs.at("version", default: config.default)
#assert(
  version-name in config.versions,
  message: "unknown version '" + version-name + "', expected one of: " + config.versions.keys().join(", "),
)
#let version = config.versions.at(version-name)
#let version-topics = version.at("topics", default: "all")

// An item is shown unless it has `hide: true`, or it has `topics` and none of
// them are selected by the current version. Items without topics always show.
#let included(it) = {
  if type(it) != dictionary { return true }
  if it.at("hide", default: false) { return false }
  let topics = it.at("topics", default: ())
  version-topics == "all" or topics.len() == 0 or topics.any(t => t in version-topics)
}
#let visible(items) = items.filter(included)

// ---- Style knobs ----
// EB Garamond is kept in fonts/ so every machine renders the same PDF.
#let body-font = "EB Garamond"
#let body-size = 12.25pt // EB Garamond runs narrow; this matches Word's 12pt Garamond
#let name-size = 28pt
#let contact-size = 13pt
#let rule-stroke = 0.75pt
#let section-gap = 12pt // space above each section heading
#let entry-gap = 6pt    // space between entries in a section

#set document(title: data.name + " Resume", author: data.name)
#set page(paper: "us-letter", margin: (x: 0.6in, y: 0.4in))
#set text(font: body-font, size: body-size, lang: "en")
#set par(leading: 0.42em, spacing: 0.42em)
// EB Garamond's italic is wider than its roman; shrink it to keep the
// compact italic lines of the original Word version.
#show emph: set text(size: 0.91em)
#set list(marker: [•], indent: 0.1in, body-indent: 0.15in, spacing: 0.45em)

// ---- Helpers ----

// The visible items of a list (each a string or `{ text, topics }`), joined
// with commas.
#let join-items(items) = visible(items).map(i => if type(i) == str { i } else { i.text }).join(", ")

// A bold lead-in followed by plain text, or by a comma-separated list of
// `items`. No space is added when the text starts with punctuation, so
// "GPA: 3.68/4.0" + "; Dean's List" reads right.
#let labeled(item) = {
  if type(item) == str { return item }
  let text-part = item.at("text", default: "")
  if "items" in item { text-part = join-items(item.items) }
  let gap = if text-part.len() > 0 and text-part.first() in (";", ",", ".") { "" } else { " " }
  if "label" in item [*#item.label*#gap]
  text-part
}

// One line with content on the left and right edges.
#let split-line(lhs, rhs) = grid(
  columns: (1fr, auto),
  column-gutter: 1em,
  lhs, align(right, rhs),
)

// A full-width block with a rule under it, like Word's paragraph bottom border.
#let underlined(body) = block(
  width: 100%,
  stroke: (bottom: rule-stroke),
  inset: (bottom: 3pt),
  body,
)

// ---- Header ----
// A ❖ drawn from four small diamonds, so it doesn't depend on a symbol font.
#let contact-icon = {
  let d = 0.27em
  let diamond = polygon(fill: black, (d / 2, 0pt), (d, d / 2), (d / 2, d), (0pt, d / 2))
  box(width: 2 * d + 0.06em, height: 2 * d + 0.06em, baseline: 0.05em, {
    place(dx: d / 2 + 0.03em, dy: 0pt, diamond)
    place(dx: 0pt, dy: d / 2 + 0.03em, diamond)
    place(dx: d + 0.06em, dy: d / 2 + 0.03em, diamond)
    place(dx: d / 2 + 0.03em, dy: d + 0.06em, diamond)
  })
}
#let contact-item(c) = {
  contact-icon
  h(0.3em)
  if "link" in c { link(c.link, c.text) } else { c.text }
}

#underlined({
  text(size: name-size, weight: "bold", data.name)
  v(-4pt)
  text(size: contact-size, grid(
    columns: (3.1875in, 1fr),
    row-gutter: 0.45em,
    ..visible(data.contact).map(contact-item),
  ))
})

// ---- Body ----
#let section-heading(title) = {
  block(above: section-gap, below: 4pt, underlined(upper(strong(title))))
}

// An entry is laid out the same way in every section:
//   Name (note)                         Location
//   Role                                   Dates   (one line per role)
//   Stack: ...
//   • bullets
// An entry with dates but no role shows its dates on the first line instead.
#let entry(e) = block(above: entry-gap, below: 0pt, breakable: true, {
  // A single `role` + `dates` is shorthand for one-item `roles`.
  let roles = if "roles" in e { visible(e.roles) } else if "role" in e {
    ((role: e.role, dates: e.at("dates", default: none)),)
  } else { () }

  if "name" in e {
    let name = strong(e.name)
    if "note" in e { name += [ #emph(e.note)] }
    let right = ()
    if "location" in e { right.push(emph(e.location)) }
    if "dates" in e and roles.len() == 0 { right.push(e.dates) }
    split-line(name, right.join[, ])
  }
  for role in roles { split-line(emph(role.role), role.at("dates", default: none)) }
  if "stack" in e { par[#emph[Stack:] #join-items(e.stack)] }

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
    for e in entries { entry(e) }
  }
}
