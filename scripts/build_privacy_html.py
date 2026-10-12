#!/usr/bin/env python3
"""Regenerates docs/web/privacy.html from docs/PRIVACY_POLICY.md (the single source of truth).

Usage:  python3 scripts/build_privacy_html.py
Handles only the markdown subset used by the policy: headings, paragraphs, bullet lists (with
two-space continuation lines), **bold**, `code`, _italics_ and block quotes.
"""
import html
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
md = (root / "docs/PRIVACY_POLICY.md").read_text(encoding="utf-8")
old = (root / "docs/web/privacy.html").read_text(encoding="utf-8")
head = old[: old.index("<h1>")]  # doctype, styles, nav


def inline(t: str) -> str:
    t = html.escape(t, quote=False)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"(?<![\w])_([^_]+)_(?![\w])", r"<em>\1</em>", t)
    return t.replace("›", "&rsaquo;")


out, para, items, in_list = [], [], [], False


def flush_para():
    global para
    if para:
        out.append("<p>" + inline(" ".join(para)) + "</p>")
        para = []


def flush_list():
    global items, in_list
    if in_list:
        out.append("<ul>\n" + "\n".join("<li>" + inline(i) + "</li>" for i in items) + "\n</ul>")
        items, in_list = [], False


title = "StationX Privacy Policy"
effective = contact = ""
for raw in md.splitlines():
    line = raw.rstrip()
    if line.startswith("# "):
        continue
    if line.startswith("_Effective date:"):
        effective = line.strip("_")
        continue
    if line.startswith("_Contact:"):
        contact = line.strip("_")
        continue
    if line.startswith("> "):  # owner notes are not part of the published page
        continue
    if line.startswith("## "):
        flush_para(); flush_list()
        out.append("<h2>" + inline(line[3:]) + "</h2>")
    elif line.startswith("- "):
        flush_para()
        in_list = True
        items.append(line[2:])
    elif line.startswith("  ") and in_list and items:
        items[-1] += " " + line.strip()
    elif not line.strip():
        flush_para(); flush_list()
    else:
        if in_list:
            flush_list()
        para.append(line.strip())
flush_para(); flush_list()

page = (
    head
    + f"<h1>{title}</h1>\n"
    + f'<p class="mut">{html.escape(effective)}<br>{html.escape(contact)}</p>\n\n'
    + "\n".join(out)
    + "\n</main></body></html>\n"
)
(root / "docs/web/privacy.html").write_text(page, encoding="utf-8")
print("wrote docs/web/privacy.html")
