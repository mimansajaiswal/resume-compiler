// ============================================================================
// SHORT RESUME VARIANT
// ============================================================================
// This file generates a shorter version of your resume.
// Items marked with include_short: false in resume.yml will be excluded.
// Compile with: typst compile resume-short.typ
// ============================================================================

#import "template.typ": build_resume

// Load resume data from YAML file
#let resume_data = yaml("resume.yml")

// ============================================================================
// CONFIGURATION FOR SHORT RESUME
// ============================================================================

#let config = (
  // Fonts and sizes (same as long version)
  heading_font: "New Computer Modern",
  body_font: "New Computer Modern",
  font_size: 11pt,
  name_font_size: 2.25em,
  section_font_size: 1em,

  // Spacing and layout (same as long version)
  margin: 0.5in,
  line_spacing: 0.65em,
  list_spacing: 0.65em,
  section_spacing: 0.8em,

  // ----------------------------------------------------------------------------
  // KEY DIFFERENCE: Set variant to "short"
  // ----------------------------------------------------------------------------
  variant: "short",                           // Filters out items with include_short: false

  // Section styling
  section_smallcaps: true,

  // Visibility toggles
  show_location: false,
  show_phone: true,
  show_interests_summary: false,              // Often hide summary in short version
  show_languages: false,                      // Often hide languages in short version
  show_interests: false,
  show_references: false,

  // Section titles
  work_title: "Experience",
  education_title: "Education",
  publications_title: "Selected Publications",  // Note: "Selected"
  projects_title: "Projects",
  awards_title: "Honors and Awards",
  skills_title: "Skills",
  languages_title: "Languages",
  interests_title: "Interests",
  references_title: "References",

  // Section order (can be different from long version)
  section_order: (
    "work",                // Start with experience
    "education",           // Then education
    "publications",        // Key publications only
    "awards",              // Awards (filtered)
    "skills",              // Skills
    // "projects",         // Often omit projects in short version
    // "languages",        // Hidden by show_languages: false
    // "interests",        // Hidden
  ),
)

// ============================================================================
// BUILD SHORT RESUME
// ============================================================================

#build_resume(resume_data, config)
