// ============================================================================
// SHORT RESUME VARIANT
// ============================================================================
// Data from resume.yml, config from config-short.yml
// Items with include_short: false in resume.yml will be excluded.
// Compile with: typst compile resume-short.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

#build_resume(resume_data, (:), config_file: "config-short.yml")
