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
    if display == "short" { month.slice(0, 3) } else { month }
  } else {
    none
  }
}

#let numeric_pattern = regex("^[+-]?[0-9]+(\\.[0-9]+)?$")
#let year_pattern = regex("^[0-9]{4}$")
#let iso_date_pattern = regex("^[0-9]{4}-[0-9]{2}(-[0-9]{2})?$")
#let hex_color_pattern = regex("^#[0-9a-fA-F]{6}$")
#let legacy_rgb_color_pattern = regex("^rgb\\(\"#[0-9a-fA-F]{6}\"\\)$")

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

  if s.matches(legacy_rgb_color_pattern).len() > 0 {
    let parts = s.split("\"")
    if parts.len() >= 2 {
      let hex = parts.at(1)
      if hex.matches(hex_color_pattern).len() > 0 {
        return rgb(hex)
      }
    }
  }

  default
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

#let date_range(start_date, end_date) = {
  let start = parse_date(start_date)
  let end = parse_date(end_date)
  if start != none and end != none {
    [#start #sym.dash.en #end]
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

// ============================================================================
// DOCUMENT SETUP
// ============================================================================

#let apply_settings(config, doc) = {
  set page(
    paper: "us-letter",
    margin: config.at("margin", default: 0.5in),
  )
  set text(
    font: config.at("body_font", default: "New Computer Modern"),
    size: config.at("font_size", default: 10pt),
    hyphenate: false,
  )
  set par(
    leading: config.at("line_spacing", default: 0.82em),
    justify: false,
  )
  set list(
    indent: 0.9em,
    spacing: config.at("list_spacing", default: 0.24em),
    marker: [•],
    body-indent: 0.5em,
  )
  show link: it => {
    let c = parse_color(config.at("link_color", default: none), default: rgb("#0b61a4"))
    text(fill: c, it)
  }
  doc
}

#let apply_heading_styles(config, doc) = {
  show heading.where(level: 1): it => block(width: 100%)[
    #set text(
      font: config.at("heading_font", default: "New Computer Modern"),
      size: config.at("name_font_size", default: 1.8em),
      weight: "bold",
    )
    #it.body
  ]

  show heading.where(level: 2): it => {
    let rule_color = parse_color(config.at("section_rule_color", default: none), default: rgb("#222222"))
    let rule_thickness = config.at("section_rule_thickness", default: 0.6pt)
    v(config.at("section_spacing", default: 0.5em))
    block(breakable: false, width: 100%)[
      #set text(
        font: config.at("heading_font", default: "New Computer Modern"),
        size: config.at("section_font_size", default: 1em),
        weight: "bold",
        tracking: 0.03em,
      )
      #if config.at("section_smallcaps", default: true) {
        smallcaps(it.body)
      } else {
        upper(it.body)
      }
      #v(0.12em)
      #line(length: 100%, stroke: rule_thickness + rule_color)
    ]
    v(config.at("post_section_spacing", default: 0.26em))
  }

  doc
}

// ============================================================================
// HEADER / CONTACT INFORMATION
// ============================================================================

