// Checks on content.yaml and versions.yaml, run by template.typ before
// rendering. Without these, a misspelled field or topic would silently drop
// text from the PDF; with them the build stops and says where the problem is.

#let fail(file, path, message) = assert(false, message: file + ", " + path + ": " + message)

// Fields every item may have, on top of its own.
#let common-fields = ("hide", "topics", "id")

// The fields each kind of item may have. `variants` (other wordings of
// `text`, by topic) is allowed wherever `text` is.
#let entry-fields = ("name", "note", "location", "role", "dates", "roles", "stack", "bullets")
#let role-fields = ("role", "dates")
#let labeled-fields = ("label", "text", "variants", "items")
#let list-item-fields = ("text", "variants")
#let contact-fields = ("text", "variants", "link")

#let check-fields(file, path, obj, allowed) = {
  if type(obj) != dictionary {
    fail(file, path, "expected a set of fields, got " + repr(obj))
  }
  for key in obj.keys() {
    if key not in allowed {
      fail(file, path, "unknown field '" + key + "' (allowed: " + allowed.join(", ") + ")")
    }
  }
}

#let check-type(file, path, obj, key, expected, description) = {
  if key in obj and type(obj.at(key)) != expected {
    fail(file, path, "'" + key + "' must be " + description + ", got " + repr(obj.at(key)))
  }
}

#let check-required(file, path, obj, key) = {
  if key not in obj { fail(file, path, "missing required field '" + key + "'") }
}

#let check-list-of-strings(file, path, obj, key) = {
  check-type(file, path, obj, key, array, "a list, e.g. [robotics]")
  for value in obj.at(key, default: ()) {
    if type(value) != str { fail(file, path, "'" + key + "' entries must be text, got " + repr(value)) }
  }
}

// Checks an item's own fields plus the common ones and `variants`.
#let check-item(path, obj, fields) = {
  let file = "content.yaml"
  check-fields(file, path, obj, fields + common-fields)
  check-type(file, path, obj, "hide", bool, "true or false")
  check-type(file, path, obj, "id", str, "a single word")
  check-list-of-strings(file, path, obj, "topics")
  if "variants" in obj {
    if "text" not in obj { fail(file, path, "has 'variants' but no 'text' to fall back on") }
    check-type(file, path, obj, "variants", dictionary, "a set of `topic: wording` lines")
    for (topic, wording) in obj.variants {
      if type(wording) != str {
        fail(file, path, "variant '" + topic + "' must be text, got " + repr(wording))
      }
    }
  }
}

// A list of items, each plain text or `{ text, topics, hide, ... }`.
#let check-items(path, items) = {
  if type(items) != array { fail("content.yaml", path, "must be a list, got " + repr(items)) }
  for (i, sub) in items.enumerate() {
    let sub-path = path + " > item " + str(i + 1)
    if type(sub) != str {
      check-item(sub-path, sub, list-item-fields)
      check-required("content.yaml", sub-path, sub, "text")
    }
  }
}

// Everything `pick` returns for each set of fields anywhere inside `value`,
// e.g. every `id` in the content.
#let collect(value, pick) = {
  let found = ()
  if type(value) == dictionary {
    found += pick(value)
    for v in value.values() { found += collect(v, pick) }
  } else if type(value) == array {
    for v in value { found += collect(v, pick) }
  }
  found
}

#let content-ids(data) = collect(data, d => if "id" in d { (d.id,) } else { () })

// Every topic used anywhere in the content, as `topics` or as a variant.
#let content-topics(data) = collect(data, d => {
  let found = d.at("topics", default: ())
  if "variants" in d { found += d.variants.keys() }
  found
}).dedup()

// The start of an item's text, to say which item an error is about.
#let preview(item) = {
  let chars = item.text.clusters()
  "\"" + chars.slice(0, calc.min(chars.len(), 40)).join() + if chars.len() > 40 { "...\"" } else { "\"" }
}

// A bullet: plain text, or a set of fields.
#let check-labeled(path, item) = {
  if type(item) == str { return }
  check-item(path, item, labeled-fields)
  if "text" not in item and "items" not in item {
    fail("content.yaml", path, "needs 'text' or 'items'")
  }
  if "items" in item { check-items(path, item.items) }
}

