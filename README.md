# Digital Junk Tools

This repo **is** the document root (`public_html`) of https://tools.digitaljunk.in.
Every Labs tool lives at `https://tools.digitaljunk.in/<slug>/`. No new subdomains.
Pushes to `main` deploy to Hostinger over FTP (`.github/workflows/deploy.yml`).

## Contribution rules (bots and humans)

1. **One folder per slug.** `<slug>/` is lowercase `a-z0-9-`. A PR adds or updates exactly one slug folder.
2. **Static only.** Commit the built output (`dist/`) only: HTML, JS, CSS, fonts, images, sample data. No source, no `package.json`, no PHP/server code.
3. **Build with base `/<slug>/`**, e.g. Vite `base: '/<slug>/'` or `vite build --base /<slug>/`. Absolute URLs must start with `/<slug>/`; prefer `import.meta.env.BASE_URL` for runtime fetches.
4. **No secrets.** No API keys, tokens, `.env` files. Tools run in the browser; anything shipped is public.
5. **Add an entry to `tools.json`**: `{ "slug", "name", "oneliner", "date": "YYYY-MM-DD", "x": "<X post URL or empty>" }`. Newest entries go after existing ones unless told otherwise; the landing page renders the list in order.
6. **Share card.** Include `<slug>/og.png` (1200x630 ideal) and `og:title`, `og:description`, `og:image` (`https://tools.digitaljunk.in/<slug>/og.png`), `twitter:card` meta in `<slug>/index.html`.
7. **PR title `tool: <slug>`.** Such PRs auto-merge (squash) once checks pass.
8. Files must be under 20 MB each. If you need `.mjs` or `.wasm`, the root `.htaccess` already serves them correctly.

Changes outside your slug, `tools.json` and `index.html` (workflows, `.htaccess`, `scripts/`, README) need the `infra` label and a human review.

## Checks (`.github/workflows/check.yml`)

- `tools.json` parses and entries have required keys
- every changed slug folder has `index.html` and a `tools.json` entry
- no absolute `src`/`href` outside `/<slug>/`, no `/assets/` references in JS/CSS
- no secrets-looking strings, no server-side files
- lychee offline internal link check
- no files over 20 MB
- scope: only own slug + `tools.json` + `index.html` unless labelled `infra`

Run locally: `bash scripts/check.sh origin/main` then `python3 -m http.server` and open `http://localhost:8000/<slug>/`.
