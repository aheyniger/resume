// Resume layout. All content lives in resume-info.yaml; this file only
// controls how it looks. Build with: typst compile resume.typ

#let data = yaml("resume-info.yaml")

// ---- Style knobs ----
#let body-font = "Garamond"
#let body-size = 12pt
#let name-size = 28pt
#let contact-size = 13pt
#let rule-stroke = 0.75pt
#let section-gap = 12pt // space above each section heading
#let entry-gap = 6pt    // space between entries in a section

#set document(title: data.name + " Resume", author: data.name)
#set page(paper: "us-letter", margin: (x: 0.6in, y: 0.4in))
#set text(font: body-font, size: body-size, lang: "en")
#set par(leading: 0.45em, spacing: 0.45em)
#set list(marker: [•], indent: 0.1in, body-indent: 0.15in, spacing: 0.45em)

// ---- Helpers ----
#let visible(items) = items.filter(it => type(it) != dictionary or not it.at("hide", default: false))

// A bold lead-in followed by plain text. No space is added when the text
// starts with punctuation, so "GPA: 3.68/4.0" + "; Dean's List" reads right.
#let labeled(item) = {
  if type(item) == str { return item }
  let text-part = item.at("text", default: "")
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
#let contact-icon = text(font: "Segoe UI Symbol", size: 0.8em, baseline: -0.05em)[❖]
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

#let role-line(role) = {
  let right = if "subtitle-bold" in role { strong(role.at("subtitle-bold")) } else { emph(role.at("subtitle-right", default: "")) }
  split-line(emph(role.at("subtitle", default: "")), right)
}

#let entry(e) = block(above: entry-gap, below: 0pt, breakable: true, {
  if "title" in e {
    let title = strong(e.title)
    if "title-note" in e { title += [ #emph(e.at("title-note"))] }
    let right = if "right-italic" in e { emph(e.at("right-italic")) } else { strong(e.at("right", default: "")) }
    split-line(title, right)
  }
  let roles = e.at("roles", default: if "subtitle" in e or "subtitle-right" in e { (e,) } else { () })
  for role in roles { role-line(role) }
  for d in visible(e.at("details", default: ())) { par(labeled(d)) }
  let bullets = visible(e.at("bullets", default: ()))
  if bullets.len() > 0 { list(..bullets.map(labeled)) }
})

#for section in visible(data.sections) {
  section-heading(section.title)
  for e in visible(section.entries) { entry(e) }
}
