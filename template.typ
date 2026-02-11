// ============================================================================
// TYPST RESUME TEMPLATE - Professional, ATS-Friendly, YAML-Driven
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

#let as_array(items) = {
  if items == none {
    ()
  } else if type(items) == array {
    items
  } else {
    (items,)
  }
}

#let filter_by_variant(items, variant) = {
  let entries = as_array(items)
  if variant == "long" {
    return entries
  }
  entries.filter(item => {
    if type(item) == dictionary {
      item.at("include_short", default: true) == true
    } else {
      true
    }
  })
}

#let month_name(n, display: "short") = {
  n = int(n)
  let months = (
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  )
  if n >= 1 and n <= 12 {
    let month = months.at(n - 1)
    if display == "short" {
      if n == 9 { "Sept" } else { month.slice(0, 3) }
    } else { month }
  } else {
    none
  }
}

#let numeric_pattern = regex("^[+-]?[0-9]+(\\.[0-9]+)?$")
#let year_pattern = regex("^[0-9]{4}$")
#let iso_date_pattern = regex("^[0-9]{4}-[0-9]{2}(-[0-9]{2})?$")
#let hex_color_pattern = regex("^#[0-9a-fA-F]{6}$")
#let markdown_link_pattern = regex("\\[([^\\]]+)\\]\\(([^\\)]+)\\)")

#let parse_dimension(value, default: none) = {
  if value == none { return default }
  if type(value) == length { return value }

  let s = str(value).trim()
  if s == "" { return default }

  let units = (
    (suffix: "pt", scale: 1pt),
    (suffix: "em", scale: 1em),
    (suffix: "in", scale: 1in),
    (suffix: "cm", scale: 1cm),
    (suffix: "mm", scale: 1mm),
  )

  for u in units {
    if s.ends-with(u.suffix) {
      let num = s.slice(0, s.len() - u.suffix.len()).trim()
      if num.matches(numeric_pattern).len() > 0 {
        return float(num) * u.scale
      }
      return default
    }
  }

  if s.matches(numeric_pattern).len() > 0 {
    return float(s) * 1pt
  }

  default
}

#let parse_color(value, default: rgb("#555555")) = {
  if value == none { return default }
  if type(value) == color { return value }

  let s = str(value).trim()
  if s.matches(hex_color_pattern).len() > 0 {
    return rgb(s)
  }

  default
}

#let maybe_link(url, body, config) = {
  let link_color = parse_color(config.at("link_color", default: none), default: rgb("#1C398D"))
  if url == none or str(url).trim() == "" {
    return body
  }
  if config.at("enable_links", default: true) {
    link(str(url))[#text(fill: link_color)[#body]]
  } else {
    body
  }
}

#let resolve_paper_size(value, default: "us-letter") = {
  if value == none { return default }
  let s = lower(str(value).trim()).replace("_", "-")
  if s == "a4" {
    "a4"
  } else if s == "letter" or s == "us-letter" {
    "us-letter"
  } else {
    default
  }
}

#let render_markup(value) = {
  if value == none { return [] }
  if type(value) == content { return value }
  let s = str(value)
  let star_count = s.matches(regex("\\*")).len()
  let underscore_count = s.matches(regex("_")).len()
  let has_markers = star_count > 0 or underscore_count > 0

  if not has_markers { return s }
  if calc.rem(star_count, 2) != 0 or calc.rem(underscore_count, 2) != 0 { return s }

  eval(s, mode: "markup")
}

#let render_rich(value, config) = {
  if value == none { return [] }
  if type(value) == content { return value }

  if type(value) == array {
    let parts = ()
    for item in value {
      if item != none {
        parts.push(render_rich(item, config))
      }
    }
    return parts.join([ ])
  }

  if type(value) == dictionary {
    let markdown_keys = (
      "markdown",
      "content",
      "text",
      "label",
      "title",
      "name",
      "value",
      "summary",
      "description",
      "notes",
    )
    for key in markdown_keys {
      if key in value {
        let nested = value.at(key, default: none)
        if nested != none and str(nested).trim() != "" {
          return render_rich(nested, config)
        }
      }
    }
    return []
  }

  let s = str(value)
  let matches = s.matches(markdown_link_pattern)
  if matches.len() == 0 {
    return render_markup(s)
  }

  let strip_links = (
    not config.at("enable_links", default: true)
    and config.at("strip_link_labels_when_links_disabled", default: false)
  )

  let parts = ()
  let cursor = 0
  for m in matches {
    if m.start > cursor {
      parts.push(render_markup(s.slice(cursor, m.start)))
    }
    let label = m.captures.at(0)
    let url = m.captures.at(1)
    if not strip_links {
      parts.push(maybe_link(url, render_markup(label), config))
    }
    cursor = m.end
  }
  if cursor < s.len() {
    parts.push(render_markup(s.slice(cursor)))
  }
  parts.join()
}

#let non_empty(value) = {
  if value == none { return false }
  if type(value) == content { return true }
  if type(value) == array { return value.len() > 0 }
  if type(value) == dictionary { return value.keys().len() > 0 }
  str(value).trim() != ""
}

#let first_present(item, keys) = {
  if type(item) != dictionary { return none }
  for key in keys {
    if key in item and non_empty(item.at(key, default: none)) {
      return item.at(key)
    }
  }
  none
}

#let normalize_key(value) = {
  if value == none { return "" }
  lower(str(value).trim()).replace("-", "_").replace(" ", "_")
}

#let titleize_section_key(key) = {
  let cleaned = str(key).replace("-", " ").replace("_", " ").trim()
  if cleaned == "" { return "Section" }

  let words = ()
  for word in cleaned.split(" ") {
    let w = word.trim()
    if w != "" {
      words.push(upper(w.slice(0, 1)) + w.slice(1))
    }
  }
  words.join(" ")
}

#let resolve_section_title(config, section_key) = {
  let titles = config.at("section_titles_map", default: (:))
  if type(titles) == dictionary and section_key in titles {
    return titles.at(section_key)
  }

  titleize_section_key(section_key)
}

#let parse_date(date_str) = {
  if date_str == none or date_str == "" { return none }
  let s = str(date_str).trim()
  if s == "" { return none }
  let date_lower = lower(s)
  if date_lower == "present" or date_lower == "current" or date_lower == "now" { return "Present" }
  if s.matches(year_pattern).len() > 0 { return s }
  if s.matches(iso_date_pattern).len() > 0 {
    let year = int(s.slice(0, 4))
    let month = int(s.slice(5, 7))
    let month_str = month_name(month, display: "short")
    if month_str != none {
      return month_str + " " + str(year)
    }
  }
  s
}

#let date_range(start_date, end_date, sep: none) = {
  let start = parse_date(start_date)
  let end = parse_date(end_date)
  let separator = if sep != none { sep } else { [ to ] }
  if start != none and end != none {
    [#start #separator #end]
  } else if start != none {
    [#start]
  } else if end != none {
    [#end]
  } else {
    []
  }
}

#let resolve_last_updated(data, config) = {
  let cli_date = if "last_updated" in sys.inputs { str(sys.inputs.at("last_updated")) } else { none }
  if cli_date != none and cli_date.trim() != "" {
    return cli_date.trim()
  }

  let config_date = config.at("last_updated", default: none)
  if config_date != none and str(config_date).trim() != "" {
    return str(config_date).trim()
  }

  let meta = data.at("meta", default: (:))
  let data_date = meta.at("last_updated", default: none)
  if data_date != none and str(data_date).trim() != "" {
    return str(data_date).trim()
  }

  datetime.today().display("[month repr:long] [day], [year]")
}

// ============================================================================
// DESIGN PRIMITIVES
// ============================================================================

#let secondary(config, body) = {
  let c = parse_color(config.at("secondary_color", default: none), default: rgb("#555555"))
  text(fill: c, body)
}

