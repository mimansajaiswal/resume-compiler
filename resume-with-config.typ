// ============================================================================
// RESUME WITH EXTERNAL CONFIG
// ============================================================================
// This file demonstrates using an external config.yml file.
// All settings are loaded from config.yml
// Compile with: typst compile resume-with-config.typ
// ============================================================================

#import "template.typ": build_resume

// Load resume data from YAML file
#let resume_data = yaml("resume.yml")

// Optional: Override specific settings inline (these take precedence over config.yml)
#let config_overrides = (
  // Example: Uncomment to override settings from config.yml
  // variant: "short",
  // show_phone: false,
)

// Build resume using external config.yml
#build_resume(resume_data, config_overrides, config_file: "config.yml")