#let render_header(data, config) = {
  let personal = data.at("personal", default: none)
  if personal == none { return }

  let contact_size = config.at("contact_font_size", default: 0.85em)
  let last_updated = resolve_last_updated(data, config)
  let show_last_updated = config.at("show_last_updated", default: true)

  if show_last_updated and last_updated != none {
    align(right)[
      #set text(size: config.at("last_updated_font_size", default: 0.72em))
      #secondary(config, [
        #config.at("last_updated_label", default: "Last Updated on")
        #h(0.35em)
        #last_updated
      ])
    ]
    v(config.at("last_updated_bottom_spacing", default: 0.2em))
  }

  align(center)[
    = #personal.name

    #v(-0.4em)

    #let titles = as_array(personal.at("titles", default: ()))
    #if titles.len() > 0 {
      block(above: 0pt, below: 0.2em)[
        #set text(size: 0.9em, weight: "regular", style: "italic")
        #{
          let title_items = ()
          for title in titles {
            title_items.push(render_markup(title))
          }
          title_items.join([ | ])
        }
      ]
    }

    #if config.at("show_location", default: true) {
      if "location" in personal and personal.location != none {
        let loc = personal.location
        let parts = ()
        if "city" in loc and loc.city != none and loc.city != "" { parts.push(loc.city) }
        if "region" in loc and loc.region != none and loc.region != "" { parts.push(loc.region) }
        if "country" in loc and loc.country != none and loc.country != "" { parts.push(loc.country) }
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

      #if "email" in personal and personal.email != none {
        contacts.push(link("mailto:" + personal.email)[#personal.email])
      }

      #if config.at("show_phone", default: true) {
        if "phone" in personal and personal.phone != none {
          contacts.push(link("tel:" + personal.phone)[#personal.phone])
        }
      }

      #if "url" in personal and personal.url != none {
        let display_url = personal.url.split("//").at(-1).trim("/", at: end)
        contacts.push(link(personal.url)[#display_url])
      }

      #let profiles = as_array(personal.at("profiles", default: ()))
      #if profiles.len() > 0 {
        for profile in profiles {
          if "network" in profile and "username" in profile and profile.username != none {
            if "url" in profile and profile.url != none {
              contacts.push(link(profile.url)[#profile.username])
            } else if profile.network != none and profile.network != "" {
              contacts.push([#profile.network: #profile.username])
            } else {
              contacts.push(profile.username)
            }
          } else if "url" in profile and profile.url != none {
            let display_url = profile.url.split("//").at(-1).trim("/", at: end)
            contacts.push(link(profile.url)[#display_url])
          }
        }
      }

      #contacts.join([ #h(0.3em) | #h(0.3em) ])
    ]
  ]

  v(config.at("header_bottom_spacing", default: 0.12em))
}

// ============================================================================
// INTERESTS / SUMMARY SECTION
// ============================================================================

#let render_interests_summary(data, config) = {
  if not config.at("show_interests_summary", default: false) { return }
  if "interests_summary" in data and data.interests_summary != none {
    block(above: 0pt, below: 0pt)[
      == #config.at("interests_summary_title", default: "Interests")
      #set text(size: config.at("summary_font_size", default: 0.92em))
      #render_markup(data.interests_summary)
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

  let entry_spacing = config.at("work_entry_spacing", default: config.at("entry_spacing", default: 0.56em))
  let entry_inner_spacing = config.at(
    "work_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.28em),
  )
  let position_spacing = config.at("work_position_spacing", default: entry_inner_spacing * 1.1)
  let bullet_top_spacing = config.at("work_bullet_spacing", default: entry_inner_spacing)
  let work_list_spacing = config.at("work_list_spacing", default: config.at("list_spacing", default: 0.2em))

  block(above: 0pt, below: 0pt)[
    == #config.at("work_title", default: "Experience")

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
                let org_content = if "url" in work and work.url != none {
                  strong(link(work.url)[#render_markup(work.organization)])
                } else {
                  strong(render_markup(work.organization))
                }

                let role = position.at("position", default: position.at("name", default: none))
                let left_line = if role != none and str(role).trim() != "" {
                  [#org_content #sym.dash.em #render_markup(role)]
                } else {
                  [#org_content]
                }

                lr(
                  left_line,
                  date_range(position.at("startDate", default: none), position.at("endDate", default: none)),
                )
              }

              #let position_highlights = as_array(position.at("highlights", default: ()))
              #if position_highlights.len() > 0 {
                block(width: 100%, above: bullet_top_spacing, below: 0pt, breakable: true)[
                  #set list(spacing: work_list_spacing)
                  #for highlight in position_highlights {
                    [- #render_markup(highlight)]
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

  let entry_spacing = config.at("education_entry_spacing", default: config.at("entry_spacing", default: 0.66em))
  let entry_inner_spacing = config.at(
    "education_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.24em),
  )
  let honors_spacing = config.at("education_honors_spacing", default: entry_inner_spacing)
  let degree_spacing = config.at("education_degree_spacing", default: entry_inner_spacing)
  let courses_spacing = config.at("education_courses_spacing", default: entry_inner_spacing * 0.9)
  let highlights_spacing = config.at("education_highlights_spacing", default: entry_inner_spacing)
  let education_list_spacing = config.at("education_list_spacing", default: config.at("list_spacing", default: 0.22em))

  block(above: 0pt, below: 0pt)[
    == #config.at("education_title", default: "Education")

    #for (i, edu) in edu_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #{
          let inst_content = if "url" in edu and edu.url != none {
            strong(link(edu.url)[#render_markup(edu.institution)])
          } else {
            strong(render_markup(edu.institution))
          }
          let loc_parts = ()
          if "location" in edu and edu.location != none {
            loc_parts.push(edu.location)
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

        #let honors_list = as_array(edu.at("honors", default: ()))
        #if honors_list.len() > 0 {
          block(width: 100%, above: honors_spacing, below: 0pt, breakable: true)[
            #{
              let honors = ()
              for honor in honors_list {
                honors.push(render_markup(honor))
              }
              strong(honors.join(", "))
            }
          ]
        }

        #{
          let degree_parts = ()
          if "studyType" in edu and edu.studyType != none { degree_parts.push(render_markup(edu.studyType)) }
          if "area" in edu and edu.area != none { degree_parts.push([ in #render_markup(edu.area)]) }
          if degree_parts.len() > 0 {
            block(width: 100%, above: degree_spacing, below: 0pt, breakable: true)[
              #degree_parts.join()
            ]
          }
        }

        #let courses_list = as_array(edu.at("courses", default: ()))
        #if courses_list.len() > 0 {
          block(width: 100%, above: courses_spacing, below: 0pt, breakable: true)[
            #{
              let courses = ()
              for course in courses_list {
                courses.push(render_markup(course))
              }
              [Coursework: #courses.join(", ")]
            }
          ]
        }

        #let edu_highlights = as_array(edu.at("highlights", default: ()))
        #if edu_highlights.len() > 0 {
          block(width: 100%, above: highlights_spacing, below: 0pt, breakable: true)[
            #set list(spacing: education_list_spacing)
            #for highlight in edu_highlights {
              [- #render_markup(highlight)]
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

#let render_publications(data, config) = {
  let publication_entries = as_array(data.at("publications", default: ()))
  if publication_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let pub_items = filter_by_variant(publication_entries, variant)
  if pub_items.len() == 0 { return }

  let pub_spacing = config.at("pub_spacing", default: 0.62em)
  let pub_font_size = config.at("publications_font_size", default: config.at("font_size", default: 10.5pt))
  let pub_link_style = config.at("publications_link_style", default: "compact")
  let pub_line_spacing = config.at("publications_line_spacing", default: config.at("line_spacing", default: 0.62em))
  let author_name = data.at("personal", default: (:)).at("name", default: none)

  block(above: 0pt, below: 0pt)[
    == #config.at("publications_title", default: "Publications")

    #for (i, pub) in pub_items.enumerate() {
      if type(pub) != dictionary {
        block(width: 100%, above: if i == 0 { 0pt } else { pub_spacing }, below: 0pt)[
          #set text(size: pub_font_size)
          #set par(leading: pub_line_spacing)
          #render_markup(pub)
        ]
      } else if "bib_key" in pub {
        let extra_links = as_array(pub.at("links", default: ()))
        block(width: 100%, above: if i == 0 { 0pt } else { pub_spacing }, below: 0pt)[
          #set text(size: pub_font_size)
          #set par(leading: pub_line_spacing)
          #cite(label(pub.bib_key), form: "full")
          #if extra_links.len() > 0 {
            let link_parts = ()
            for link_info in extra_links {
              if "label" in link_info and "url" in link_info {
                link_parts.push(link(link_info.url)[#link_info.label])
              }
            }
            if link_parts.len() > 0 {
              if pub_link_style == "newline" {
                [\ ]
                [[#link_parts.join([ | ])]]
              } else {
                [ [#link_parts.join([ | ])]]
              }
            }
          }
        ]
      } else {
        block(width: 100%, above: if i == 0 { 0pt } else { pub_spacing }, below: 0pt)[
          #set text(size: pub_font_size)
          #set par(leading: pub_line_spacing)
          #{
            let title = pub.at("name", default: pub.at("title", default: "Untitled"))
            if "url" in pub and pub.url != none {
              strong(link(pub.url)[#render_markup(title)])
            } else {
              strong(render_markup(title))
            }
          }
          #if "authors" in pub and pub.authors != none {
            [. #highlight_author_name(pub.authors, author_name)]
          }
          #if "publisher" in pub and pub.publisher != none {
            [. #emph(render_markup(pub.publisher))]
            if "releaseDate" in pub and pub.releaseDate != none {
              let date = parse_date(pub.releaseDate)
              if date != none {
                [, ]
                secondary(config, date)
              }
            }
          } else if "releaseDate" in pub and pub.releaseDate != none {
            let date = parse_date(pub.releaseDate)
            if date != none {
              [. ]
              secondary(config, date)
            }
          }
          #if "status" in pub and pub.status != none {
            if "publisher" not in pub or pub.publisher == none {
              [ --- #emph[#render_markup(pub.status)]]
            } else {
              [ (#render_markup(pub.status))]
            }
          }
          .
        ]
      }
    }
  ]
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
    default: config.at("entry_spacing", default: 0.52em),
  )
  let entry_inner_spacing = config.at(
    "projects_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.22em),
  )

  block(above: 0pt, below: 0pt)[
    == #config.at("projects_title", default: "Projects")

    #for (i, project) in project_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #if type(project) != dictionary {
          render_markup(project)
        } else {
          [
            #lr(
              {
                if "url" in project and project.url != none {
                  strong(link(project.url)[#render_markup(project.at("name", default: "Project"))])
                } else {
                  strong(render_markup(project.at("name", default: "Project")))
                }
              },
              secondary(config, date_range(project.at("startDate", default: none), project.at("endDate", default: none))),
            )

            #if "affiliation" in project and project.affiliation != none {
              text(style: "italic")[#render_markup(project.affiliation)]
            }

            #let project_highlights = as_array(project.at("highlights", default: ()))
            #if project_highlights.len() > 0 {
              block(width: 100%, above: entry_inner_spacing, below: 0pt, breakable: true)[
                #for highlight in project_highlights {
                  [- #render_markup(highlight)]
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

  let entry_spacing = config.at("awards_entry_spacing", default: config.at("entry_spacing", default: 0.46em))
  let entry_inner_spacing = config.at(
    "awards_entry_inner_spacing",
    default: config.at("entry_inner_spacing", default: 0.22em),
  )
  let awards_font_size = config.at("awards_font_size", default: config.at("font_size", default: 10.5pt))
  let awards_highlights_spacing = config.at("awards_highlights_spacing", default: entry_inner_spacing)
  let awards_list_spacing = config.at("awards_list_spacing", default: config.at("list_spacing", default: 0.22em))

  block(above: 0pt, below: 0pt)[
    == #config.at("awards_title", default: "Honors and Awards")

    #for (i, award) in award_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #set text(size: awards_font_size)
        #if type(award) != dictionary {
          render_markup(award)
        } else {
          [
            #lr(
              {
                let title_content = if "url" in award and award.url != none {
                  strong(link(award.url)[#render_markup(award.title)])
                } else {
                  strong(render_markup(award.title))
                }
                if "issuer" in award and award.issuer != none {
                  [#title_content, #emph(render_markup(award.issuer))]
                } else {
                  title_content
                }
              },
              {
                let right_parts = ()
                if "location" in award and award.location != none {
                  right_parts.push(award.location)
                }
                if "date" in award and award.date != none {
                  let date = parse_date(award.date)
                  if date != none { right_parts.push(date) }
                }
                if right_parts.len() > 0 {
                  secondary(config, right_parts.join([ | ]))
                }
              },
            )

            #let award_highlights = as_array(award.at("highlights", default: ()))
            #if award_highlights.len() > 0 {
              block(width: 100%, above: awards_highlights_spacing, below: 0pt, breakable: true)[
                #set list(spacing: awards_list_spacing)
                #for highlight in award_highlights {
                  [- #render_markup(highlight)]
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
// SKILLS SECTION
// ============================================================================

#let render_skills(data, config) = {
  let skill_entries = as_array(data.at("skills", default: ()))
  if skill_entries.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let skill_items = filter_by_variant(skill_entries, variant)
  if skill_items.len() == 0 { return }

  let skill_spacing = config.at("skill_spacing", default: 0.1em)

  block(above: 0pt, below: 0pt)[
    == #config.at("skills_title", default: "Skills")

    #for (i, skill_group) in skill_items.enumerate() {
      block(above: if i == 0 { 0pt } else { skill_spacing }, below: 0pt)[
        #{
          if type(skill_group) == dictionary {
            let category = render_markup(skill_group.at("category", default: "Skills"))
            let skill_parts = ()
            for s in as_array(skill_group.at("skills", default: ())) {
              skill_parts.push(render_markup(s))
            }
            [#strong(category): #skill_parts.join(", ")]
          } else {
            render_markup(skill_group)
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

  block(above: 0pt, below: 0pt)[
    == #config.at("languages_title", default: "Languages")

    #let lang_list = ()
    #for lang in lang_items {
      if type(lang) == dictionary {
        let language = lang.at("language", default: none)
        let fluency = lang.at("fluency", default: none)
        if language != none and fluency != none {
          lang_list.push([#render_markup(language) (#render_markup(fluency))])
        } else if language != none {
          lang_list.push(render_markup(language))
        } else {
          lang_list.push(render_markup(str(lang)))
        }
      } else {
        lang_list.push(render_markup(lang))
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

  block(above: 0pt, below: 0pt)[
    == #config.at("interests_title", default: "Interests")
    #let interest_list = ()
    #for interest in interest_items {
      if type(interest) == dictionary {
        if "name" in interest and interest.name != none {
          interest_list.push(render_markup(interest.name))
        } else if "label" in interest and interest.label != none {
          interest_list.push(render_markup(interest.label))
        }
      } else {
        interest_list.push(render_markup(interest))
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

  block(above: 0pt, below: 0pt)[
    == #config.at("references_title", default: "References")

    #for ref in refs {
      block(width: 100%, above: 0.3em, below: 0pt)[
        #if type(ref) != dictionary {
          [- #render_markup(ref)]
        } else if "url" in ref and ref.url != none {
          [- #strong(link(ref.url)[#render_markup(ref.at("name", default: "Reference"))]): #render_markup(ref.at("reference", default: ""))]
        } else {
          [- #strong(render_markup(ref.at("name", default: "Reference"))): #render_markup(ref.at("reference", default: ""))]
        }
      ]
    }
  ]
}

// ============================================================================
// CONFIG MANAGEMENT
// ============================================================================

#let flatten_config(yaml_config) = {
  let flat = (:)

  if "variant" in yaml_config { flat.insert("variant", yaml_config.variant) }

  if "fonts" in yaml_config {
    let fonts = yaml_config.fonts
    if "heading_font" in fonts { flat.insert("heading_font", fonts.heading_font) }
    if "body_font" in fonts { flat.insert("body_font", fonts.body_font) }
    if "font_size" in fonts { flat.insert("font_size", parse_dimension(fonts.font_size, default: 10pt)) }
    if "name_font_size" in fonts {
      flat.insert("name_font_size", parse_dimension(fonts.name_font_size, default: 1.8em))
    }
    if "section_font_size" in fonts {
      flat.insert("section_font_size", parse_dimension(fonts.section_font_size, default: 1em))
    }
    if "publications_font_size" in fonts {
      flat.insert("publications_font_size", parse_dimension(fonts.publications_font_size, default: 10.5pt))
    }
    if "awards_font_size" in fonts {
      flat.insert("awards_font_size", parse_dimension(fonts.awards_font_size, default: 10.5pt))
    }
  }

  if "layout" in yaml_config {
    let layout = yaml_config.layout
    if "margin" in layout { flat.insert("margin", parse_dimension(layout.margin, default: 0.5in)) }
    if "line_spacing" in layout {
      flat.insert("line_spacing", parse_dimension(layout.line_spacing, default: 0.82em))
    }
    if "list_spacing" in layout {
      flat.insert("list_spacing", parse_dimension(layout.list_spacing, default: 0.24em))
    }
    if "section_spacing" in layout {
      flat.insert("section_spacing", parse_dimension(layout.section_spacing, default: 0.5em))
    }
    if "entry_spacing" in layout {
      flat.insert("entry_spacing", parse_dimension(layout.entry_spacing, default: 0.72em))
    }
    if "entry_inner_spacing" in layout {
      flat.insert("entry_inner_spacing", parse_dimension(layout.entry_inner_spacing, default: 0.26em))
    }
    if "pub_spacing" in layout {
      flat.insert("pub_spacing", parse_dimension(layout.pub_spacing, default: 0.62em))
    }
    if "skill_spacing" in layout {
      flat.insert("skill_spacing", parse_dimension(layout.skill_spacing, default: 0.18em))
    }
    if "post_section_spacing" in layout {
      flat.insert("post_section_spacing", parse_dimension(layout.post_section_spacing, default: 0.26em))
    }
    if "work_position_spacing" in layout {
      flat.insert("work_position_spacing", parse_dimension(layout.work_position_spacing, default: 0.26em))
    }
    if "work_bullet_spacing" in layout {
      flat.insert("work_bullet_spacing", parse_dimension(layout.work_bullet_spacing, default: 0.22em))
    }
    if "header_bottom_spacing" in layout {
      flat.insert("header_bottom_spacing", parse_dimension(layout.header_bottom_spacing, default: 0.12em))
    }
    if "last_updated_bottom_spacing" in layout {
      flat.insert(
        "last_updated_bottom_spacing",
        parse_dimension(layout.last_updated_bottom_spacing, default: 0.2em),
      )
    }
    if "work_entry_spacing" in layout {
      flat.insert("work_entry_spacing", parse_dimension(layout.work_entry_spacing, default: 0.56em))
    }
    if "work_entry_inner_spacing" in layout {
      flat.insert(
        "work_entry_inner_spacing",
        parse_dimension(layout.work_entry_inner_spacing, default: 0.28em),
      )
    }
    if "work_list_spacing" in layout {
      flat.insert("work_list_spacing", parse_dimension(layout.work_list_spacing, default: 0.2em))
    }
    if "education_entry_spacing" in layout {
      flat.insert("education_entry_spacing", parse_dimension(layout.education_entry_spacing, default: 0.72em))
    }
    if "education_entry_inner_spacing" in layout {
      flat.insert(
        "education_entry_inner_spacing",
        parse_dimension(layout.education_entry_inner_spacing, default: 0.26em),
      )
    }
    if "education_honors_spacing" in layout {
      flat.insert("education_honors_spacing", parse_dimension(layout.education_honors_spacing, default: 0.26em))
    }
    if "education_degree_spacing" in layout {
      flat.insert("education_degree_spacing", parse_dimension(layout.education_degree_spacing, default: 0.26em))
    }
    if "education_courses_spacing" in layout {
      flat.insert("education_courses_spacing", parse_dimension(layout.education_courses_spacing, default: 0.24em))
    }
    if "education_highlights_spacing" in layout {
      flat.insert(
        "education_highlights_spacing",
        parse_dimension(layout.education_highlights_spacing, default: 0.24em),
      )
    }
    if "education_list_spacing" in layout {
      flat.insert("education_list_spacing", parse_dimension(layout.education_list_spacing, default: 0.22em))
    }
    if "projects_entry_spacing" in layout {
      flat.insert("projects_entry_spacing", parse_dimension(layout.projects_entry_spacing, default: 0.46em))
    }
    if "projects_entry_inner_spacing" in layout {
      flat.insert(
        "projects_entry_inner_spacing",
        parse_dimension(layout.projects_entry_inner_spacing, default: 0.18em),
      )
    }
    if "awards_entry_spacing" in layout {
      flat.insert("awards_entry_spacing", parse_dimension(layout.awards_entry_spacing, default: 0.46em))
    }
    if "awards_entry_inner_spacing" in layout {
      flat.insert(
        "awards_entry_inner_spacing",
        parse_dimension(layout.awards_entry_inner_spacing, default: 0.22em),
      )
    }
    if "awards_highlights_spacing" in layout {
      flat.insert("awards_highlights_spacing", parse_dimension(layout.awards_highlights_spacing, default: 0.22em))
    }
    if "awards_list_spacing" in layout {
      flat.insert("awards_list_spacing", parse_dimension(layout.awards_list_spacing, default: 0.22em))
    }
    if "publications_line_spacing" in layout {
      flat.insert("publications_line_spacing", parse_dimension(layout.publications_line_spacing, default: 0.76em))
    }
  }

  if "styling" in yaml_config {
    let styling = yaml_config.styling
    if "section_smallcaps" in styling { flat.insert("section_smallcaps", styling.section_smallcaps) }
    if "contact_font_size" in styling {
      flat.insert("contact_font_size", parse_dimension(styling.contact_font_size, default: 0.85em))
    }
    if "summary_font_size" in styling {
      flat.insert("summary_font_size", parse_dimension(styling.summary_font_size, default: 0.92em))
    }
    if "secondary_color" in styling {
      flat.insert("secondary_color", parse_color(styling.secondary_color, default: rgb("#555555")))
    }
    if "link_color" in styling {
      flat.insert("link_color", parse_color(styling.link_color, default: rgb("#0b61a4")))
    }
    if "section_rule_color" in styling {
      flat.insert("section_rule_color", parse_color(styling.section_rule_color, default: rgb("#222222")))
    }
    if "section_rule_thickness" in styling {
      flat.insert("section_rule_thickness", parse_dimension(styling.section_rule_thickness, default: 0.6pt))
    }
    if "publications_link_style" in styling {
      flat.insert("publications_link_style", styling.publications_link_style)
    }
    if "last_updated_font_size" in styling {
      flat.insert(
        "last_updated_font_size",
        parse_dimension(styling.last_updated_font_size, default: 0.72em),
      )
    }
    if "last_updated_label" in styling {
      flat.insert("last_updated_label", str(styling.last_updated_label))
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
  }

  if "last_updated" in yaml_config and yaml_config.last_updated != none {
    flat.insert("last_updated", str(yaml_config.last_updated))
  }

  if "section_titles" in yaml_config {
    let titles = yaml_config.section_titles
    if "work" in titles { flat.insert("work_title", titles.work) }
    if "education" in titles { flat.insert("education_title", titles.education) }
    if "publications" in titles { flat.insert("publications_title", titles.publications) }
    if "projects" in titles { flat.insert("projects_title", titles.projects) }
    if "awards" in titles { flat.insert("awards_title", titles.awards) }
    if "skills" in titles { flat.insert("skills_title", titles.skills) }
    if "languages" in titles { flat.insert("languages_title", titles.languages) }
    if "interests" in titles { flat.insert("interests_title", titles.interests) }
    if "interests_summary" in titles { flat.insert("interests_summary_title", titles.interests_summary) }
    if "references" in titles { flat.insert("references_title", titles.references) }
  }

  if "section_order" in yaml_config {
    flat.insert("section_order", yaml_config.section_order)
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
    if section == "interests_summary" { render_interests_summary(data, config) } else if section == "work" {
      render_work(data, config)
    } else if section == "education" { render_education(data, config) } else if section == "publications" {
      render_publications(data, config)
    } else if section == "projects" { render_projects(data, config) } else if section == "awards" {
      render_awards(data, config)
    } else if section == "skills" { render_skills(data, config) } else if section == "languages" {
      render_languages(data, config)
    } else if section == "interests" { render_interests(data, config) } else if section == "references" {
      render_references(data, config)
    }
  }
}
