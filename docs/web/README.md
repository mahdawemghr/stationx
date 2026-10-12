# docs/web - static pages for the stores

Plain HTML + inline CSS, no scripts, no external requests, no tracking. The app does **not** bundle them; they only need to be hosted publicly over HTTPS.

Files: `index.html`, `privacy.html` (mirrors `docs/PRIVACY_POLICY.md` - keep them in sync; update the .md first), `delete-account.html`.

## Before hosting - fill in
Search for `[` in the three pages and replace: `[CONTACT EMAIL — fill in]`, `[DATE — fill in]` (privacy effective date), `[OWNER: developer name — fill in]`, `[OWNER: N]` (days to process deletion requests). Do the same placeholders in `docs/PRIVACY_POLICY.md`.
Check: `grep -rn "fill in\|OWNER" docs/web` must print nothing.

## Hosting options
1. **GitHub Pages** (free): push the repo to GitHub (you must push it yourself), then Settings > Pages > Source: *Deploy from a branch*, branch `main`, folder `/docs`. Pages only offers `/` or `/docs`, so the pages will be at `https://<user>.github.io/<repo>/web/privacy.html`. (Or copy `docs/web/*` to a separate public repo's root for shorter URLs.) Note the whole `/docs` folder becomes public, including the roadmap and store notes - use a separate repo if you do not want that.
2. **Netlify Drop**: open app.netlify.com/drop and drag the `docs/web` folder in. You get an `https://<name>.netlify.app/` URL; pages are at `/privacy.html` and `/delete-account.html`.
3. **Any static host** (Cloudflare Pages, your own web server, S3 + CDN): upload the three HTML files to one directory served over HTTPS.

## URLs to paste into Play Console
- App content > Privacy policy: `<base>/privacy.html`
- App content > Data safety > Delete account URL (and "Data deletion" page): `<base>/delete-account.html`

`<base>` = the folder that contains the files, e.g. `https://<user>.github.io/<repo>/web`. Open both URLs in a private browser window first: they must load without login.
