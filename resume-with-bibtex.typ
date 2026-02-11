// ============================================================================
// RESUME WITH BIBTEX PUBLICATIONS
// ============================================================================
// Compile with: typst compile resume-with-bibtex.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume-bibtex.yml")

#let config = (
  bib_style: "ieee",
  variant: "long",
  show_interests_summary: false,
  show_publication_numbers: true,
  publication_number_width: 2.2em,
  publications_title: "Selected Publications",
  section_order: (
    "work",
    "education",
    "publications",
    "skills",
    "languages",
  ),
)

#build_resume(resume_data, config, config_file: "config.yml", bib_file: "publications.bib")
