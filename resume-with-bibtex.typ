// ============================================================================
// RESUME WITH BIBTEX PUBLICATIONS
// ============================================================================
// Compile with: typst compile resume-with-bibtex.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume-bibtex.yml")

#let config = (
  heading_font: "New Computer Modern",
  body_font: "New Computer Modern",
  font_size: 10pt,
  name_font_size: 1.8em,
  section_font_size: 1em,
  margin: 0.5in,
  line_spacing: 0.5em,
  list_spacing: 0.4em,
  section_spacing: 0.6em,
  post_section_spacing: 0.15em,
  entry_spacing: 0.4em,
  entry_inner_spacing: 0.15em,
  pub_spacing: 0.5em,
  skill_spacing: 0.15em,
  header_bottom_spacing: 0.2em,
  variant: "long",
  bib_style: "ieee",
  section_smallcaps: true,
  contact_font_size: 0.85em,
  summary_font_size: 0.92em,
  show_location: false,
  show_phone: true,
  show_interests_summary: false,
  show_languages: true,
  show_interests: false,
  show_references: false,
  work_title: "Experience",
  education_title: "Education",
  publications_title: "Publications",
  skills_title: "Skills",
  languages_title: "Languages",
  section_order: (
    "work",
    "education",
    "publications",
    "skills",
    "languages",
  ),
)

#build_resume(resume_data, config, bib_file: "publications.bib")
