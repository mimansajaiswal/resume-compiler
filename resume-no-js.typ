// ============================================================================
// NO-JS / PLAIN-TEXT LINK VARIANT
// ============================================================================
// Uses the main config, but disables active hyperlinks for plain-text output.
// Compile with: typst compile resume-no-js.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

#let no_js_overrides = (
  enable_links: false,
  strip_link_labels_when_links_disabled: true,
)

#build_resume(resume_data, no_js_overrides, config_file: "config.yml")