#let lr(left_content, right_content) = {
  grid(
    columns: (1fr, auto),
    column-gutter: 1em,
    align(left + top, left_content),
    align(right + top, right_content),
  )
}

#let highlight_author_name(authors_str, name) = {
  if authors_str == none or name == none { return authors_str }
  let name_str = str(name).trim()
  let auth_str = str(authors_str)
  if auth_str.contains(name_str) {
    let parts = auth_str.split(name_str)
    let result = ()
    for (i, part) in parts.enumerate() {
      if i > 0 {
        result.push(strong(name_str))
      }
      result.push(part)
    }
    result.join()
  } else {
    authors_str
  }
}

#let resolve_profile_label(profile) = {
  if "label" in profile and profile.label != none and str(profile.label).trim() != "" {
    return profile.label
  }
  let network = lower(str(profile.at("network", default: "")).trim())
  let username = str(profile.at("username", default: "")).trim()
  if network == "twitter" or network == "x" {
    return "@" + username
  }
  if network == "linkedin" {
    return "LinkedIn"
  }
  if network.contains("email") {
    return username
  }
  username
}

#let contact_kind_from_network(network) = {
  let n = lower(str(network).trim())
  if n.contains("email") { return "email" }
  if n.contains("linkedin") { return "linkedin" }
  if n.contains("github") { return "github" }
  if n.contains("twitter") or n == "x" { return "twitter" }
  "profile"
}

#let contact_icon(kind, family: "lucide") = {
  let k = lower(str(kind).trim())
  let f = lower(str(family).trim())

  if f == "mdi" {
    if k == "phone" { return [☎] }
    if k == "email" { return [✉] }
    if k == "website" or k == "url" { return [⌂] }
    if k == "linkedin" { return [◫] }
    if k == "github" { return [◇] }
    if k == "twitter" { return [◌] }
    return [◦]
  }

  if f == "phosphor" {
    if k == "phone" { return [☏] }
    if k == "email" { return [✉] }
    if k == "website" or k == "url" { return [⌂] }
    if k == "linkedin" { return [◧] }
    if k == "github" { return [⬡] }
    if k == "twitter" { return [◍] }
    return [•]
  }

  // Default: lucide-like minimal glyph set (unicode-safe fallback)
  if k == "phone" { return [✆] }
  if k == "email" { return [✉] }
  if k == "website" or k == "url" { return [⌁] }
  if k == "linkedin" { return [◩] }
  if k == "github" { return [⬢] }
  if k == "twitter" { return [◌] }
  [•]
}

#let render_contact_entry(kind, label, url, config) = {
  let mode = lower(str(config.at("contact_display_mode", default: "label")).trim())
  let family = config.at("contact_icon_family", default: "lucide")
  let icon_spacing = config.at("contact_icon_spacing", default: 0.18em)
  let icon = contact_icon(kind, family: family)
  let text_label = render_rich(label, config)

  let body = if mode == "icon" {
    icon
  } else if mode == "icon_label" or mode == "icons_labels" {
    [#icon#h(icon_spacing)#text_label]
  } else {
    text_label
  }

  if url != none and str(url).trim() != "" {
    maybe_link(url, body, config)
  } else {
    body
  }
}

#let section_heading(title, config) = {
  v(config.at("section_spacing", default: 1.08em))
  block(width: 100%, above: 0pt, below: 0pt, breakable: false)[
    #set text(
      font: config.at("heading_font", default: "New Computer Modern"),
      size: config.at("section_font_size", default: 1em),
      weight: "bold",
      tracking: config.at("section_heading_tracking", default: 0.01em),
    )
    #if config.at("section_smallcaps", default: false) {
      smallcaps(title)
    } else {
      upper(title)
    }
  ]
  v(config.at("post_section_spacing", default: 0.74em))
}

// ============================================================================
// DOCUMENT SETUP
// ============================================================================

#let apply_settings(config, doc) = {
  let show_page_numbers = config.at("show_page_numbers", default: true)
  set page(
    paper: resolve_paper_size(config.at("paper_size", default: "letter")),
    margin: config.at("margin", default: 0.65in),
    footer: if show_page_numbers {
      context align(center, text(size: 0.85em)[
        #counter(page).display("1") of #counter(page).final().first()
      ])
    } else {
      none
    },
  )
  set text(
    font: config.at("body_font", default: "New Computer Modern"),
    size: config.at("font_size", default: 10pt),
    hyphenate: false,
  )
  set par(
    leading: config.at("line_spacing", default: 0.33em),
    justify: false,
  )
  set list(
    indent: 0.9em,
    spacing: config.at("list_spacing", default: 0.61em),
    marker: [•],
    body-indent: 0.5em,
  )
  doc
}

#let apply_heading_styles(config, doc) = {
  show heading.where(level: 1): it => block(width: 100%)[
    #set text(
      font: config.at("heading_font", default: "New Computer Modern"),
      size: config.at("name_font_size", default: 1.4em),
      weight: "bold",
    )
    #it.body
  ]

  doc
}

// ============================================================================
// HEADER / CONTACT INFORMATION
// ============================================================================

#let render_header(data, config) = {
  let personal = data.at("personal", default: none)
  if personal == none { return }

  let contact_size = config.at("contact_font_size", default: 0.85em)
  let header_rule_color = parse_color(
    config.at("header_rule_color", default: config.at("section_rule_color", default: none)),
    default: rgb("#9F9FA8"),
  )
  let header_rule_thickness = config.at("header_rule_thickness", default: 1pt)
  let last_updated = resolve_last_updated(data, config)
  let show_last_updated = config.at("show_last_updated", default: true)

  if show_last_updated and last_updated != none {
    place(top + right, dx: 0pt, dy: -config.at("margin", default: 0.65in) + 0.25in)[
      #set text(size: config.at("last_updated_font_size", default: 0.68em))
      #secondary(config, [
        #config.at("last_updated_label", default: "Last Updated on")
        #h(0.25em)
        #last_updated
      ])
    ]
  }

  align(center)[
    = #render_rich(personal.name, config)

    #v(-0.2em)

    #let show_titles = config.at("show_titles", default: true)
    #if show_titles {
      let titles = as_array(personal.at("titles", default: ()))
      if titles.len() > 0 {
        block(above: 0pt, below: 0.2em)[
          #set text(size: 0.9em, weight: "regular", style: "italic")
          #{
            let title_items = ()
            for title in titles {
              title_items.push(render_rich(title, config))
            }
            title_items.join([ | ])
          }
        ]
      }
    }

    #if config.at("show_location", default: false) {
      if "location" in personal and personal.location != none {
        let loc = personal.location
        let parts = ()
        if "city" in loc and loc.city != none and loc.city != "" { parts.push(render_rich(loc.city, config)) }
        if "region" in loc and loc.region != none and loc.region != "" { parts.push(render_rich(loc.region, config)) }
        if "country" in loc and loc.country != none and loc.country != "" { parts.push(render_rich(loc.country, config)) }
        if parts.len() > 0 {
          block(above: 0pt, below: 0pt)[
            #set text(size: 0.8em)
            #secondary(config, parts.join(", "))
          ]
          v(-0.1em)
        }
      }
    }

    #block(above: 0pt, below: 0pt)[
      #set text(size: contact_size)
      #let contacts = ()

      #if config.at("show_phone", default: true) {
        if "phone" in personal and personal.phone != none {
          contacts.push(render_contact_entry("phone", personal.phone, none, config))
        }
      }

      #if "email" in personal and personal.email != none {
        contacts.push(render_contact_entry("email", personal.email, "mailto:" + personal.email, config))
      }

      #let profiles = as_array(personal.at("profiles", default: ()))
      #let url_label = config.at("url_display_label", default: none)

      #for profile in profiles {
        let network = lower(str(profile.at("network", default: "")).trim())
        if network.contains("email") {
          let label = resolve_profile_label(profile)
          if "url" in profile and profile.url != none {
            contacts.push(render_contact_entry("email", label, profile.url, config))
          } else {
            contacts.push(render_contact_entry("email", label, none, config))
          }
        }
      }

      #if "url" in personal and personal.url != none {
        let display = if url_label != none { url_label } else {
          personal.url.split("//").at(-1).trim("/", at: end)
        }
        contacts.push(render_contact_entry("website", display, personal.url, config))
      }

      #for profile in profiles {
        let network = lower(str(profile.at("network", default: "")).trim())
        if not network.contains("email") {
          let label = resolve_profile_label(profile)
          let kind = contact_kind_from_network(network)
          if "url" in profile and profile.url != none {
            contacts.push(render_contact_entry(kind, label, profile.url, config))
          } else {
            contacts.push(render_contact_entry(kind, label, none, config))
          }
        }
      }

      #let sep_gap = config.at("contact_separator_spacing", default: 0.3em)
      #contacts.join([ #h(sep_gap) | #h(sep_gap) ])
    ]
  ]

  v(config.at("header_rule_top_spacing", default: 0.42em))
  line(length: 100%, stroke: header_rule_thickness + header_rule_color)
  v(config.at("header_bottom_spacing", default: 0.3em))
}

