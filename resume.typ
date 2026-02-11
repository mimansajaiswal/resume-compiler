// ============================================================================
// MAIN RESUME ENTRYPOINT (Config-Driven)
// ============================================================================
// Data from resume.yml, settings from config.yml
// Compile with: typst compile resume.typ
// ============================================================================

#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

#build_resume(resume_data, (:), config_file: "config.yml")
