// ============================================================================
// TYPST RESUME TEMPLATE - Highly Configurable YAML-Based Resume System
// ============================================================================
// This template provides modular, reusable functions for rendering resumes
// from YAML data. It's designed to be flexible and easy to customize.
//
// Based on concepts from NNJR and imprecv templates, adapted for maximum
// configurability and ATS-friendliness.
// ============================================================================

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Filter items based on resume variant (long/short)
#let filter_by_variant(items, variant) = {
  if variant == "long" {
    return items
  }

  // For short variant, filter items
  items.filter(item => {
    // Include item if:
    // 1. No include_short field (default to include)
    // 2. include_short is explicitly true
    let should_include = item.at("include_short", default: true)
    should_include == true
  })
}

// Format month number to month name
#let month_name(n, display: "short") = {
  n = int(n)
  let months = (
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  )

  if n >= 1 and n <= 12 {
    let month = months.at(n - 1)
    if display == "short" {
      month.slice(0, 3)
    } else {
      month
    }
  } else {
    none
  }
}

// Parse ISO date string (YYYY-MM-DD) to formatted date
#let parse_date(date_str) = {
  if date_str == none or date_str == "" {
    return none
  }

  let date_lower = lower(str(date_str))
  if date_lower == "present" {
    return "Present"
  }

  // Parse YYYY-MM-DD format
  let year = int(date_str.slice(0, 4))
  let month = int(date_str.slice(5, 7))
  let month_str = month_name(month, display: "short")

  return month_str + " " + str(year)
}

// Format date range
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
// DOCUMENT SETUP FUNCTIONS
// ============================================================================

// Apply document-wide settings
#let apply_settings(config, doc) = {
  set page(
    paper: "us-letter",
    margin: config.at("margin", default: 0.5in),
  )

  set text(
    font: config.at("body_font", default: "New Computer Modern"),
    size: config.at("font_size", default: 11pt),
    hyphenate: false,
  )

  set par(
    leading: config.at("line_spacing", default: 0.65em),
    justify: true,
  )

  set list(
    indent: 1em,
    spacing: config.at("list_spacing", default: 0.65em),
  )

  // Show rules for links
  show link: underline
  show link: set underline(offset: 3pt)

  doc
}

// Apply heading styles
#let apply_heading_styles(config, doc) = {
  // Main name heading (level 1)
  show heading.where(level: 1): it => block(width: 100%)[
    #set text(
      font: config.at("heading_font", default: "New Computer Modern"),
      size: config.at("name_font_size", default: 2.25em),
      weight: "bold"
    )
    #it.body
  ]

  // Section headings (level 2)
  show heading.where(level: 2): it => block(width: 100%)[
    #v(config.at("section_spacing", default: 0.8em))
    #set text(
      font: config.at("heading_font", default: "New Computer Modern"),
      size: config.at("section_font_size", default: 1em),
      weight: "bold"
    )
    #if config.at("section_smallcaps", default: true) {
      smallcaps(it.body)
    } else {
      upper(it.body)
    }
    #v(-0.4em)
    #line(length: 100%, stroke: 1pt + black)
  ]

  doc
}

// ============================================================================
// HEADER / CONTACT INFORMATION
// ============================================================================

#let render_header(data, config) = {
  let personal = data.at("personal", default: none)
  if personal == none {
    return
  }

  align(center)[
    // Name
    = #personal.name

    #v(-0.5em)

    // Titles (if present)
    #if "titles" in personal and personal.titles != none and personal.titles.len() > 0 {
      block[
        #set text(size: 0.95em, weight: "medium")
        #personal.titles.join(" | ")
      ]
      v(-0.3em)
    }

    // Location (if present and config allows)
    #if config.at("show_location", default: true) {
      if "location" in personal and personal.location != none {
        let loc = personal.location
        let parts = ()
        if "city" in loc and loc.city != none and loc.city != "" { parts.push(loc.city) }
        if "region" in loc and loc.region != none and loc.region != "" { parts.push(loc.region) }
        if "country" in loc and loc.country != none and loc.country != "" { parts.push(loc.country) }
        if parts.len() > 0 {
          block[
            #set text(size: 0.9em)
            #parts.join(", ")
          ]
          v(-0.3em)
        }
      }
    }

    // Contact information
    #block[
      #set text(size: 0.95em)
      #let contacts = ()

      // Email
      #if "email" in personal and personal.email != none {
        contacts.push(link("mailto:" + personal.email)[#personal.email])
      }

      // Phone (if config allows)
      #if config.at("show_phone", default: true) {
        if "phone" in personal and personal.phone != none {
          contacts.push(link("tel:" + personal.phone)[#personal.phone])
        }
      }

      // Website
      #if "url" in personal and personal.url != none {
        let display_url = personal.url.split("//").at(-1)
        contacts.push(link(personal.url)[#display_url])
      }

      // Social profiles
      #if "profiles" in personal and personal.profiles != none {
        for profile in personal.profiles {
          let display_url = profile.url.split("//").at(-1)
          contacts.push(link(profile.url)[#display_url])
        }
      }

      #contacts.join([  #sym.diamond.filled  ])
    ]
  ]

  v(0.5em)
}

// ============================================================================
// INTERESTS / SUMMARY SECTION
// ============================================================================

#let render_interests_summary(data, config) = {
  if not config.at("show_interests_summary", default: false) {
    return
  }

  if "interests_summary" in data and data.interests_summary != none {
    block[
      == Interests
      #data.interests_summary
    ]
  }
}

