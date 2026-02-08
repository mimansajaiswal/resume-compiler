// ============================================================================
// MAIN RESUME FILE (Long Variant)
// ============================================================================
// Data from resume.yml, config from config.yml
// Compile with: typst compile resume.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

#build_resume(resume_data, (:), config_file: "config.yml")
