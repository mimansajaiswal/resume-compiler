# Typst Resume Template with YAML

A highly configurable, ATS-friendly resume template for [Typst](https://typst.app/) that uses YAML for data storage. Perfect for academics, researchers, and professionals who want to maintain their resume data separately from formatting.

## Features

- **YAML-based data storage** - Easy to maintain and version control
- **Long/Short resume variants** - Create multiple versions from one data file
- **External configuration** - Manage settings in `config.yml`
- **BibTeX support** - Professional citation formatting with custom links
- **GitHub Actions** - Automatic PDF generation and cloud upload
- **Highly configurable** - Customize fonts, spacing, colors, and section order
- **ATS-friendly** - Single-column layout that parses well in Applicant Tracking Systems
- **Academic-focused** - Built-in support for publications, research projects, awards
- **Zero code required** - Just edit YAML and configuration settings

## Quick Start

### Prerequisites

Install Typst:
- **Typst CLI**: Download from [github.com/typst/typst/releases](https://github.com/typst/typst/releases)
- **Typst Web**: Use [typst.app](https://typst.app/) online editor

### Basic Usage

1. **Edit your data** - Modify `resume.yml` with your personal information
2. **Customize settings** (optional) - Adjust configuration in `resume.typ` or `config.yml`
3. **Compile**:
   ```bash
   typst compile resume.typ
   ```

This generates `resume.pdf` in the same directory.

### Watch Mode (Auto-compile on changes)

```bash
typst watch resume.typ
```

## File Structure

```
resume_typst/
├── README.md                       # This file
├── template.typ                    # Core template library (18KB)
│
├── resume.typ                      # Main long resume
├── resume-short.typ                # Short resume variant
├── resume-with-config.typ          # Using external config
├── resume-with-bibtex.typ          # With BibTeX citations
│
├── resume.yml                      # Your resume data
├── resume-bibtex.yml               # Example with BibTeX references
├── example.yml                     # Reference example
│
├── config.yml                      # External configuration (long)
├── config-short.yml                # External configuration (short)
│
├── publications.bib                # BibTeX bibliography
│
├── .github/workflows/
│   ├── build-resume.yml           # Auto-build PDFs
│   └── upload-to-cloud.yml        # Upload to cloud storage
│
└── .gitignore                     # Ignores PDF outputs
```

## Core Usage Patterns

### Pattern 1: Basic YAML Resume (Simplest)

**Files:** `resume.yml` + `resume.typ`

```bash
# Edit your data
vim resume.yml

# Compile
typst compile resume.typ
```

**Best for:** Quick updates, simple resumes, learning the system

---

### Pattern 2: Long/Short Variants

**Files:** `resume.yml` (with `include_short` flags) + `resume.typ` + `resume-short.typ`

Add `include_short: false` to exclude items from short version:

```yaml
publications:
  - name: "Important Paper"
    include_short: true   # In both versions

  - name: "Minor Paper"
    include_short: false  # Only in long version
```

Compile both:
```bash
typst compile resume.typ        # Long (all items)
typst compile resume-short.typ  # Short (filtered)
```

**Best for:** Job applications (short) vs academic CVs (long)

---

### Pattern 3: External Configuration

**Files:** `resume.yml` + `config.yml` + `resume-with-config.typ`

Store all settings in `config.yml`:

```yaml
# config.yml
variant: long
fonts:
  heading_font: "New Computer Modern"
  font_size: 11pt
layout:
  margin: 0.5in
visibility:
  show_phone: true
  show_interests_summary: true
section_order:
  - work
  - education
  - publications
```

Compile:
```bash
typst compile resume-with-config.typ
```

**Best for:** Managing multiple resume styles, team templates

---

### Pattern 4: BibTeX Publications

**Files:** `publications.bib` + `resume-bibtex.yml` + `resume-with-bibtex.typ`

1. Create `publications.bib`:
```bibtex
@article{smith2024,
  title={Your Paper Title},
  author={Smith, John},
  journal={Conference Name},
  year={2024},
  url={https://arxiv.org/...}
}
```

2. Reference in `resume-bibtex.yml`:
```yaml
publications:
  - bib_key: smith2024
    links:
      - label: "Paper"
        url: "https://arxiv.org/..."
      - label: "Code"
        url: "https://github.com/..."
      - label: "Data"
        url: "https://dataset.com/..."
```

3. Compile:
```bash
typst compile resume-with-bibtex.typ
```

**Best for:** Academics with many publications, maintaining consistency with other documents

---

## Detailed Feature Guide

### Feature 1: Long/Short Resume Variants

Create multiple resume versions from a single data file by marking items for inclusion:

#### How to Use

Add `include_short: false` to any entry in `resume.yml`:

```yaml
work:
  # This entire work entry excluded from short version
  - organization: Company Name
    include_short: false
    positions: [...]

  # Keep in both versions
  - organization: Current Company
    positions:
      # Include this position in short version
      - position: Senior Role
        include_short: true
        highlights: [...]

      # Exclude this older position from short
      - position: Junior Role
        include_short: false
        highlights: [...]

publications:
  # Top papers in short version
  - name: "Important Paper"
    include_short: true

  # Exclude from short version
  - name: "Workshop Paper"
    include_short: false
```

#### Configuration

Set `variant` in your .typ file:

```typst
#let config = (
  variant: "long",  // or "short"
  // ... other settings
)
```

Or use the pre-configured files:
- `resume.typ` → variant: "long"
- `resume-short.typ` → variant: "short"

#### Default Behavior

If `include_short` is not specified, items are included in both versions by default.

---

### Feature 2: External Configuration (`config.yml`)

Separate your settings from your resume logic for easier management.

#### Structure

```yaml
# config.yml
variant: long

fonts:
  heading_font: "New Computer Modern"
  body_font: "New Computer Modern"
  font_size: 11pt
  name_font_size: 2.25em

layout:
  margin: 0.5in
  line_spacing: 0.65em
  section_spacing: 0.8em

styling:
  section_smallcaps: true

visibility:
  show_location: false
  show_phone: true
  show_interests_summary: true
  show_languages: true
  show_references: false

section_titles:
  work: "Experience"
  education: "Education"
  publications: "Publications"

section_order:
  - interests_summary
  - work
  - education
  - publications
  - awards
  - skills
```

#### Usage

```typst
// resume-with-config.typ
#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")

// Optional inline overrides
#let config_overrides = (
  // Uncomment to override config.yml settings
  // variant: "short",
  // show_phone: false,
)

#build_resume(resume_data, config_overrides, config_file: "config.yml")
```

#### Multiple Configs

Create different config files for different purposes:

- `config.yml` - Default long resume
- `config-short.yml` - Short resume with different sections
- `config-academic.yml` - Academic CV format
- `config-industry.yml` - Industry resume format

Switch by changing the file reference in your .typ file.

---

### Feature 3: BibTeX Integration

Use BibTeX for professional citation formatting with support for custom links.

#### Setup

1. **Create `publications.bib`:**

```bibtex
@article{jaiswal2024emotion,
  title={From Text to Emotion: Unveiling the Emotion Annotation Capabilities of LLMs},
  author={Niu, Minxue and Jaiswal, Mimansa and Provost, Emily Mower},
  journal={Interspeech 2024},
  year={2024},
  url={https://arxiv.org/pdf/2408.17026}
}

@inproceedings{jaiswal2020privacy,
  title={Privacy Enhanced Multimodal Neural Representations for Emotion Recognition},
  author={Jaiswal, Mimansa and Provost, Emily Mower},
  booktitle={AAAI Conference on Artificial Intelligence},
  year={2020}
}
```

2. **Reference in YAML with custom links:**

```yaml
publications:
  # BibTeX entry with custom links
  - bib_key: jaiswal2024emotion
    links:
      - label: "Paper"
        url: "https://arxiv.org/pdf/2408.17026"
      - label: "Code"
        url: "https://github.com/example/code"
      - label: "Demo"
        url: "https://demo.example.com"

  # BibTeX entry without extra links
  - bib_key: jaiswal2020privacy

  # Mix YAML and BibTeX formats
  - name: "Work in Progress: CAPSTONE"
    authors: "Mimansa Jaiswal"
    status: "Research Notes"
    url: "https://example.com"
```

3. **Configure and compile:**

```typst
#let config = (
  bib_style: "ieee",  // Options: "ieee", "apa", "chicago-author-date"
  // ... other settings
)

#build_resume(resume_data, config, bib_file: "publications.bib")
```

#### Citation Styles

Supported styles:
- `"ieee"` - IEEE (default)
- `"apa"` - APA 7th edition
- `"chicago-author-date"` - Chicago author-date
- `"mla"` - MLA 9th edition
- `"vancouver"` - Vancouver
- See [Typst documentation](https://typst.app/docs/reference/model/bibliography/) for more

#### Mixing YAML and BibTeX

You can mix both formats in the same `publications` section:
- Entries with `bib_key` → formatted via BibTeX
- Entries without `bib_key` → formatted manually (YAML)

This is useful for:
- Works in progress (not yet in BibTeX)
- Preprints or workshop papers
- Adding status notes ("Submitted", "In Review", etc.)

---

### Feature 4: GitHub Actions

Automatic PDF generation and deployment on every commit.

#### Workflows Included

**1. `build-resume.yml` - Automatic Builds**

Triggers on:
- Push to main/master
- Pull requests
- Manual workflow dispatch

Builds:
- `resume.pdf` (long version)
- `resume-short.pdf` (short version)
- `resume-config.pdf` (external config version)
- `resume-bibtex.pdf` (BibTeX version)

Outputs:
- Uploaded as GitHub Actions artifacts (90 days retention)
- Attached to releases when you push a git tag

**2. `upload-to-cloud.yml` - Cloud Deployment**

Supports (uncomment sections you need):
- **AWS S3** - Upload to S3 bucket
- **Cloudflare R2** - Upload to R2 storage
- **GitHub Pages** - Deploy to gh-pages branch
- **Google Drive** - Upload via rclone

#### Setup Instructions

**For GitHub Actions (Builds):**

1. Push your code to GitHub
2. Workflows run automatically on push
3. Download PDFs from Actions tab → Artifacts

**For Releases:**

```bash
# Tag your release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions automatically creates a release with PDFs attached
```

**For Cloud Upload:**

1. Choose your provider (S3, R2, GDrive, etc.)
2. Edit `.github/workflows/upload-to-cloud.yml`
3. Uncomment the section for your provider
4. Add secrets to repository:
   - Settings → Secrets and variables → Actions → New repository secret
   - Add credentials (AWS_ACCESS_KEY_ID, CLOUDFLARE_API_TOKEN, etc.)

#### Example: AWS S3 Setup

1. Uncomment S3 section in `upload-to-cloud.yml`
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Update bucket name in workflow
4. Push to trigger upload

---

## Configuration Reference

### All Config Options

```yaml
# Variant (long/short)
variant: long

# Fonts
fonts:
  heading_font: "New Computer Modern"
  body_font: "New Computer Modern"
  font_size: 11pt              # Base font size
  name_font_size: 2.25em       # Your name size
  section_font_size: 1em       # Section headings size

# Layout
layout:
  margin: 0.5in                # Page margins
  line_spacing: 0.65em         # Line height
  list_spacing: 0.65em         # Space between list items
  section_spacing: 0.8em       # Space before sections

# Styling
styling:
  section_smallcaps: true      # Use small caps for section headings

# Visibility toggles
visibility:
  show_location: false         # City/state in header
  show_phone: true             # Phone number
  show_interests_summary: true # Research interests paragraph
  show_languages: true         # Languages section
  show_interests: false        # Interests list
  show_references: false       # References section

# Section titles (customize headings)
section_titles:
  work: "Experience"
  education: "Education"
  publications: "Publications"
  projects: "Projects"
  awards: "Honors and Awards"
  skills: "Skills"
  languages: "Languages"
  interests: "Interests"
  references: "References"

# Section order (what to show and in what order)
section_order:
  - interests_summary
  - work
  - education
  - publications
  - awards
  - skills
  - languages
  # - projects       # Commented out = hidden
  # - interests      # Commented out = hidden
  # - references     # Commented out = hidden
```

### Inline Config (in .typ file)

```typst
#let config = (
  variant: "long",
  heading_font: "New Computer Modern",
  font_size: 11pt,
  margin: 0.5in,
  show_phone: true,
  section_order: ("work", "education", "publications"),
)

#build_resume(resume_data, config)
```

### Priority

Config priority (highest to lowest):
1. Inline config in .typ file
2. External `config.yml` file
3. Template defaults

---

## Common Use Cases

### Use Case 1: Academic CV (Long)

**Goal:** Comprehensive CV with all publications, talks, teaching

**Setup:**
- Use `resume.yml` with all details
- Set `variant: "long"`
- Include sections: work, education, publications, awards, skills
- Use BibTeX for publications

**Compile:**
```bash
typst compile resume.typ
```

---

### Use Case 2: Industry Resume (Short)

**Goal:** Concise 1-2 page resume for job applications

**Setup:**
- Mark older work with `include_short: false`
- Mark minor publications with `include_short: false`
- Set `variant: "short"`
- Sections: work, education, skills (skip publications/awards)

**Compile:**
```bash
typst compile resume-short.typ
```

---

### Use Case 3: Multiple Versions

**Goal:** Maintain both academic CV and industry resume

**Setup:**
1. One `resume.yml` with all data
2. Mark items appropriately:
   - `include_short: true` → Must-have items
   - `include_short: false` → Academic/detailed items
3. Two config files:
   - `config.yml` → Academic settings
   - `config-short.yml` → Industry settings

**Compile:**
```bash
typst compile resume.typ              # Academic CV
typst compile resume-short.typ        # Industry resume
```

---

### Use Case 4: Research Group Template

**Goal:** Standardized format for all lab members

**Setup:**
1. Create `config.yml` with lab standards
2. Each person maintains their own `resume.yml`
3. Everyone uses `resume-with-config.typ`
4. Version control the template, config, and GitHub Actions

**Benefits:**
- Consistent formatting across group
- Easy to update everyone's format
- Automatic builds via GitHub Actions

---

## Tips for ATS Compatibility

1. **Use standard section names** - Stick with "Experience", "Education", "Skills"
2. **Single-column layout** - Already implemented
3. **Standard fonts** - Use system fonts (New Computer Modern, Linux Libertine, Liberation Sans)
4. **Avoid tables in main content** - Template uses grid for alignment only
5. **Include keywords** - Add relevant skills and technologies
6. **Export as PDF** - Typst generates proper searchable PDFs

---

## Troubleshooting

### Compilation Errors

**Error: "file not found"**
- Ensure `resume.yml`, `template.typ`, and your .typ file are in the same directory
- Check that `config.yml` exists if using external config
- Check that `publications.bib` exists if using BibTeX

**Error: "expected pattern"**
- Check YAML syntax - proper indentation is critical
- Ensure strings with special characters are quoted
- Validate YAML at [yamllint.com](http://www.yamllint.com/)

**Error: "unknown citation label"**
- Check that `bib_key` matches an entry in `publications.bib`
- Ensure BibTeX file is in the same directory
- Verify BibTeX syntax is correct

### Formatting Issues

**Text overlapping:**
- Reduce `font_size` in config
- Increase `line_spacing` or `section_spacing`
- Check for very long unbroken strings

**Sections not appearing:**
- Verify section is in `section_order`
- Check that data exists in `resume.yml`
- Verify visibility toggles (e.g., `show_languages: true`)

**Short resume showing everything:**
- Ensure `variant: "short"` is set in config
- Check that items have `include_short: false` in YAML
- Verify you're compiling `resume-short.typ`

**BibTeX citations not formatted:**
- Ensure `bib_file` parameter is passed to `build_resume()`
- Check that `publications.bib` exists and has valid syntax
- Verify `bib_key` matches entry in .bib file

### Date Formatting

**Use ISO format:** `YYYY-MM-DD`

```yaml
startDate: 2021-01-15    # ✓ Correct
endDate: present         # ✓ Correct

startDate: "Jan 2021"    # ✗ Wrong
endDate: "current"       # ✗ Wrong
```

---

## Advanced Customization

### Modifying Template Code

If you want to change how sections are rendered, edit `template.typ`:

```typst
// Each section has its own function
#let render_work(data, config) = { ... }
#let render_education(data, config) = { ... }
#let render_publications(data, config) = { ... }
```

Functions are modular and well-commented for easy modification.

### Adding Custom Sections

1. Add data to `resume.yml`:
```yaml
custom_section:
  - item: "Something"
    details: "Details here"
```

2. Create render function in `template.typ`:
```typst
#let render_custom(data, config) = {
  if "custom_section" not in data { return }

  block[
    == Custom Section Title
    #for item in data.custom_section {
      [- #item.item: #item.details]
    }
  ]
}
```

3. Add to main render loop:
```typst
#let build_resume(data, config, ...) = {
  // ... existing code ...

  for section in section_order {
    // ... existing sections ...
    else if section == "custom" { render_custom(data, config) }
  }
}
```

4. Add to `section_order`:
```yaml
section_order:
  - work
  - education
  - custom  # Your new section
```

---

## Contributing

Contributions are welcome! Some ideas:
- Additional section types
- More font/style presets
- Better error handling
- Accessibility improvements
- More citation styles
- Template variants (two-column, etc.)

---

## Credits

Built by combining the best ideas from:
- [NNJR](https://github.com/tzx/NNJR) - YAML-based Typst resume
- [imprecv](https://github.com/jskherman/imprecv) - Comprehensive CV template
- [Jake's Resume](https://github.com/jakegut/resume) - Clean LaTeX design

Enhanced with:
- Long/short variants
- External configuration
- BibTeX support
- GitHub Actions automation

---

## License

This template is provided as-is for personal and commercial use. Feel free to modify and distribute.

---

**Made with [Typst](https://typst.app/)** - The modern alternative to LaTeX