// ============================================================================
// INTERESTS / SUMMARY SECTION
// ============================================================================

#let render_interests_summary(data, config) = {
  if not config.at("show_interests_summary", default: false) { return }
  if "interests_summary" in data and data.interests_summary != none {
    section_heading(resolve_section_title(config, "interests_summary"), config)
    block(above: 0pt, below: 0pt)[
      #set text(size: config.at("summary_font_size", default: 1.0em))
      #render_rich(data.interests_summary, config)
    ]
  }
}

// ============================================================================
// WORK EXPERIENCE SECTION
// ============================================================================

#let render_work(data, config) = {
  let work_entries = as_array(data.at("work", default: ()))
  if work_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let work_items = filter_by_variant(work_entries, variant)
  if work_items.len() == 0 { return }

  let entry_spacing = config.at("work_entry_spacing", default: config.at("entry_spacing", default: 0.5em))
  let entry_inner_spacing = config.at(
    "work_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.48em),
  )
  let position_spacing = config.at("work_position_spacing", default: entry_inner_spacing)
  let bullet_top_spacing = config.at("work_bullet_spacing", default: entry_inner_spacing)
  let work_list_spacing = config.at("work_list_spacing", default: config.at("list_spacing", default: 0.61em))
  let work_highlight_indent = config.at("work_highlight_indent", default: 1.2em)

  section_heading(resolve_section_title(config, "work"), config)
  block(above: 0pt, below: 0pt)[
    #for (i, work) in work_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #{
          let positions = if "positions" in work and work.positions != none {
            filter_by_variant(as_array(work.positions), variant)
          } else {
            (work,)
          }

          for (j, position) in positions.enumerate() {
            block(width: 100%, above: if j == 0 { 0pt } else { position_spacing }, below: 0pt, breakable: true)[
              #{
                let work_name = work.at("name", default: "Organization")
                let org_content = if "url" in work and work.url != none {
                  strong(maybe_link(work.url, render_rich(work_name, config), config))
                } else {
                  strong(render_rich(work_name, config))
                }

                let role = position.at("name", default: none)
                let work_location = work.at("location", default: position.at("location", default: none))
                let role_with_location = if role != none and str(role).trim() != "" and work_location != none and str(work_location).trim() != "" {
                  [#render_rich(role, config) (#render_rich(work_location, config))]
                } else if role != none and str(role).trim() != "" {
                  render_rich(role, config)
                } else {
                  none
                }
                let left_line = if role != none and str(role).trim() != "" {
                  [#org_content | #role_with_location]
                } else {
                  [#org_content]
                }

                let end_date = position.at("endDate", default: none)
                let end_formatted = if end_date != none and lower(str(end_date)) == "present" {
                  [_present_]
                } else {
                  none
                }

                lr(
                  left_line,
                  if end_formatted != none {
                    date_range(position.at("startDate", default: none), none)
                    [ to ]
                    end_formatted
                  } else {
                    date_range(position.at("startDate", default: none), position.at("endDate", default: none))
                  },
                )
              }

              #let position_content = as_array(position.at("content", default: ()))
              #if position_content.len() > 0 {
                v(bullet_top_spacing)
                block(width: 100%, above: 0pt, below: 0pt, inset: (left: work_highlight_indent), breakable: true)[
                  #for (hi, hl) in position_content.enumerate() {
                    block(width: 100%, above: if hi == 0 { 0pt } else { work_list_spacing }, below: 0pt, breakable: true)[
                      #render_rich(hl, config)
                    ]
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  ]
}

// ============================================================================
// EDUCATION SECTION
// ============================================================================

#let render_education(data, config) = {
  let education_entries = as_array(data.at("education", default: ()))
  if education_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let edu_items = filter_by_variant(education_entries, variant)
  if edu_items.len() == 0 { return }

  let entry_spacing = config.at("education_entry_spacing", default: config.at("entry_spacing", default: 0.5em))
  let entry_inner_spacing = config.at(
    "education_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.48em),
  )
  let education_list_spacing = config.at(
    "education_list_spacing",
    default: config.at("list_spacing", default: 0.61em),
  )
  let education_highlight_indent = config.at("education_highlight_indent", default: 0.95em)

  section_heading(resolve_section_title(config, "education"), config)
  block(above: 0pt, below: 0pt)[
    #for (i, edu) in edu_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #{
          let education_name = edu.at("name", default: "Institution")
          let inst_content = if "url" in edu and edu.url != none {
            strong(maybe_link(edu.url, render_rich(education_name, config), config))
          } else {
            strong(render_rich(education_name, config))
          }
          let loc_parts = ()
          if "location" in edu and edu.location != none and str(edu.location).trim() != "" {
            loc_parts.push(render_rich(edu.location, config))
          }
          let left_label = if loc_parts.len() > 0 {
            [#inst_content, #loc_parts.join(", ")]
          } else {
            inst_content
          }
          lr(
            left_label,
            date_range(edu.at("startDate", default: none), edu.at("endDate", default: none)),
          )
        }

        #{
          let all_honors = as_array(edu.at("honors", default: ()))
          let non_gpa_honors = all_honors.filter(h => not str(h).contains("GPA"))
          let gpa_honors = all_honors.filter(h => str(h).contains("GPA"))

          let degree_parts = ()
          if "studyType" in edu and edu.studyType != none { degree_parts.push(render_rich(edu.studyType, config)) }
          if "area" in edu and edu.area != none { degree_parts.push([ in #render_rich(edu.area, config)]) }

          let lines = ()

          if non_gpa_honors.len() > 0 {
            for honor in non_gpa_honors {
              lines.push(strong(render_rich(honor, config)))
            }
          }

          if degree_parts.len() > 0 {
            let deg_text = degree_parts.join()
            if gpa_honors.len() > 0 {
              deg_text = [#deg_text, #gpa_honors.map(h => render_rich(h, config)).join(", ")]
            }
            lines.push(deg_text)
          }

          let edu_content = as_array(edu.at("content", default: ()))
          for hl in edu_content {
            lines.push(render_rich(hl, config))
          }

          if "thesis" in edu and edu.thesis != none {
            lines.push([#strong[Thesis]: #render_rich(edu.thesis, config)])
          }

          let courses_list = as_array(edu.at("courses", default: ()))
          if courses_list.len() > 0 {
            let courses = ()
            for course in courses_list {
              courses.push(render_rich(course, config))
            }
            lines.push([#strong[Coursework:] #courses.join(", ")])
          }

          block(width: 100%, above: entry_inner_spacing, below: 0pt, inset: (left: education_highlight_indent), breakable: true)[
            #for (idx, line) in lines.enumerate() {
              block(width: 100%, above: if idx == 0 { 0pt } else { education_list_spacing }, below: 0pt, breakable: true)[
                #line
              ]
            }
          ]
        }
      ]
    }
  ]
}

// ============================================================================
// PUBLICATIONS SECTION
// ============================================================================

#let publication_section_key(pub) = {
  if type(pub) != dictionary { return "uncategorized" }

  let explicit = pub.at("section", default: pub.at("group", default: none))
  if non_empty(explicit) {
    return normalize_key(explicit)
  }

  let status = pub.at("status", default: none)
  if non_empty(status) {
    let s = lower(str(status))
    if s.contains("submit") { return "submitted" }
    if s.contains("work") or s.contains("progress") or s.contains("research note") or s.contains("demo") {
      return "works_in_progress"
    }
  }

  if pub.at("publisher", default: none) == none {
    return "works_in_progress"
  }

  "accepted"
}

#let publication_links(pub, config) = {
  let link_parts = ()
  if type(pub) != dictionary { return link_parts }
  let strip_links = (
    not config.at("enable_links", default: true)
    and config.at("strip_link_labels_when_links_disabled", default: false)
  )
  if strip_links { return link_parts }

  let explicit_links = as_array(pub.at("links", default: ()))
  for link_info in explicit_links {
    if type(link_info) == dictionary {
      let label = link_info.at("label", default: none)
      let url = link_info.at("url", default: none)
      if non_empty(label) and non_empty(url) {
        link_parts.push(maybe_link(url, render_rich(label, config), config))
      }
    } else {
      link_parts.push(render_rich(link_info, config))
    }
  }

  if explicit_links.len() == 0 {
    let demo_url = pub.at("demo_url", default: pub.at("demo", default: none))
    let repo_url = pub.at("repo_url", default: pub.at("repo", default: none))
    let demo_label = pub.at("demo_label", default: "Demo")
    let repo_label = pub.at("repo_label", default: "Repo")
    if non_empty(demo_url) {
      link_parts.push(maybe_link(demo_url, render_rich(demo_label, config), config))
    }
    if non_empty(repo_url) {
      link_parts.push(maybe_link(repo_url, render_rich(repo_label, config), config))
    }
  }

  link_parts
}

#let render_publication_item(
  pub,
  idx,
  pub_spacing,
  pub_font_size,
  pub_link_style,
  pub_line_spacing,
  author_name,
  config,
  section_key: "accepted",
  publication_number: none,
) = {
  let number_prefix = if publication_number != none {
    [#publication_number #h(0.22em)]
  } else {
    []
  }

  if type(pub) != dictionary {
    block(width: 100%, above: if idx == 0 { 0pt } else { pub_spacing }, below: 0pt)[
      #set text(size: pub_font_size)
      #set par(leading: pub_line_spacing)
      #number_prefix
      #render_rich(pub, config)
    ]
  } else if "bib_key" in pub {
    let extra_links = publication_links(pub, config)
    let notes = pub.at("notes", default: none)
    block(width: 100%, above: if idx == 0 { 0pt } else { pub_spacing }, below: 0pt)[
      #set text(size: pub_font_size)
      #set par(leading: pub_line_spacing)
      #number_prefix
      #cite(label(pub.bib_key), form: "full")
      #if extra_links.len() > 0 {
        if pub_link_style == "newline" {
          [\ ]
          [[#extra_links.join([ | ])]]
        } else {
          [ [#extra_links.join([ | ])]]
        }
      }
      #if non_empty(notes) {
        [\ #render_rich(notes, config)]
      }
    ]
  } else {
    block(width: 100%, above: if idx == 0 { 0pt } else { pub_spacing }, below: 0pt)[
      #set text(size: pub_font_size)
      #set par(leading: pub_line_spacing)
      #number_prefix
      #{
        let title = first_present(pub, ("content", "title", "name", "label", "text"))
        let title = if title == none { "Untitled" } else { title }
        let has_url = "url" in pub and pub.url != none
        let notes = pub.at("notes", default: pub.at("status", default: none))

        if section_key == "works_in_progress" {
          strong(render_rich(title, config))
          if "authors" in pub and pub.authors != none {
            [. #render_rich(highlight_author_name(pub.authors, author_name), config).]
          }
          let pub_links = publication_links(pub, config)
          if pub_links.len() > 0 {
            [\ ]
            [#pub_links.join([ | ])]
          }
          if non_empty(notes) {
            [\ #render_rich(notes, config)]
          }
        } else if section_key == "submitted" {
          if has_url {
            maybe_link(pub.url, strong(render_rich(title, config) + [.]), config)
          } else {
            strong(render_rich(title, config) + [.])
          }
          if "authors" in pub and pub.authors != none {
            [ #render_rich(highlight_author_name(pub.authors, author_name), config).]
          }
          if non_empty(notes) {
            [ #render_rich(notes, config)]
          }
        } else {
          if has_url {
            maybe_link(pub.url, strong(render_rich(title, config)), config)
          } else {
            strong(render_rich(title, config))
          }
          if "publisher" in pub and pub.publisher != none {
            [. In #emph(render_rich(pub.publisher, config)).]
          }
          if "authors" in pub and pub.authors != none {
            [ #render_rich(highlight_author_name(pub.authors, author_name), config).]
          }
          if non_empty(notes) {
            [ #render_rich(notes, config)]
          }
        }
      }
    ]
  }
}

#let render_publications(data, config) = {
  let publication_entries = as_array(data.at("publications", default: ()))
  if publication_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let pub_items = filter_by_variant(publication_entries, variant)
  if pub_items.len() == 0 { return }

  let pub_spacing = config.at("pub_spacing", default: config.at("list_spacing", default: 0.61em))
  let pub_font_size = config.at("publications_font_size", default: config.at("font_size", default: 10pt))
  let pub_link_style = config.at("publications_link_style", default: "compact")
  let pub_line_spacing = config.at("publications_line_spacing", default: config.at("line_spacing", default: 0.33em))
  let author_name = data.at("personal", default: (:)).at("name", default: none)
  let publication_sections = as_array(config.at("publication_sections", default: ()))
  let show_publication_numbers = config.at("show_publication_numbers", default: false)

  let pub_heading_tighten = config.at("publications_heading_tighten", default: 0pt)

  if publication_sections.len() > 0 {
    for section in publication_sections {
      if type(section) == dictionary {
        let section_key = normalize_key(section.at("key", default: none))
        if section_key != "" {
          let section_items = ()
          for pub in pub_items {
            if publication_section_key(pub) == section_key {
              section_items.push(pub)
            }
          }

          if section_items.len() > 0 {
            let section_title = section.at("title", default: resolve_section_title(config, section_key))
            section_heading(section_title, config)
            v(pub_heading_tighten)
            block(above: 0pt, below: 0pt)[
              #set par(justify: false)
              #for (i, pub) in section_items.enumerate() {
                render_publication_item(
                  pub,
                  i,
                  pub_spacing,
                  pub_font_size,
                  pub_link_style,
                  pub_line_spacing,
                  author_name,
                  config,
                  section_key: section_key,
                  publication_number: if show_publication_numbers { ["[" + str(i + 1) + "]"] } else { none },
                )
              }
            ]
          }
        }
      }
    }

    let remaining_items = ()
    for pub in pub_items {
      let matched_sections = ()
      for section in publication_sections {
        if type(section) == dictionary {
          let section_key = normalize_key(section.at("key", default: none))
          if section_key != "" and publication_section_key(pub) == section_key {
            matched_sections.push(section_key)
          }
        }
      }
      if matched_sections.len() == 0 { remaining_items.push(pub) }
    }

    if remaining_items.len() > 0 {
      section_heading(resolve_section_title(config, "publications"), config)
      v(pub_heading_tighten)
      block(above: 0pt, below: 0pt)[
        #set par(justify: false)
        #for (i, pub) in remaining_items.enumerate() {
          render_publication_item(
            pub,
            i,
            pub_spacing,
            pub_font_size,
            pub_link_style,
            pub_line_spacing,
            author_name,
            config,
            publication_number: if show_publication_numbers { ["[" + str(i + 1) + "]"] } else { none },
          )
        }
      ]
    }
  } else {
    section_heading(resolve_section_title(config, "publications"), config)
    v(pub_heading_tighten)
    block(above: 0pt, below: 0pt)[
      #set par(justify: false)
      #for (i, pub) in pub_items.enumerate() {
        render_publication_item(
          pub,
          i,
          pub_spacing,
          pub_font_size,
          pub_link_style,
          pub_line_spacing,
          author_name,
          config,
          publication_number: if show_publication_numbers { ["[" + str(i + 1) + "]"] } else { none },
        )
      }
    ]
  }
}

// ============================================================================
// PROJECTS SECTION
// ============================================================================

#let render_projects(data, config) = {
  let project_entries = as_array(data.at("projects", default: ()))
  if project_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let project_items = filter_by_variant(project_entries, variant)
  if project_items.len() == 0 { return }

  let entry_spacing = config.at(
    "projects_entry_spacing",
    default: config.at("entry_spacing", default: 0.5em),
  )
  let entry_inner_spacing = config.at(
    "projects_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.48em),
  )

  section_heading(resolve_section_title(config, "projects"), config)
  block(above: 0pt, below: 0pt)[
    #for (i, project) in project_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #if type(project) != dictionary {
          render_rich(project, config)
        } else {
          let project_title = first_present(project, ("content", "title", "name", "label", "text"))
          let project_title = if project_title == none { "Project" } else { project_title }
          [
            #lr(
              {
                if "url" in project and project.url != none {
                  strong(maybe_link(project.url, render_rich(project_title, config), config))
                } else {
                  strong(render_rich(project_title, config))
                }
              },
              secondary(config, date_range(project.at("startDate", default: none), project.at("endDate", default: none))),
            )

            #if "affiliation" in project and project.affiliation != none {
              text(style: "italic")[#render_rich(project.affiliation, config)]
            }

            #let project_content = as_array(project.at("content", default: ()))
            #if project_content.len() > 0 {
              block(width: 100%, above: entry_inner_spacing, below: 0pt, breakable: true)[
                #for highlight in project_content {
                  [- #render_rich(highlight, config)]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}

// ============================================================================
// AWARDS AND HONORS SECTION
// ============================================================================

#let render_awards(data, config) = {
  let award_entries = as_array(data.at("awards", default: ()))
  if award_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let award_items = filter_by_variant(award_entries, variant)
  if award_items.len() == 0 { return }

  let entry_spacing = config.at("awards_entry_spacing", default: config.at("entry_spacing", default: 0.5em))
  let awards_font_size = config.at("awards_font_size", default: config.at("font_size", default: 10pt))

  section_heading(resolve_section_title(config, "awards"), config)
  block(above: 0pt, below: 0pt)[
    #for (i, award) in award_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #set text(size: awards_font_size)
        #{
          if type(award) != dictionary {
            render_rich(award, config)
          } else {
            let title = first_present(award, ("content", "title", "name", "label", "text", "notes"))
            let title = if title == none { "" } else { title }
            let has_url = "url" in award and award.url != none
            let is_flat = award.at("flat", default: false)
            let notes = award.at("notes", default: none)

            let extra_keys = award.keys().filter(
              k => k != "title" and k != "content" and k != "notes" and k != "flat" and k != "include_short"
                and k != "bold_label" and k != "links" and k != "url" and k != "name" and k != "label" and k != "text",
            )
            if is_flat or extra_keys.len() == 0 {
              let bold_label = award.at("bold_label", default: none)
              if bold_label != none and str(title).starts-with(str(bold_label)) {
                let rest = str(title).slice(str(bold_label).len())
                [#strong(bold_label)#rest]
              } else {
                render_rich(title, config)
              }
            } else if has_url {
              strong(maybe_link(award.url, render_rich(title, config), config))
            } else {
              render_rich(title, config)
            }

            let award_links = as_array(award.at("links", default: ()))
            if award_links.len() > 0 {
              [ ]
              for lnk in award_links {
                if type(lnk) == dictionary {
                  if "text" in lnk {
                    render_rich(lnk.text, config)
                  } else if "url" in lnk and "label" in lnk {
                    maybe_link(lnk.url, render_rich(lnk.label, config), config)
                  } else if "label" in lnk {
                    render_rich(lnk.label, config)
                  }
                }
              }
            }

            if non_empty(notes) and str(notes) != str(title) {
              [ #render_rich(notes, config)]
            }
          }
        }
      ]
    }
  ]
}

// ============================================================================
// SKILLS SECTION
// ============================================================================

#let render_skills(data, config) = {
  let skill_entries = as_array(data.at("skills", default: ()))
  if skill_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let skill_items = filter_by_variant(skill_entries, variant)
  if skill_items.len() == 0 { return }

  let skill_spacing = config.at("skill_spacing", default: config.at("list_spacing", default: 0.61em))
  let skills_line_spacing = config.at(
    "skills_line_spacing",
    default: config.at("line_spacing", default: 0.33em),
  )

  section_heading(resolve_section_title(config, "skills"), config)
  block(above: 0pt, below: 0pt)[
    #for (i, skill_group) in skill_items.enumerate() {
      block(above: if i == 0 { 0pt } else { skill_spacing }, below: 0pt)[
        #set par(leading: skills_line_spacing)
        #{
          if type(skill_group) == dictionary {
            let category_value = first_present(skill_group, ("category", "title", "name", "label", "text"))
            let category = render_rich(if category_value == none { "Skills" } else { category_value }, config)
            let skill_parts = ()
            let skills_value = first_present(skill_group, ("skills", "items", "values"))
            for s in as_array(if skills_value == none { () } else { skills_value }) {
              skill_parts.push(render_rich(s, config))
            }
            [#strong(category): #skill_parts.join(", ")]
          } else {
            render_rich(skill_group, config)
          }
        }
      ]
    }
  ]
}

// ============================================================================
// LANGUAGES SECTION
// ============================================================================

#let render_languages(data, config) = {
  let language_entries = as_array(data.at("languages", default: ()))
  if language_entries.len() == 0 { return }
  if not config.at("show_languages", default: true) { return }

  let variant = config.at("variant", default: "long")
  let lang_items = filter_by_variant(language_entries, variant)
  if lang_items.len() == 0 { return }

  section_heading(resolve_section_title(config, "languages"), config)
  block(above: 0pt, below: 0pt)[
    #let lang_list = ()
    #for lang in lang_items {
      if type(lang) == dictionary {
        let language = lang.at("language", default: none)
        let fluency = lang.at("fluency", default: none)
        if language != none and fluency != none {
          lang_list.push([#render_rich(language, config) (#render_rich(fluency, config))])
        } else if language != none {
          lang_list.push(render_rich(language, config))
        } else {
          lang_list.push(render_rich(str(lang), config))
        }
      } else {
        lang_list.push(render_rich(lang, config))
      }
    }
    #lang_list.join([ | ])
  ]
}

// ============================================================================
// INTERESTS SECTION
// ============================================================================

#let render_interests(data, config) = {
  let interest_entries = as_array(data.at("interests", default: ()))
  if interest_entries.len() == 0 { return }
  if not config.at("show_interests", default: true) { return }

  let variant = config.at("variant", default: "long")
  let interest_items = filter_by_variant(interest_entries, variant)
  if interest_items.len() == 0 { return }

  section_heading(resolve_section_title(config, "interests"), config)
  block(above: 0pt, below: 0pt)[
    #let interest_list = ()
    #for interest in interest_items {
      if type(interest) == dictionary {
        let interest_label = first_present(interest, ("content", "name", "label", "title", "text"))
        if interest_label != none {
          interest_list.push(render_rich(interest_label, config))
        }
      } else {
        interest_list.push(render_rich(interest, config))
      }
    }
    #interest_list.join(", ")
  ]
}

// ============================================================================
// REFERENCES SECTION
// ============================================================================

#let render_references(data, config) = {
  let reference_entries = as_array(data.at("references", default: ()))
  if reference_entries.len() == 0 { return }
  if not config.at("show_references", default: false) { return }

  let variant = config.at("variant", default: "long")
  let refs = filter_by_variant(reference_entries, variant)
  if refs.len() == 0 { return }

  section_heading(resolve_section_title(config, "references"), config)
  block(above: 0pt, below: 0pt)[
    #for ref in refs {
      block(width: 100%, above: 0.3em, below: 0pt)[
        #if type(ref) != dictionary {
          [- #render_rich(ref, config)]
        } else if "url" in ref and ref.url != none {
          let ref_name = first_present(ref, ("name", "title", "label", "content", "text"))
          let ref_name = if ref_name == none { "Reference" } else { ref_name }
          let ref_text = first_present(ref, ("reference", "content", "notes", "description", "summary", "text"))
          let ref_text = if ref_text == none { "" } else { ref_text }
          [- #strong(maybe_link(ref.url, render_rich(ref_name, config), config)): #render_rich(ref_text, config)]
        } else {
          let ref_name = first_present(ref, ("name", "title", "label", "content", "text"))
          let ref_name = if ref_name == none { "Reference" } else { ref_name }
          let ref_text = first_present(ref, ("reference", "content", "notes", "description", "summary", "text"))
          let ref_text = if ref_text == none { "" } else { ref_text }
          [- #strong(render_rich(ref_name, config)): #render_rich(ref_text, config)]
        }
      ]
    }
  ]
}

// ============================================================================
// GENERIC SECTION RENDERER (for custom sections like patents, talks, service)
// ============================================================================

#let render_generic_item(item, config, entry_spacing, entry_inner_spacing, highlights_spacing, highlight_indent) = {
  if type(item) != dictionary {
    block(width: 100%, above: entry_spacing, below: 0pt, breakable: true)[#render_rich(item, config)]
    return
  }

  block(width: 100%, above: entry_spacing, below: 0pt, breakable: true)[
    #{
      let title = first_present(item, ("name", "title", "label"))
      let subtitle = first_present(item, ("subtitle",))
      let description = first_present(item, ("notes", "description", "summary"))
      let content_lines = as_array(item.at("content", default: ()))

      let date_text = if ("startDate" in item or "endDate" in item) {
        date_range(item.at("startDate", default: none), item.at("endDate", default: none))
      } else {
        let one_date = first_present(item, ("date", "releaseDate", "year"))
        if one_date != none {
          let parsed = parse_date(one_date)
          if parsed != none { parsed } else { render_rich(one_date, config) }
        } else {
          none
        }
      }

      if title != none {
        let title_content = if "url" in item and item.url != none {
          strong(maybe_link(item.url, render_rich(title, config), config))
        } else {
          strong(render_rich(title, config))
        }

        let left_line = if subtitle != none {
          [#title_content | #render_rich(subtitle, config)]
        } else {
          [#title_content]
        }

        if date_text != none and date_text != [] {
          lr(left_line, secondary(config, date_text))
        } else {
          left_line
        }
      }

      if description != none {
        block(width: 100%, above: entry_inner_spacing, below: 0pt, breakable: true)[
          #render_rich(description, config)
        ]
      }

      if content_lines.len() > 0 {
        block(width: 100%, above: entry_inner_spacing, below: 0pt, breakable: true)[
          #for (ci, line) in content_lines.enumerate() {
            block(width: 100%, above: if ci == 0 { 0pt } else { highlights_spacing }, below: 0pt)[
              #render_rich(line, config)
            ]
          }
        ]
      }

      if "skills" in item and type(item.skills) == array and item.skills.len() > 0 {
        block(width: 100%, above: entry_inner_spacing, below: 0pt, breakable: true)[
          #{
            let skill_parts = ()
            for s in item.skills {
              skill_parts.push(render_rich(s, config))
            }
            skill_parts.join(", ")
          }
        ]
      }

    }
  ]
}

#let render_generic_section(data, config, section_key) = {
  if section_key not in data { return }
  let section_data = data.at(section_key, default: none)
  if section_data == none { return }

  let variant = config.at("variant", default: "long")
  let entry_spacing = config.at("generic_entry_spacing", default: config.at("entry_spacing", default: 0.5em))
  let entry_inner_spacing = config.at(
    "generic_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.48em),
  )
  let highlights_spacing = config.at(
    "generic_highlights_spacing",
    default: config.at("list_spacing", default: 0.61em),
  )
  let highlight_indent = config.at("generic_highlight_indent", default: 0.95em)

  let section_title = resolve_section_title(config, section_key)

  if type(section_data) == array {
    let entries = filter_by_variant(section_data, variant)
    if entries.len() == 0 { return }
    section_heading(section_title, config)
    block(above: 0pt, below: 0pt)[
      #for (i, item) in entries.enumerate() {
        render_generic_item(
          item,
          config,
          if i == 0 { 0pt } else { entry_spacing },
          entry_inner_spacing,
          highlights_spacing,
          highlight_indent,
        )
      }
    ]
  } else if type(section_data) == dictionary and "items" in section_data {
    let entries = filter_by_variant(as_array(section_data.items), variant)
    if entries.len() == 0 { return }
    section_heading(section_title, config)
    block(above: 0pt, below: 0pt)[
      #for (i, item) in entries.enumerate() {
        render_generic_item(
          item,
          config,
          if i == 0 { 0pt } else { entry_spacing },
          entry_inner_spacing,
          highlights_spacing,
          highlight_indent,
        )
      }
    ]
  } else {
    section_heading(section_title, config)
    block(above: 0pt, below: 0pt)[
      #render_rich(section_data, config)
    ]
  }
}

// ============================================================================
// CONFIG MANAGEMENT
// ============================================================================

#let flatten_config(yaml_config) = {
  let flat = (:)

  if "variant" in yaml_config { flat.insert("variant", yaml_config.variant) }
  if "paper_size" in yaml_config { flat.insert("paper_size", resolve_paper_size(yaml_config.paper_size, default: "us-letter")) }

  if "fonts" in yaml_config {
    let fonts = yaml_config.fonts
    if "heading_font" in fonts { flat.insert("heading_font", fonts.heading_font) }
    if "body_font" in fonts { flat.insert("body_font", fonts.body_font) }
    if "font_size" in fonts { flat.insert("font_size", parse_dimension(fonts.font_size, default: 10pt)) }
    if "name_font_size" in fonts {
      flat.insert("name_font_size", parse_dimension(fonts.name_font_size, default: 1.4em))
    }
    if "section_font_size" in fonts {
      flat.insert("section_font_size", parse_dimension(fonts.section_font_size, default: 1em))
    }
    if "publications_font_size" in fonts {
      flat.insert("publications_font_size", parse_dimension(fonts.publications_font_size, default: 10pt))
    }
    if "awards_font_size" in fonts {
      flat.insert("awards_font_size", parse_dimension(fonts.awards_font_size, default: 10pt))
    }
  }

  if "layout" in yaml_config {
    let layout = yaml_config.layout
    if "paper_size" in layout { flat.insert("paper_size", resolve_paper_size(layout.paper_size, default: "us-letter")) }
    if "margin" in layout { flat.insert("margin", parse_dimension(layout.margin, default: 0.65in)) }
    if "line_spacing" in layout {
      flat.insert("line_spacing", parse_dimension(layout.line_spacing, default: 0.33em))
    }
    if "skills_line_spacing" in layout {
      flat.insert("skills_line_spacing", parse_dimension(layout.skills_line_spacing, default: 0.33em))
    }
    if "list_spacing" in layout {
      flat.insert("list_spacing", parse_dimension(layout.list_spacing, default: 0.61em))
    }
    if "section_spacing" in layout {
      flat.insert("section_spacing", parse_dimension(layout.section_spacing, default: 1.08em))
    }
    if "entry_spacing" in layout {
      flat.insert("entry_spacing", parse_dimension(layout.entry_spacing, default: 0.5em))
    }
    if "entry_inner_spacing" in layout {
      flat.insert("entry_inner_spacing", parse_dimension(layout.entry_inner_spacing, default: 0.48em))
    }
    if "pub_spacing" in layout {
      flat.insert("pub_spacing", parse_dimension(layout.pub_spacing, default: 0.61em))
    }
    if "skill_spacing" in layout {
      flat.insert("skill_spacing", parse_dimension(layout.skill_spacing, default: 0.61em))
    }
    if "work_highlight_indent" in layout {
      flat.insert("work_highlight_indent", parse_dimension(layout.work_highlight_indent, default: 1.2em))
    }
    if "education_highlight_indent" in layout {
      flat.insert("education_highlight_indent", parse_dimension(layout.education_highlight_indent, default: 0.95em))
    }
    if "awards_highlight_indent" in layout {
      flat.insert("awards_highlight_indent", parse_dimension(layout.awards_highlight_indent, default: 0.95em))
    }
    if "generic_entry_spacing" in layout {
      flat.insert("generic_entry_spacing", parse_dimension(layout.generic_entry_spacing, default: 0.5em))
    }
    if "generic_entry_inner_spacing" in layout {
      flat.insert(
        "generic_entry_inner_spacing",
        parse_dimension(layout.generic_entry_inner_spacing, default: 0.48em),
      )
    }
    if "generic_highlights_spacing" in layout {
      flat.insert(
        "generic_highlights_spacing",
        parse_dimension(layout.generic_highlights_spacing, default: 0.61em),
      )
    }
    if "generic_highlight_indent" in layout {
      flat.insert("generic_highlight_indent", parse_dimension(layout.generic_highlight_indent, default: 0.95em))
    }
    if "post_section_spacing" in layout {
      flat.insert("post_section_spacing", parse_dimension(layout.post_section_spacing, default: 0.74em))
    }
    if "work_position_spacing" in layout {
      flat.insert("work_position_spacing", parse_dimension(layout.work_position_spacing, default: 0.48em))
    }
    if "work_bullet_spacing" in layout {
      flat.insert("work_bullet_spacing", parse_dimension(layout.work_bullet_spacing, default: 0.48em))
    }
    if "header_bottom_spacing" in layout {
      flat.insert("header_bottom_spacing", parse_dimension(layout.header_bottom_spacing, default: 0.3em))
    }
    if "header_rule_top_spacing" in layout {
      flat.insert("header_rule_top_spacing", parse_dimension(layout.header_rule_top_spacing, default: 0.42em))
    }
    if "contact_separator_spacing" in layout {
      flat.insert("contact_separator_spacing", parse_dimension(layout.contact_separator_spacing, default: 0.3em))
    }
    if "last_updated_bottom_spacing" in layout {
      flat.insert(
        "last_updated_bottom_spacing",
        parse_dimension(layout.last_updated_bottom_spacing, default: 0.16em),
      )
    }
    if "work_entry_spacing" in layout {
      flat.insert("work_entry_spacing", parse_dimension(layout.work_entry_spacing, default: 0.5em))
    }
    if "work_entry_inner_spacing" in layout {
      flat.insert(
        "work_entry_inner_spacing",
        parse_dimension(layout.work_entry_inner_spacing, default: 0.48em),
      )
    }
    if "work_list_spacing" in layout {
      flat.insert("work_list_spacing", parse_dimension(layout.work_list_spacing, default: 0.61em))
    }
    if "education_entry_spacing" in layout {
      flat.insert("education_entry_spacing", parse_dimension(layout.education_entry_spacing, default: 0.5em))
    }
    if "education_entry_inner_spacing" in layout {
      flat.insert(
        "education_entry_inner_spacing",
        parse_dimension(layout.education_entry_inner_spacing, default: 0.48em),
      )
    }
    if "education_honors_spacing" in layout {
      flat.insert("education_honors_spacing", parse_dimension(layout.education_honors_spacing, default: 0.02em))
    }
    if "education_degree_spacing" in layout {
      flat.insert("education_degree_spacing", parse_dimension(layout.education_degree_spacing, default: 0.02em))
    }
    if "education_courses_spacing" in layout {
      flat.insert("education_courses_spacing", parse_dimension(layout.education_courses_spacing, default: 0.02em))
    }
    if "education_highlights_spacing" in layout {
      flat.insert(
        "education_highlights_spacing",
        parse_dimension(layout.education_highlights_spacing, default: 0.02em),
      )
    }
    if "education_list_spacing" in layout {
      flat.insert("education_list_spacing", parse_dimension(layout.education_list_spacing, default: 0.61em))
    }
    if "projects_entry_spacing" in layout {
      flat.insert("projects_entry_spacing", parse_dimension(layout.projects_entry_spacing, default: 0.5em))
    }
    if "projects_entry_inner_spacing" in layout {
      flat.insert(
        "projects_entry_inner_spacing",
        parse_dimension(layout.projects_entry_inner_spacing, default: 0.48em),
      )
    }
    if "awards_entry_spacing" in layout {
      flat.insert("awards_entry_spacing", parse_dimension(layout.awards_entry_spacing, default: 0.5em))
    }
    if "awards_entry_inner_spacing" in layout {
      flat.insert(
        "awards_entry_inner_spacing",
        parse_dimension(layout.awards_entry_inner_spacing, default: 0.05em),
      )
    }
    if "awards_highlights_spacing" in layout {
      flat.insert("awards_highlights_spacing", parse_dimension(layout.awards_highlights_spacing, default: 0.05em))
    }
    if "awards_list_spacing" in layout {
      flat.insert("awards_list_spacing", parse_dimension(layout.awards_list_spacing, default: 0.05em))
    }
    if "publications_line_spacing" in layout {
      flat.insert("publications_line_spacing", parse_dimension(layout.publications_line_spacing, default: 0.33em))
    }
    if "publications_heading_tighten" in layout {
      flat.insert("publications_heading_tighten", parse_dimension(layout.publications_heading_tighten, default: 0pt))
    }
  }

  if "styling" in yaml_config {
    let styling = yaml_config.styling
    if "section_smallcaps" in styling { flat.insert("section_smallcaps", styling.section_smallcaps) }
    if "contact_font_size" in styling {
      flat.insert("contact_font_size", parse_dimension(styling.contact_font_size, default: 0.85em))
    }
    if "summary_font_size" in styling {
      flat.insert("summary_font_size", parse_dimension(styling.summary_font_size, default: 1.0em))
    }
    if "secondary_color" in styling {
      flat.insert("secondary_color", parse_color(styling.secondary_color, default: rgb("#555555")))
    }
    if "link_color" in styling {
      flat.insert("link_color", parse_color(styling.link_color, default: rgb("#1C398D")))
    }
    if "section_rule_color" in styling {
      flat.insert("section_rule_color", parse_color(styling.section_rule_color, default: rgb("#9F9FA8")))
    }
    if "header_rule_color" in styling {
      flat.insert("header_rule_color", parse_color(styling.header_rule_color, default: rgb("#9F9FA8")))
    }
    if "section_rule_thickness" in styling {
      flat.insert("section_rule_thickness", parse_dimension(styling.section_rule_thickness, default: 0.6pt))
    }
    if "header_rule_thickness" in styling {
      flat.insert("header_rule_thickness", parse_dimension(styling.header_rule_thickness, default: 1pt))
    }
    if "section_rule_enabled" in styling { flat.insert("section_rule_enabled", styling.section_rule_enabled) }
    if "section_rule_gap" in styling {
      flat.insert("section_rule_gap", parse_dimension(styling.section_rule_gap, default: 0.12em))
    }
    if "section_heading_tracking" in styling {
      flat.insert("section_heading_tracking", parse_dimension(styling.section_heading_tracking, default: 0.01em))
    }
    if "publications_link_style" in styling {
      flat.insert("publications_link_style", styling.publications_link_style)
    }
    if "last_updated_font_size" in styling {
      flat.insert(
        "last_updated_font_size",
        parse_dimension(styling.last_updated_font_size, default: 0.68em),
      )
    }
    if "last_updated_label" in styling {
      flat.insert("last_updated_label", str(styling.last_updated_label))
    }
    if "contact_display_mode" in styling {
      flat.insert("contact_display_mode", lower(str(styling.contact_display_mode)))
    }
    if "contact_icon_family" in styling {
      flat.insert("contact_icon_family", lower(str(styling.contact_icon_family)))
    }
    if "contact_icon_spacing" in styling {
      flat.insert("contact_icon_spacing", parse_dimension(styling.contact_icon_spacing, default: 0.18em))
    }
  }

  if "visibility" in yaml_config {
    let visibility = yaml_config.visibility
    if "show_location" in visibility { flat.insert("show_location", visibility.show_location) }
    if "show_phone" in visibility { flat.insert("show_phone", visibility.show_phone) }
    if "show_interests_summary" in visibility {
      flat.insert("show_interests_summary", visibility.show_interests_summary)
    }
    if "show_languages" in visibility { flat.insert("show_languages", visibility.show_languages) }
    if "show_interests" in visibility { flat.insert("show_interests", visibility.show_interests) }
    if "show_references" in visibility { flat.insert("show_references", visibility.show_references) }
    if "show_last_updated" in visibility { flat.insert("show_last_updated", visibility.show_last_updated) }
    if "show_titles" in visibility { flat.insert("show_titles", visibility.show_titles) }
    if "show_page_numbers" in visibility { flat.insert("show_page_numbers", visibility.show_page_numbers) }
    if "url_display_label" in visibility { flat.insert("url_display_label", visibility.url_display_label) }
    if "enable_links" in visibility { flat.insert("enable_links", visibility.enable_links) }
    if "strip_link_labels_when_links_disabled" in visibility {
      flat.insert("strip_link_labels_when_links_disabled", visibility.strip_link_labels_when_links_disabled)
    }
    if "show_publication_numbers" in visibility { flat.insert("show_publication_numbers", visibility.show_publication_numbers) }
  }

  if "last_updated" in yaml_config and yaml_config.last_updated != none {
    flat.insert("last_updated", str(yaml_config.last_updated))
  }

  if "section_titles" in yaml_config {
    let titles = yaml_config.section_titles
    flat.insert("section_titles_map", titles)
  }

  if "section_order" in yaml_config {
    flat.insert("section_order", yaml_config.section_order)
  }

  if "publication_sections" in yaml_config {
    flat.insert("publication_sections", yaml_config.publication_sections)
  }

  return flat
}

#let load_config(config_file: none, inline_config: (:)) = {
  let final_config = (:)
  if config_file != none {
    let yaml_config = yaml(config_file)
    final_config = flatten_config(yaml_config)
  }
  for (key, value) in inline_config {
    final_config.insert(key, value)
  }
  return final_config
}

// ============================================================================
// MAIN RESUME BUILDER FUNCTION
// ============================================================================

#let build_resume(data, config, config_file: none, bib_file: none) = {
  let merged_config = load_config(config_file: config_file, inline_config: config)
  let config = merged_config

  if bib_file != none {
    config.insert("bib_file", bib_file)
  }

  show: doc => apply_settings(config, doc)
  show: doc => apply_heading_styles(config, doc)

  if bib_file != none {
    show bibliography: none
    bibliography(bib_file, style: config.at("bib_style", default: "ieee"))
  }

  render_header(data, config)

  let known_renderers = (
    "interests_summary",
    "work",
    "education",
    "publications",
    "projects",
    "awards",
    "skills",
    "languages",
    "interests",
    "references",
  )

  let section_order = config.at("section_order", default: (
    "interests_summary",
    "work",
    "education",
    "publications",
    "projects",
    "awards",
    "skills",
    "languages",
    "interests",
    "references",
  ))

  for section in section_order {
    if section == "interests_summary" { render_interests_summary(data, config) }
    else if section == "work" { render_work(data, config) }
    else if section == "education" { render_education(data, config) }
    else if section == "publications" { render_publications(data, config) }
    else if section == "projects" { render_projects(data, config) }
    else if section == "awards" { render_awards(data, config) }
    else if section == "skills" { render_skills(data, config) }
    else if section == "languages" { render_languages(data, config) }
    else if section == "interests" { render_interests(data, config) }
    else if section == "references" { render_references(data, config) }
    else { render_generic_section(data, config, section) }
  }

  let special_keys = ("personal", "meta", "interests_summary")
  if type(data) == dictionary {
    for key in data.keys() {
      if key not in special_keys and key not in section_order and key not in known_renderers {
        render_generic_section(data, config, key)
      }
    }
  }
}
