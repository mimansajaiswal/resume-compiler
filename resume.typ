// ============================================================================
// SINGLE RESUME ENTRYPOINT (Mode-Driven)
// ============================================================================
// Compile examples:
//   typst compile resume.typ
//   typst compile --input mode=short resume.typ
//   typst compile --input mode="no-js+short" resume.typ
//   typst compile --input mode=bibtex resume.typ
//   typst compile --input mode="bibtex+short" resume.typ
// ============================================================================

#import "template.typ": build_resume

#let normalize_mode(mode) = {
  lower(str(mode).trim()).replace(" ", "").replace("_", "").replace("-", "").replace("+", "")
}

#let build_resume_by_mode(
  mode: "default",
  runtime_overrides: (:),
  resume_file: "resume.yml",
  bib_resume_file: "resume-bibtex.yml",
  config_long_file: "config.yml",
  config_short_file: "config-short.yml",
  bib_file: "publications.bib",
) = {
  let m = normalize_mode(mode)
  let use_short = m.contains("short")
  let use_bib = m.contains("bibtex")
  let use_no_js = m.contains("nojs")

  let config_file = if use_short { config_short_file } else { config_long_file }
  let active_resume_file = if use_bib { bib_resume_file } else { resume_file }
  let resume_data = yaml(active_resume_file)
  let overrides = runtime_overrides

  if use_no_js {
    overrides.insert("enable_links", false)
  }

  if use_bib {
    build_resume(resume_data, overrides, config_file: config_file, bib_file: bib_file)
  } else {
    build_resume(resume_data, overrides, config_file: config_file)
  }
}

#let runtime_overrides = {
  let out = (:)
  if "last_updated" in sys.inputs {
    out.insert("last_updated", str(sys.inputs.at("last_updated")))
  }
  out
}

#let selected_mode = sys.inputs.at("mode", default: "default")
#build_resume_by_mode(mode: selected_mode, runtime_overrides: runtime_overrides)
