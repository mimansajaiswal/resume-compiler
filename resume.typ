// ============================================================================
// MAIN RESUME FILE
// ============================================================================
// This is the main entry point for your resume.
// 1. Edit resume.yml with your personal data
// 2. Customize the configuration below (optional)
// 3. Compile with: typst compile resume.typ
// ============================================================================

#import "template.typ": build_resume

// Load resume data from YAML file
#let resume_data = yaml("resume.yml")

// ============================================================================
// CONFIGURATION
// ============================================================================
// Customize these settings to match your preferences.
// All settings are optional - defaults will be used if not specified.
// ============================================================================

#let config = (
  // ----------------------------------------------------------------------------
  // FONTS AND SIZES
  // ----------------------------------------------------------------------------
  heading_font: "New Computer Modern",        // Font for name and section headings
  body_font: "New Computer Modern",           // Font for body text
  font_size: 11pt,                            // Base font size
  name_font_size: 2.25em,                     // Size for your name
  section_font_size: 1em,                     // Size for section headings

  // ----------------------------------------------------------------------------
  // SPACING AND LAYOUT
  // ----------------------------------------------------------------------------
  margin: 0.5in,                              // Page margins
  line_spacing: 0.65em,                       // Space between lines
  list_spacing: 0.65em,                       // Space between list items
  section_spacing: 0.8em,                     // Space before section headings

  // ----------------------------------------------------------------------------
  // RESUME VARIANT
  // ----------------------------------------------------------------------------
  variant: "long",                            // "long" or "short" - filters items by include_short field

  // ----------------------------------------------------------------------------
  // SECTION HEADINGS STYLE
  // ----------------------------------------------------------------------------
  section_smallcaps: true,                    // Use small caps for sections (true/false)

  // ----------------------------------------------------------------------------
  // VISIBILITY TOGGLES
  // ----------------------------------------------------------------------------
  // Control what information to show/hide
  show_location: false,                       // Show location in header
  show_phone: true,                           // Show phone number
  show_interests_summary: true,               // Show interests paragraph at top
  show_languages: true,                       // Show languages section
  show_interests: false,                      // Show interests list at bottom
  show_references: false,                     // Show references section

  // ----------------------------------------------------------------------------
  // SECTION TITLES
  // ----------------------------------------------------------------------------
  // Customize section headings
  work_title: "Experience",
  education_title: "Education",
  publications_title: "Publications",
  projects_title: "Projects",
  awards_title: "Honors and Awards",
  skills_title: "Skills",
  languages_title: "Languages",
  interests_title: "Interests",
  references_title: "References",

  // ----------------------------------------------------------------------------
  // SECTION ORDER
  // ----------------------------------------------------------------------------
  // Define which sections to show and in what order
  // Comment out or remove any section you don't want to display
  section_order: (
    "interests_summary",   // Research interests paragraph
    "work",                // Work experience
    "education",           // Education
    "publications",        // Publications (includes all publications from YAML)
    "awards",              // Honors and awards
    "skills",              // Skills
    "languages",           // Languages
    // "projects",         // Projects (currently commented out)
    // "interests",        // Interests list
    // "references",       // References
  ),
)

// ============================================================================
// BUILD RESUME
// ============================================================================
// This calls the template to build your resume
// You don't need to modify anything below this line
// ============================================================================

#build_resume(resume_data, config)
