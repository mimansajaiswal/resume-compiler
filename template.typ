// ============================================================================
// TYPST RESUME TEMPLATE - Highly Configurable YAML-Based Resume System
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

#let filter_by_variant(items, variant) = {
  if variant == "long" {
    return items
  }
  items.filter(item => {
    let should_include = item.at("include_short", default: true)
    should_include == true
  })
}

#let month_name(n, display: "short") = {
  n = int(n)
  let months = (
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  )
  if n >= 1 and n <= 12 {
    let month = months.at(n - 1)
    if display == "short" { month.slice(0, 3) } else { month }
  } else {
    none
  }
}

#let parse_date(date_str) = {
  if date_str == none or date_str == "" { return none }
  let date_lower = lower(str(date_str))
  if date_lower == "present" { return "Present" }
  let year = int(date_str.slice(0, 4))
  let month = int(date_str.slice(5, 7))
  let month_str = month_name(month, display: "short")
  return month_str + " " + str(year)
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
    leading: config.at("line_spacing", default: 0.5em),
    justify: true,
  )
  set list(
    indent: 0.6em,
    spacing: config.at("list_spacing", default: 0.4em),
    marker: [•],
    body-indent: 0.4em,
  )
  show link: it => { text(fill: rgb("#0b61a4"), it) }
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
    v(config.at("section_spacing", default: 0.6em))
    block(breakable: false, width: 100%)[
      #set text(
        font: config.at("heading_font", default: "New Computer Modern"),
        size: config.at("section_font_size", default: 1em),
        weight: "bold",
      )
      #if config.at("section_smallcaps", default: true) {
        smallcaps(it.body)
      } else {
        upper(it.body)
      }
      #v(-0.5em)
      #line(length: 100%, stroke: 0.75pt + black)
    ]
    v(config.at("post_section_spacing", default: 0.15em))
  }

  doc
}

// ============================================================================
// HEADER / CONTACT INFORMATION
// ============================================================================

#let render_header(data, config) = {
  let personal = data.at("personal", default: none)
  if personal == none { return }

  let separator = config.at("contact_separator", default: [#h(0.25em)#sym.diamond.filled#h(0.25em)])
  let contact_size = config.at("contact_font_size", default: 0.8em)

  align(center)[
    = #personal.name

    #v(-0.6em)

    #if "titles" in personal and personal.titles != none and personal.titles.len() > 0 {
      block(above: 0pt, below: 0pt)[
        #set text(size: 0.9em, weight: "medium")
        #personal.titles.join(" | ")
      ]
      v(-0.15em)
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
            #parts.join(", ")
          ]
          v(-0.15em)
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

      #if "profiles" in personal and personal.profiles != none {
        for profile in personal.profiles {
          if "network" in profile and "username" in profile and profile.username != none {
            contacts.push(link(profile.url)[#profile.username])
          } else if "url" in profile and profile.url != none {
            let display_url = profile.url.split("//").at(-1).trim("/", at: end)
            contacts.push(link(profile.url)[#display_url])
          }
        }
      }

      #contacts.join(separator)
    ]
  ]

  v(config.at("header_bottom_spacing", default: 0.2em))
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
      #data.interests_summary
    ]
  }
}

// ============================================================================
// WORK EXPERIENCE SECTION
// ============================================================================