#let check-content(data) = {
  let file = "content.yaml"
  check-fields(file, "top level", data, ("name", "contact", "sections"))
  check-required(file, "top level", data, "name")
  check-required(file, "top level", data, "sections")

  // Locations in error messages use titles where there are any, and count
  // from 1 otherwise, e.g. "Skills > entry 1 > bullet 2 > item 6".
  for (i, item) in data.at("contact", default: ()).enumerate() {
    let path = "contact " + str(i + 1)
    check-item(path, item, contact-fields)
    check-required(file, path, item, "text")
  }

  for (i, section) in data.sections.enumerate() {
    let path = section.at("title", default: "section " + str(i + 1))
    check-item(path, section, ("title", "entries"))
    check-required(file, path, section, "title")
    check-required(file, path, section, "entries")

    for (j, entry) in section.entries.enumerate() {
      let entry-path = path + " > " + entry.at("name", default: "entry " + str(j + 1))
      check-item(entry-path, entry, entry-fields)
      if "roles" in entry {
        for key in ("role", "dates") {
          if key in entry {
            fail(file, entry-path, "has both 'roles' and '" + key + "'; put each role's dates inside 'roles'")
          }
        }
      }
      for (k, role) in entry.at("roles", default: ()).enumerate() {
        let role-path = entry-path + " > role " + str(k + 1)
        check-item(role-path, role, role-fields)
        check-required(file, role-path, role, "role")
      }
      if "stack" in entry { check-items(entry-path + " > stack", entry.stack) }
      for (k, item) in entry.at("bullets", default: ()).enumerate() {
        check-labeled(entry-path + " > bullet " + str(k + 1), item)
      }
    }
  }

  let ids = content-ids(data)
  for id in ids.dedup() {
    if ids.filter(i => i == id).len() > 1 { fail(file, "id '" + id + "'", "is used more than once") }
  }
}

#let check-versions(config, data) = {
  let file = "versions.yaml"
  check-fields(file, "top level", config, ("filename", "default", "versions"))
  for key in ("filename", "default", "versions") { check-required(file, "top level", config, key) }
  if config.default not in config.versions {
    fail(file, "default", "'" + config.default + "' is not one of the versions below")
  }

  let known-topics = content-topics(data)
  let known-sections = data.sections.map(s => s.title)
  let known-ids = content-ids(data)

  for (name, version) in config.versions.pairs() {
    let path = "versions > " + name
    check-fields(file, path, version, ("topics", "exclude", "sections", "max-pages", "build", "publish"))
    check-type(file, path, version, "max-pages", int, "a whole number")
    if version.at("max-pages", default: 1) < 1 { fail(file, path, "'max-pages' must be at least 1") }
    check-type(file, path, version, "build", bool, "true or false")
    check-type(file, path, version, "publish", bool, "true or false")
    if version.at("build", default: true) == false and version.at("publish", default: false) == true {
      fail(file, path, "has 'build: false' and 'publish: true'; a version that isn't built can't be published")
    }

    check-list-of-strings(file, path, version, "exclude")
    for id in version.at("exclude", default: ()) {
      if id not in known-ids {
        fail(file, path, "excluded id '" + id + "' isn't on anything in content.yaml (ids: " + known-ids.join(", ") + ")")
      }
    }

    let topics = version.at("topics", default: "all")
    if topics != "all" {
      check-list-of-strings(file, path, version, "topics")
      for topic in topics {
        if topic not in known-topics {
          fail(file, path, "topic '" + topic + "' isn't used anywhere in content.yaml (used topics: " + known-topics.join(", ") + ")")
        }
      }
    }

    check-list-of-strings(file, path, version, "sections")
    for title in version.at("sections", default: ()) {
      if title not in known-sections {
        fail(file, path, "section '" + title + "' doesn't exist (sections: " + known-sections.join(", ") + ")")
      }
    }
  }

  // A variant for a topic no version selects could never be shown, so it's
  // most likely a typo.
  let selected = config.versions.values().map(v => v.at("topics", default: "all")).filter(t => t != "all").flatten()
  for item in collect(data, d => if "variants" in d { (d,) } else { () }) {
    for topic in item.variants.keys() {
      if topic not in selected {
        fail("content.yaml", "variant of " + preview(item), "topic '" + topic + "' isn't selected by any version in versions.yaml")
      }
    }
  }
}