// ============================================================================
// WORK EXPERIENCE SECTION
// ============================================================================

#let render_work(data, config) = {
  if "work" not in data or data.work == none or data.work.len() == 0 {
    return
  }

  // Filter work entries by variant
  let variant = config.at("variant", default: "long")
  let work_items = filter_by_variant(data.work, variant)

  if work_items.len() == 0 {
    return
  }

  block[
    == #config.at("work_title", default: "Experience")

    #for work in work_items {
      block(width: 100%, above: 0.7em, below: 0.7em)[
        // Organization name and location
        #grid(
          columns: (1fr, auto),
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
              strong(work.location)
            }
          }
        )

        // Positions within this organization
        #if "positions" in work and work.positions != none {
          let positions = filter_by_variant(work.positions, variant)
          for position in positions {
            v(0.4em)

            // Position title and date range
            grid(
              columns: (1fr, auto),
              align: (left, right),
              [
                #text(style: "italic")[#position.position]
              ],
              [
                #date_range(position.at("startDate", default: none), position.at("endDate", default: none))
              ]
            )

            // Highlights/responsibilities
            if "highlights" in position and position.highlights != none and position.highlights.len() > 0 {
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
  if "education" not in data or data.education == none or data.education.len() == 0 {
    return
  }

  // Filter education entries by variant
  let variant = config.at("variant", default: "long")
  let edu_items = filter_by_variant(data.education, variant)

  if edu_items.len() == 0 {
    return
  }

  block[
    == #config.at("education_title", default: "Education")

    #for edu in edu_items {
      block(width: 100%, above: 0.7em, below: 0.7em)[
        // Institution name and location
        #grid(
          columns: (1fr, auto),
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
              strong(edu.location)
            }
          }
        )

        // Degree and date range
        #grid(
          columns: (1fr, auto),
          align: (left, right),
          [
            #text(style: "italic")[
              #if "studyType" in edu and edu.studyType != none {
                edu.studyType
              }
              #if "area" in edu and edu.area != none {
                [ in #edu.area]
              }
            ]
          ],
          [
            #date_range(edu.at("startDate", default: none), edu.at("endDate", default: none))
          ]
        )

        // Honors
        #if "honors" in edu and edu.honors != none and edu.honors.len() > 0 {
          [- #strong[Honors]: #edu.honors.join(", ")]
        }

        // Courses
        #if "courses" in edu and edu.courses != none and edu.courses.len() > 0 {
          [- #strong[Coursework]: #edu.courses.join(", ")]
        }

        // Additional highlights
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
// PUBLICATIONS SECTION (WITH BIBTEX SUPPORT)
// ============================================================================

// Format publication from BibTeX entry using Typst's built-in bibliography
// This is a helper that formats a single BibTeX entry
#let format_bib_entry(bib_key, bib_file, style: "ieee", extra_links: ()) = {
  // Return a formatted citation with extra links
  // Note: This uses Typst's citation feature
  [
    #cite(label(bib_key), form: "full", style: style)
    #if extra_links.len() > 0 {
      [ \ ]
      for link_info in extra_links {
        if "label" in link_info and "url" in link_info {
          [[#link(link_info.url)[#link_info.label]]]
          if link_info != extra_links.last() {
            [ | ]
          }
        }
      }
    }
  ]
}