#let render_work(data, config) = {
  if "work" not in data or data.work == none or data.work.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let work_items = filter_by_variant(data.work, variant)
  if work_items.len() == 0 { return }

  let entry_spacing = config.at("entry_spacing", default: 0.4em)
  let entry_inner_spacing = config.at("entry_inner_spacing", default: 0.15em)

  block(above: 0pt, below: 0pt)[
    == #config.at("work_title", default: "Experience")

    #for (i, work) in work_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align: (left, right),
          {
            if "url" in work and work.url != none {
              strong(link(work.url)[#work.organization])
            } else {
              strong(work.organization)
            }
          },
          {
            if "location" in work and work.location != none {
              text(style: "italic")[#work.location]
            }
          },
        )

        #if "positions" in work and work.positions != none {
          let positions = filter_by_variant(work.positions, variant)
          for (j, position) in positions.enumerate() {
            v(if j == 0 { entry_inner_spacing } else { entry_spacing * 0.6 })

            grid(
              columns: (1fr, auto),
              column-gutter: 1em,
              align: (left, right),
              [#text(style: "italic")[#position.position]],
              [#date_range(position.at("startDate", default: none), position.at("endDate", default: none))],
            )

            if "highlights" in position and position.highlights != none and position.highlights.len() > 0 {
              v(entry_inner_spacing * 0.5)
              for highlight in position.highlights {
                [- #highlight]
              }
            }
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
  if "education" not in data or data.education == none or data.education.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let edu_items = filter_by_variant(data.education, variant)
  if edu_items.len() == 0 { return }

  let entry_spacing = config.at("entry_spacing", default: 0.4em)
  let entry_inner_spacing = config.at("entry_inner_spacing", default: 0.15em)

  block(above: 0pt, below: 0pt)[
    == #config.at("education_title", default: "Education")

    #for (i, edu) in edu_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: false)[
        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align: (left, right),
          {
            if "url" in edu and edu.url != none {
              strong(link(edu.url)[#edu.institution])
            } else {
              strong(edu.institution)
            }
          },
          {
            if "location" in edu and edu.location != none {
              text(style: "italic")[#edu.location]
            }
          },
        )

        #v(entry_inner_spacing)

        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align: (left, right),
          [
            #text(style: "italic")[
              #if "studyType" in edu and edu.studyType != none { edu.studyType }
              #if "area" in edu and edu.area != none { [ in #edu.area] }
            ]
          ],
          [#date_range(edu.at("startDate", default: none), edu.at("endDate", default: none))],
        )

        #if "honors" in edu and edu.honors != none and edu.honors.len() > 0 {
          [- #strong[Honors]: #edu.honors.join(", ")]
        }

        #if "courses" in edu and edu.courses != none and edu.courses.len() > 0 {
          [- #strong[Coursework]: #edu.courses.join(", ")]
        }

        #if "highlights" in edu and edu.highlights != none and edu.highlights.len() > 0 {
          for highlight in edu.highlights {
            [- #highlight]
          }
        }
      ]
    }
  ]
}

// ============================================================================
// PUBLICATIONS SECTION
// ============================================================================

#let format_bib_entry(bib_key, bib_file, style: "ieee", extra_links: ()) = {
  [
    #cite(label(bib_key), form: "full", style: style)
    #if extra_links.len() > 0 {
      [ ]
      for link_info in extra_links {
        if "label" in link_info and "url" in link_info {
          [[#link(link_info.url)[#link_info.label]]]
          if link_info != extra_links.last() { [ | ] }
        }
      }
    }
  ]
}

#let render_publications(data, config) = {
  if "publications" not in data or data.publications == none or data.publications.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let pub_items = filter_by_variant(data.publications, variant)
  if pub_items.len() == 0 { return }

  let pub_spacing = config.at("pub_spacing", default: 0.5em)

  block(above: 0pt, below: 0pt)[
    == #config.at("publications_title", default: "Publications")

    #for (i, pub) in pub_items.enumerate() {
      if "bib_key" in pub {
        let extra_links = pub.at("links", default: ())
        block(width: 100%, above: if i == 0 { 0pt } else { pub_spacing }, below: 0pt)[
          #cite(label(pub.bib_key), form: "full")
          #if extra_links.len() > 0 {
            [ ]
            let link_parts = ()
            for link_info in extra_links {
              if "label" in link_info and "url" in link_info {
                link_parts.push(link(link_info.url)[#link_info.label])
              }
            }
            [[#link_parts.join([ | ])]]
          }
        ]
      } else {
        block(width: 100%, above: if i == 0 { 0pt } else { pub_spacing }, below: 0pt)[
          #{
            let parts = ()
            if "url" in pub and pub.url != none {
              parts.push(strong(link(pub.url)[#pub.name]))
            } else {
              parts.push(strong(pub.name))
            }
            if "authors" in pub and pub.authors != none {
              parts.push([. #pub.authors])
            }
            if "publisher" in pub and pub.publisher != none {
              parts.push([. #emph(pub.publisher)])
            }
            if "releaseDate" in pub and pub.releaseDate != none {
              let date = parse_date(pub.releaseDate)
              if date != none {
                parts.push([, #date])
              }
            }
            if "status" in pub and pub.status != none {
              if "publisher" not in pub or pub.publisher == none {
                parts.push([ --- #emph[#pub.status]])
              } else {
                parts.push([ (#pub.status)])
              }
            }
            parts.push([.])
            parts.join()
          }
        ]
      }
    }
  ]
}

// ============================================================================
// PROJECTS SECTION
// ============================================================================

#let render_projects(data, config) = {
  if "projects" not in data or data.projects == none or data.projects.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let project_items = filter_by_variant(data.projects, variant)
  if project_items.len() == 0 { return }

  let entry_spacing = config.at("entry_spacing", default: 0.4em)
  let entry_inner_spacing = config.at("entry_inner_spacing", default: 0.15em)

  block(above: 0pt, below: 0pt)[
    == #config.at("projects_title", default: "Projects")

    #for (i, project) in project_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: true)[
        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align: (left, right),
          {
            if "url" in project and project.url != none {
              strong(link(project.url)[#project.name])
            } else {
              strong(project.name)
            }
          },
          [#date_range(project.at("startDate", default: none), project.at("endDate", default: none))],
        )

        #if "affiliation" in project and project.affiliation != none {
          v(entry_inner_spacing)
          text(style: "italic")[#project.affiliation]
        }

        #if "highlights" in project and project.highlights != none and project.highlights.len() > 0 {
          v(entry_inner_spacing * 0.5)
          for highlight in project.highlights {
            [- #highlight]
          }
        }
      ]
    }
  ]
}

// ============================================================================
// AWARDS AND HONORS SECTION
// ============================================================================

#let render_awards(data, config) = {
  if "awards" not in data or data.awards == none or data.awards.len() == 0 { return }

  let variant = config.at("variant", default: "long")
  let award_items = filter_by_variant(data.awards, variant)
  if award_items.len() == 0 { return }

  let entry_spacing = config.at("entry_spacing", default: 0.4em)

  block(above: 0pt, below: 0pt)[
    == #config.at("awards_title", default: "Honors and Awards")

    #for (i, award) in award_items.enumerate() {
      block(width: 100%, above: if i == 0 { 0pt } else { entry_spacing }, below: 0pt, breakable: false)[
        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align: (left, right),
          {
            let title_content = if "url" in award and award.url != none {
              strong(link(award.url)[#award.title])
            } else {
              strong(award.title)
            }
            if "issuer" in award and award.issuer != none {
              [#title_content, #emph(award.issuer)]
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
              right_parts.join([ #sym.bar.v ])
            }
          },
        )

        #if "highlights" in award and award.highlights != none and award.highlights.len() > 0 {
          for highlight in award.highlights {
            [- #highlight]
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
  if "skills" not in data or data.skills == none or data.skills.len() == 0 { return }

  let skill_spacing = config.at("skill_spacing", default: 0.15em)

  block(above: 0pt, below: 0pt)[
    == #config.at("skills_title", default: "Skills")

    #for (i, skill_group) in data.skills.enumerate() {
      block(above: if i == 0 { 0pt } else { skill_spacing }, below: 0pt)[
        #strong(skill_group.category): #skill_group.skills.join(", ")
      ]
    }
  ]
}

// ============================================================================
// LANGUAGES SECTION
// ============================================================================

#let render_languages(data, config) = {
  if "languages" not in data or data.languages == none or data.languages.len() == 0 { return }
  if not config.at("show_languages", default: true) { return }

  block(above: 0pt, below: 0pt)[
    == #config.at("languages_title", default: "Languages")

    #let lang_list = ()
    #for lang in data.languages {
      lang_list.push([#lang.language (#lang.fluency)])
    }
    #lang_list.join([ #sym.bar.v ])
  ]
}

// ============================================================================
// INTERESTS SECTION
// ============================================================================

#let render_interests(data, config) = {
  if "interests" not in data or data.interests == none or data.interests.len() == 0 { return }
  if not config.at("show_interests", default: true) { return }

  block(above: 0pt, below: 0pt)[
    == #config.at("interests_title", default: "Interests")
    #data.interests.join(", ")
  ]
}

// ============================================================================
// REFERENCES SECTION
// ============================================================================

#let render_references(data, config) = {
  if "references" not in data or data.references == none or data.references.len() == 0 { return }
  if not config.at("show_references", default: false) { return }

  block(above: 0pt, below: 0pt)[
    == #config.at("references_title", default: "References")

    #for ref in data.references {
      block(width: 100%, above: 0.3em, below: 0pt)[
        #if "url" in ref and ref.url != none {
          [- #strong(link(ref.url)[#ref.name]): "#ref.reference"]
        } else {
          [- #strong(ref.name): "#ref.reference"]
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
    if "font_size" in fonts { flat.insert("font_size", eval(str(fonts.font_size))) }
    if "name_font_size" in fonts { flat.insert("name_font_size", eval(str(fonts.name_font_size))) }
    if "section_font_size" in fonts { flat.insert("section_font_size", eval(str(fonts.section_font_size))) }
  }

  if "layout" in yaml_config {
    let layout = yaml_config.layout
    if "margin" in layout { flat.insert("margin", eval(str(layout.margin))) }
    if "line_spacing" in layout { flat.insert("line_spacing", eval(str(layout.line_spacing))) }
    if "list_spacing" in layout { flat.insert("list_spacing", eval(str(layout.list_spacing))) }
    if "section_spacing" in layout { flat.insert("section_spacing", eval(str(layout.section_spacing))) }
    if "entry_spacing" in layout { flat.insert("entry_spacing", eval(str(layout.entry_spacing))) }
    if "entry_inner_spacing" in layout { flat.insert("entry_inner_spacing", eval(str(layout.entry_inner_spacing))) }
    if "pub_spacing" in layout { flat.insert("pub_spacing", eval(str(layout.pub_spacing))) }
    if "skill_spacing" in layout { flat.insert("skill_spacing", eval(str(layout.skill_spacing))) }
    if "post_section_spacing" in layout { flat.insert("post_section_spacing", eval(str(layout.post_section_spacing))) }
    if "header_bottom_spacing" in layout {
      flat.insert("header_bottom_spacing", eval(str(layout.header_bottom_spacing)))
    }
  }

  if "styling" in yaml_config {
    let styling = yaml_config.styling
    if "section_smallcaps" in styling { flat.insert("section_smallcaps", styling.section_smallcaps) }
    if "contact_font_size" in styling { flat.insert("contact_font_size", eval(str(styling.contact_font_size))) }
    if "summary_font_size" in styling { flat.insert("summary_font_size", eval(str(styling.summary_font_size))) }
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
