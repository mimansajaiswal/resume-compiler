# Typst Resume Template with YAML

A highly configurable, ATS-friendly resume template for [Typst](https://typst.app/) that uses YAML for data storage. Perfect for academics, researchers, and professionals who want to maintain their resume data separately from formatting.

## Features

- **YAML-based data storage** - Easy to maintain and version control
- **Long/Short resume variants** - Create multiple versions from one data file
- **External configuration** - Manage settings in `config.yml`
- **No-JS/plain-text variant** - Generate a PDF with links rendered as plain text
- **BibTeX support** - Professional citation formatting with custom links
- **Configurable publication emphasis** - Keep titles regular by default and optionally auto-bold selected author names
- **Markdown-first content** - Use inline markdown in text fields (bold, italics, links)
- **Configurable contact display** - Render contact row as labels or icons+labels
- **Brand/academic profile icons** - Uses Typst Universe `scienceicons` + `sicons` (Google Scholar/DBLP/ORCID, etc.); unknown networks render label-only
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

1. **Edit your data** - Modify the synthetic example in `resume.yml`
2. **Customize settings** (optional) - Adjust configuration in `config.yml`
3. **Compile**:
   ```bash
   ./build-resumes.sh
   ```

This generates:
- `artifacts/{FirstName}{LastName}_Resume.pdf` (mode: `default`)
- `artifacts/{FirstName}{LastName}_Resume_S.pdf` (mode: `short`)
- `artifacts/{FirstName}{LastName}_Resume_B.pdf` (mode: `bibtex`)
- `artifacts/{FirstName}{LastName}_Resume_N.pdf` (mode: `no-js`)

### Markdown in YAML Fields

All user-facing text fields are markdown-capable (except explicit URL fields such as `url`).

Examples:
```yaml
awards:
  - content: "[Awarded Fellowship](https://example.com/fellowship)"

publications:
  - name: "Designing Interfaces for Delivering and Obtaining Generation Explanation Annotations"
    section: works_in_progress
    content: "[Demo](https://example.com/demo) and [Repo](https://github.com/example/repo)"
```

### Supported Keys (Standardized)

This project now uses a standardized key style with no legacy aliases:

- `work[]`:
  - `name` (organization name)
  - `url`, `location`
  - `positions[]` with:
    - `name` (role title)
    - `startDate`, `endDate`
    - `content[]` (detail lines)
- `education[]`:
  - `name` (institution name)
  - `url`, `location`, `studyType`, `area`, `startDate`, `endDate`
  - optional `honors[]`, `content[]`, `thesis`, `courses[]`
- `publications[]`:
  - BibTeX mode: `bib_key`, optional `url` override (falls back to BibTeX `url`), optional `content`, `links`
  - YAML mode: `name` (title) plus optional `content`, `authors`, `publisher`, `releaseDate`, `url`
- Generic section support:
  - Any additional top-level array (for example `community_service`) is auto-rendered.
  - You can optionally place it in `section_order` and set `section_titles.<key>`.

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
├── resume.typ                      # Single mode-driven entrypoint
│
├── resume.yml                      # Your resume data
├── resume-bibtex.yml               # Example with BibTeX references
│
├── config.yml                      # External configuration (long)
├── config-short.yml                # External configuration (short)
├── build-resumes.sh                # Local builder (outputs in artifacts/)
│
├── publications.bib                # BibTeX bibliography
├── references/                     # Reference source material (LaTeX/original PDF)
├── artifacts/                      # Generated PDFs
│
├── .github/workflows/
│   ├── build-resume.yml           # Auto-build PDFs
│   ├── upload-to-cloud.yml        # Upload to cloud storage
│   └── deploy-pages.yml           # Deploy web editor to GitHub Pages
│
├── .gitignore                     # Ignores generated outputs
└── LICENSE                        # MIT license
```

## Core Usage Patterns

### Pattern 1: Basic YAML Resume (Simplest)

**Files:** `resume.yml` + `resume.typ`

```bash
# Edit your data
vim resume.yml

# Compile all variants with canonical filenames
./build-resumes.sh
```

**Best for:** Quick updates, simple resumes, learning the system

---

### Pattern 2: Long/Short Variants

**Files:** `resume.yml` (with `include_short` flags) + `resume.typ` + `config-short.yml`

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
typst compile --input mode=default resume.typ
typst compile --input mode=short resume.typ
```

**Best for:** Job applications (short) vs academic CVs (long)

---

### Pattern 3: External Configuration

**Files:** `resume.yml` + `config.yml` + `resume.typ`

Store all settings in `config.yml`:

```yaml
# config.yml
variant: long
fonts:
  font: "Libertinus Serif"
  mono_font: "DejaVu Sans Mono"
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
typst compile resume.typ
```

Short config example:
```bash
typst compile --input mode=short resume.typ
```

**Best for:** Managing multiple resume styles, team templates

---

### Pattern 4: BibTeX Publications

**Files:** `publications.bib` + `resume-bibtex.yml` + `resume.typ`

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
    # url omitted on purpose: falls back to publications.bib url
    content: "_Accepted_"
    links:
      - content: "Paper"
        url: "https://arxiv.org/..."
      - content: "Code"
        url: "https://github.com/..."
      - content: "Data"
        url: "https://dataset.com/..."
```

3. Compile:
```bash
typst compile --input mode=bibtex resume.typ
# Canonical local output name when using build script: artifacts/{FirstName}{LastName}_Resume_B.pdf
```

`mode=bibtex` reads `resume-bibtex.yml` by default. Web editor mode uses the active resume YAML editor content.

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
  - name: Company Name
    include_short: false
    positions: [...]

  # Keep in both versions
  - name: Current Company
    positions:
      # Include this position in short version
      - name: Senior Role
        include_short: true
        content: [...]

      # Exclude this older position from short
      - name: Junior Role
        include_short: false
        content: [...]

publications:
  # Top papers in short version
  - name: "Important Paper"
    include_short: true

  # Exclude from short version
  - name: "Workshop Paper"
    include_short: false
```

#### Configuration

Set the compile mode at the CLI:

```bash
typst compile --input mode=default resume.typ
typst compile --input mode=short resume.typ
```

Mode mapping:
- `default` → uses `config.yml`
- `short` → uses `config-short.yml`
- `bibtex` → uses `config.yml` and `publications.bib`
- `no-js` → uses `config.yml` with links disabled

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
  font: "Libertinus Serif"
  mono_font: "DejaVu Sans Mono"
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
// resume.typ
#import "template.typ": build_resume

#let resume_data = yaml("resume.yml")
#build_resume(resume_data, (:), config_file: "config.yml")
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
@inproceedings{walker2024textemotion,
  title={From Text to Emotion: Evaluating LLM Annotation Quality},
  author={Niu, Melissa and Walker, Ethan and Morrison, Emily},
  journal={Interspeech 2024},
  year={2024},
  url={https://example.com/papers/text-to-emotion.pdf}
}

@inproceedings{walker2020privacy,
  title={Privacy-Enhanced Multimodal Neural Representations for Emotion Recognition},
  author={Walker, Ethan and Morrison, Emily},
  booktitle={AAAI Conference on Artificial Intelligence},
  year={2020}
}
```

2. **Reference in YAML with custom links:**

```yaml
publications:
  # BibTeX entry with custom links
  - bib_key: walker2024textemotion
    links:
      - content: "Paper"
        url: "https://example.com/papers/text-to-emotion.pdf"
      - content: "Code"
        url: "https://github.com/example/code"
      - content: "Demo"
        url: "https://demo.example.com"

  # BibTeX entry without extra links
  - bib_key: walker2020privacy

  # Mix YAML and BibTeX formats
  - content: "Work in Progress: CAPSTONE"
    name: "Work in Progress: CAPSTONE"
    section: works_in_progress
    authors: "Ethan Walker"
    content: "[Research Notes](https://example.com)"
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
- For any publication entry, use `links` (array of `{content, url}`) for extra links
- You can also place links directly in markdown text fields like `content`

You can also split publications into multiple headings (for example `Works in Progress`, `Submitted Publications`, `Accepted Publications`) by:
- Setting `publication_sections` in `config.yml`
- Adding `section: submitted` (or any configured key) on each publication item

This is useful for:
- Works in progress (not yet in BibTeX)
- Preprints or workshop papers
- Adding status notes ("Submitted", "In Review", etc.)

---

### Feature 4: GitHub Actions

Automatic PDF generation and deployment on relevant resume/template changes.

#### Workflows Included

**1. `build-resume.yml` - Automatic Builds**

Triggers on:
- Push to main/master
- Push tags matching `v*` (for versioned releases)
- Pull requests
- Manual workflow dispatch

Builds:
- `artifacts/{FirstName}{LastName}_Resume.pdf` (default long, config-driven)
- `artifacts/{FirstName}{LastName}_Resume_S.pdf` (short version)
- `artifacts/{FirstName}{LastName}_Resume_B.pdf` (BibTeX version)
- `artifacts/{FirstName}{LastName}_Resume_N.pdf` (no-JS/plain-text links)

Outputs:
- Uploaded as GitHub Actions artifacts (90 days retention)
- Attached to releases when you push a git tag

**2. `upload-to-cloud.yml` - Cloud Deployment**

Supports (uncomment sections you need):
- **AWS S3** - Upload to S3 bucket
- **Cloudflare R2** - Upload to R2 storage
- **GitHub Pages** - Deploy to gh-pages branch
- **Google Drive** - Upload via rclone

**3. `deploy-pages.yml` - Web App Deployment**

Deploys the editor under `/web/` on GitHub Pages:
- `https://mimansajaiswal.github.io/resume-compiler/web/`
- Root (`/resume-compiler/`) redirects to `/resume-compiler/web/`.

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
paper_size: letter            # Options: "letter" or "a4"

# Fonts
fonts:
  font: "Libertinus Serif"
  mono_font: "DejaVu Sans Mono"
  font_size: 11pt              # Base font size
  name_font_size: 2.25em       # Your name size
  section_font_size: 1em       # Section headings size
  page_number_font_size: 0.85em
  header_title_font_size: 0.9em
  location_font_size: 0.8em
  work_role_font_size: 0.98em

# Layout
layout:
  margin: 0.5in                # Page margins
  line_spacing: 0.38em         # Line spacing within wrapped lines
  list_spacing: 0.7em          # Space between adjacent items
  section_spacing: 1.38em      # Space before section headings
  post_section_spacing: 0.9em  # Space after section headings
  entry_spacing: 0.71em        # Space between resume entries
  entry_inner_spacing: 0.55em  # Space between entry title/details/content
  header_rule_top_spacing: 0.6em # Gap between contact row and horizontal rule
  publication_number_width: 2.2em # Hanging indent width for numbered publications

# Styling
styling:
  section_smallcaps: true      # Use small caps for section headings
  secondary_color: "#555555"   # Accent text color (hex)
  link_color: "#1C398D"        # Link color (hex)
  section_heading_sticky: true # Keep section heading with following content
  publication_title_bold: false # Keep publication titles regular weight by default
  publication_autobold_authors: true # Auto-bold `personal.name` in publication author lists
  publication_bold_author_names: [] # Optional extra names to bold (exact-match strings)
  contact_display_mode: "icon_label"   # "label" | "icon_label"
  contact_icon_spacing: 0.21em

# Visibility toggles
visibility:
  show_location: false         # City/state in header
  show_phone: true             # Phone number
  show_interests_summary: true # Research interests paragraph
  show_languages: true         # Languages section
  show_interests: false        # Interests list
  show_references: false       # References section
  enable_links: true           # Set false to render links as plain text
  links_disabled_behavior: "label" # "label" | "label_with_url"
  show_publication_numbers: false  # Prefix publication items as [1], [2], ...

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
  font: "Libertinus Serif",
  mono_font: "DejaVu Sans Mono",
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
typst compile --input mode=short resume.typ
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
typst compile --input mode=default resume.typ   # Academic CV
typst compile --input mode=short resume.typ     # Industry resume
```

---

### Use Case 4: Research Group Template

**Goal:** Standardized format for all lab members

**Setup:**
1. Create `config.yml` with lab standards
2. Each person maintains their own `resume.yml`
3. Everyone uses `resume.typ`
4. Version control the template, config, and GitHub Actions

**Benefits:**
- Consistent formatting across group
- Easy to update everyone's format
- Automatic builds via GitHub Actions

---

## Tips for ATS Compatibility

1. **Use standard section names** - Stick with "Experience", "Education", "Skills"
2. **Single-column layout** - Already implemented
3. **Standard fonts** - Use proven serif families (Libertinus Serif, New Computer Modern, TeX Gyre Termes)
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

**Editor shows JSON Resume type errors (e.g., "Expected object")**
- This repo uses a flexible markdown-first schema, not strict JSON Resume typing
- Ensure your editor loads `resume.schema.json`
- VS Code users can use the included `.vscode/settings.json` mapping
- `resume.yml` and `resume-bibtex.yml` also include:
  - `# yaml-language-server: $schema=./resume.schema.json`

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
- Verify you're compiling with `--input mode=short`

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

No template edits are required anymore for most custom sections.

1. Add data to `resume.yml` (any key name works, e.g. `patents`):
```yaml
patents:
  - name: "System and Method for X"
    subtitle: "USPTO"
    startDate: 2025-01-01
    url: "https://example.com/patent"
    content:
      - "Co-inventor"
```

2. Add it to `section_order` in `config.yml`:
```yaml
section_order:
  - work
  - education
  - patents
```

3. Set a custom title in `section_titles` (optional):
```yaml
section_titles:
  patents: "Patents"
```

The template auto-renders arrays/dictionaries using a generic resume layout.
Use standardized keys like `name`, `subtitle`, `startDate`, `endDate`, `url`, `content`, and `skills`.

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

This project is licensed under the MIT License. See `LICENSE`.

---

**Made with [Typst](https://typst.app/)** - The modern alternative to LaTeX
