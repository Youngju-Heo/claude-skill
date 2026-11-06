"""Convert a weekly worklist markdown (rnd-weekly-worklist output) into a JSON
plan that apply-excel-plan.ps1 writes into the "연구혁신" sheet.

Usage: python -I build-excel-plan.py <worklist.md> <plan.json>
"""
import json
import re
import sys

# Owner used only when the sheet has no existing owner for the group name.
DEFAULT_OWNERS = {
    "공통": "허영주",
    "edge-device": "허영주\n김은비\n조영현",
    "site-manager": "김은비\n조영현",
    "ai engine": "허영주",
    "연동": "황동기",
}
SHEET = "연구혁신"
ETC_LABEL = "기타"

ORG_URL = "https://dev.azure.com/cberrydevops"
ID_TAIL = re.compile(r"\((?:([a-z]+) )?(#[^()]*)\)\s*$")


def ids_of(text, section_project):
    """Return (ids text, link url to the first id)."""
    m = ID_TAIL.search(text)
    if not m:
        return "", ""
    ids = m.group(2).strip()
    first = re.match(r"#(\d+)", ids)
    project = m.group(1) or section_project
    url = f"{ORG_URL}/{project}/_workitems/edit/{first.group(1)}" if first and project else ""
    return ids, url


def main(src, dst):
    blocks = {}
    order = []
    group = None
    mode = None
    for line in open(src, encoding="utf-8").read().splitlines():
        h = re.match(r"^## \d+\. (.+?) \(", line)
        if h:
            parts = [p.strip() for p in h.group(1).split("/")]
            lab = parts[0]
            category, name = ("공통", "공통") if len(parts) < 3 else (parts[1], parts[2])
            pm = re.search(r"\(([a-z]+) #", line)
            section_project = pm.group(1) if pm else ""
            group = {"category": category, "name": name,
                     "default_owner": DEFAULT_OWNERS.get(name, ""),
                     "done": [], "plan": []}
            if lab not in blocks:
                blocks[lab] = {"lab": lab, "groups": []}
                order.append(lab)
            blocks[lab]["groups"].append(group)
            mode = None
            continue
        if line.startswith("### "):
            mode = {"금주 진행": "done", "차주 계획": "plan"}.get(line[4:].strip())
            continue  # other sections (e.g. 장기 진행) are not copied to Excel
        m = re.match(r"^(\s*)- (.+)$", line)
        if not (m and group and mode):
            continue
        indent, body = m.group(1), m.group(2)
        if indent:  # Task detail lines stay in the markdown only
            continue
        text = "- " + body
        ids, url = ids_of(body, section_project)
        group["done" if mode == "done" else "plan"].append(
            {"text": text, "ids": ids, "url": url})

    plan = {"sheet": SHEET, "etc_label": ETC_LABEL,
            "blocks": [blocks[k] for k in order]}
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(plan, f, ensure_ascii=False, indent=2)
    rows = sum(max(len(g["done"]), len(g["plan"]), 1)
               for b in plan["blocks"] for g in b["groups"])
    print(f"Wrote plan: {len(plan['blocks'])} blocks, {rows} rows -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
