// ============================================================================
// RESUME WITH BIBTEX PUBLICATIONS
// ============================================================================
// This file demonstrates using BibTeX for publications with custom links
// Compile with: typst compile resume-with-bibtex.typ
// ============================================================================

#import "template.typ": build_resume

// Load resume data (with bib_key references)
#let resume_data = yaml("resume-bibtex.yml")

// Configuration
#let config = (
  // Fonts and sizes
  heading_font: "New Computer Modern",
  body_font: "New Computer Modern",
  font_size: 11pt,
  name_font_size: 2.25em,

  // Layout
  margin: 0.5in,
  line_spacing: 0.65em,
  section_spacing: 0.8em,

  // Variant
  variant: "long",

  // BibTeX style
  bib_style: "ieee",  // Options: "ieee", "apa", "chicago-author-date", etc.

  // Visibility
  show_location: false,
  show_phone: true,
  show_interests_summary: false,
  show_languages: true,
  show_interests: false,
  show_references: false,

  // Section styling
  section_smallcaps: true,

  // Section titles
  work_title: "Experience",
  education_title: "Education",
  publications_title: "Publications",
  skills_title: "Skills",
  languages_title: "Languages",

  // Section order
  section_order: (
    "work",
    "education",
    "publications",
    "skills",
    "languages",
  ),
)

// Build resume with BibTeX file
#build_resume(resume_data, config, bib_file: "publications.bib")
