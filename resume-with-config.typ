// ============================================================================
// RESUME WITH EXTERNAL CONFIG
// ============================================================================
// All settings loaded from config.yml. Override inline if needed.
// Compile with: typst compile resume-with-config.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

#let config_overrides = (
  // Uncomment to override settings from config.yml:
  // variant: "short",
  // show_phone: false,
)

#build_resume(resume_data, config_overrides, config_file: "config.yml")