#let render_publications(data, config) = {
  if "publications" not in data or data.publications == none or data.publications.len() == 0 {
    return
  }

  // Filter publications by variant
  let variant = config.at("variant", default: "long")
  let pub_items = filter_by_variant(data.publications, variant)

  if pub_items.len() == 0 {
    return
  }

  block[
    == #config.at("publications_title", default: "Publications")

    #for pub in pub_items {
      // Check if this is a BibTeX reference or YAML entry
      if "bib_key" in pub {
        // BibTeX entry: use formatted citation
        let extra_links = pub.at("links", default: ())

        block(width: 100%, above: 0.6em, below: 0.6em)[
          // Format: Citation + extra links (code, data, etc.)
          #cite(label(pub.bib_key), form: "full")

          // Add extra links if present
          #if extra_links.len() > 0 {
            [ \ ]
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
        // YAML entry: use manual formatting (original behavior)
        block(width: 100%, above: 0.6em, below: 0.6em)[
          // Publication title
          #{
            if "url" in pub and pub.url != none {
              strong(link(pub.url)[#pub.name])
            } else {
              strong(pub.name)
            }
          }

          // Authors (if present)
          #if "authors" in pub and pub.authors != none {
            [ \ #pub.authors]
          }

          // Venue and date
          #if "publisher" in pub and pub.publisher != none {
            [ \ #emph(pub.publisher)]
          }
          #if "releaseDate" in pub and pub.releaseDate != none {
            let date = parse_date(pub.releaseDate)
            if date != none {
              [, #date]
            }
          }

          // Status (for submitted/in-progress works)
          #if "status" in pub and pub.status != none {
            [ \ #emph[Status: #pub.status]]
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
  if "projects" not in data or data.projects == none or data.projects.len() == 0 {
    return
  }

  // Filter projects by variant
  let variant = config.at("variant", default: "long")
  let project_items = filter_by_variant(data.projects, variant)

  if project_items.len() == 0 {
    return
  }

  block[
    == #config.at("projects_title", default: "Projects")

    #for project in project_items {
      block(width: 100%, above: 0.7em, below: 0.7em)[
        // Project name and date
        #grid(
          columns: (1fr, auto),
          align: (left, right),
          {
            if "url" in project and project.url != none {
              strong(link(project.url)[#project.name])
            } else {
              strong(project.name)
            }
          },
          [
            #date_range(project.at("startDate", default: none), project.at("endDate", default: none))
          ]
        )

        // Affiliation/organization
        #if "affiliation" in project and project.affiliation != none {
          text(style: "italic")[#project.affiliation]
        }

        // Highlights/description
        #if "highlights" in project and project.highlights != none and project.highlights.len() > 0 {
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
  if "awards" not in data or data.awards == none or data.awards.len() == 0 {
    return
  }

  // Filter awards by variant
  let variant = config.at("variant", default: "long")
  let award_items = filter_by_variant(data.awards, variant)

  if award_items.len() == 0 {
    return
  }

  block[
    == #config.at("awards_title", default: "Honors and Awards")

    #for award in award_items {
      block(width: 100%, above: 0.6em, below: 0.6em)[
        // Award title and location
        #grid(
          columns: (1fr, auto),
          align: (left, right),
          {
            if "url" in award and award.url != none {
              strong(link(award.url)[#award.title])
            } else {
              strong(award.title)
            }
          },
          {
            if "location" in award and award.location != none {
              strong(award.location)
            }
          }
        )

        // Issuer and date
        #if "issuer" in award and award.issuer != none {
          [Issued by #emph(award.issuer)]
        }
        #if "date" in award and award.date != none {
          let date = parse_date(award.date)
          if date != none {
            [ #h(1fr) #date]
          }
        }

        // Additional highlights
        #if "highlights" in award and award.highlights != none and award.highlights.len() > 0 {
          for highlight in award.highlights {
            [\ - #highlight]
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
  if "skills" not in data or data.skills == none or data.skills.len() == 0 {
    return
  }

  block[
    == #config.at("skills_title", default: "Skills")

    #for skill_group in data.skills {
      block(above: 0.5em)[
        #set text(size: 0.95em)
        #strong(skill_group.category): #skill_group.skills.join(", ")
      ]
    }
  ]
}

// ============================================================================
// LANGUAGES SECTION
// ============================================================================

#let render_languages(data, config) = {
  if "languages" not in data or data.languages == none or data.languages.len() == 0 {
    return
  }

  if not config.at("show_languages", default: true) {
    return
  }

  block[
    == #config.at("languages_title", default: "Languages")

    #let lang_list = ()
    #for lang in data.languages {
      lang_list.push([#lang.language (#lang.fluency)])
    }

    #lang_list.join(", ")
  ]
}

// ============================================================================
// INTERESTS SECTION (as list)
// ============================================================================

#let render_interests(data, config) = {
  if "interests" not in data or data.interests == none or data.interests.len() == 0 {
    return
  }

  if not config.at("show_interests", default: true) {
    return
  }

  block[
    == #config.at("interests_title", default: "Interests")

    #data.interests.join(", ")
  ]
}

// ============================================================================
// REFERENCES SECTION
// ============================================================================

#let render_references(data, config) = {
  if "references" not in data or data.references == none or data.references.len() == 0 {
    return
  }

  if not config.at("show_references", default: false) {
    return
  }

  block[
    == #config.at("references_title", default: "References")

    #for ref in data.references {
      block(width: 100%, above: 0.6em)[
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

// Flatten nested YAML config into flat config dictionary
#let flatten_config(yaml_config) = {
  let flat = (:)

  // Variant
  if "variant" in yaml_config {
    flat.insert("variant", yaml_config.variant)
  }

  // Fonts
  if "fonts" in yaml_config {
    let fonts = yaml_config.fonts
    if "heading_font" in fonts { flat.insert("heading_font", fonts.heading_font) }
    if "body_font" in fonts { flat.insert("body_font", fonts.body_font) }
    if "font_size" in fonts { flat.insert("font_size", eval(str(fonts.font_size))) }
    if "name_font_size" in fonts { flat.insert("name_font_size", eval(str(fonts.name_font_size))) }
    if "section_font_size" in fonts { flat.insert("section_font_size", eval(str(fonts.section_font_size))) }
  }

  // Layout
  if "layout" in yaml_config {
    let layout = yaml_config.layout
    if "margin" in layout { flat.insert("margin", eval(str(layout.margin))) }
    if "line_spacing" in layout { flat.insert("line_spacing", eval(str(layout.line_spacing))) }
    if "list_spacing" in layout { flat.insert("list_spacing", eval(str(layout.list_spacing))) }
    if "section_spacing" in layout { flat.insert("section_spacing", eval(str(layout.section_spacing))) }
  }

  // Styling
  if "styling" in yaml_config {
    let styling = yaml_config.styling
    if "section_smallcaps" in styling { flat.insert("section_smallcaps", styling.section_smallcaps) }
  }

  // Visibility
  if "visibility" in yaml_config {
    let visibility = yaml_config.visibility
    if "show_location" in visibility { flat.insert("show_location", visibility.show_location) }
    if "show_phone" in visibility { flat.insert("show_phone", visibility.show_phone) }
    if "show_interests_summary" in visibility { flat.insert("show_interests_summary", visibility.show_interests_summary) }
    if "show_languages" in visibility { flat.insert("show_languages", visibility.show_languages) }
    if "show_interests" in visibility { flat.insert("show_interests", visibility.show_interests) }
    if "show_references" in visibility { flat.insert("show_references", visibility.show_references) }
  }

  // Section titles
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
    if "references" in titles { flat.insert("references_title", titles.references) }
  }

  // Section order
  if "section_order" in yaml_config {
    flat.insert("section_order", yaml_config.section_order)
  }

  return flat
}

// Load config from YAML file and merge with provided config
#let load_config(config_file: none, inline_config: (:)) = {
  // Start with file config as base
  let final_config = (:)

  // If config file specified, load it as base
  if config_file != none {
    let yaml_config = yaml(config_file)
    final_config = flatten_config(yaml_config)
  }

  // Merge inline_config on top (takes precedence)
  for (key, value) in inline_config {
    final_config.insert(key, value)
  }

  return final_config
}

// ============================================================================
// MAIN RESUME BUILDER FUNCTION
// ============================================================================

#let build_resume(data, config, config_file: none, bib_file: none) = {
  // Load and merge config from file if provided
  let merged_config = load_config(config_file: config_file, inline_config: config)
  let config = merged_config

  // Store bib_file in config if provided
  if bib_file != none {
    config.insert("bib_file", bib_file)
  }

  // Apply document settings
  show: doc => apply_settings(config, doc)
  show: doc => apply_heading_styles(config, doc)

  // If bib_file is specified, set up bibliography (hidden, only for citations)
  if bib_file != none {
    show bibliography: none  // Hide default bibliography section
    bibliography(bib_file, style: config.at("bib_style", default: "ieee"))
  }

  // Render header
  render_header(data, config)

  // Render sections in configured order
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
  }
}
