import json, os, sys

CLASS_MAP = {"eary": 0, "earn": 1, "grain": 2, "rect": 3}

def convert(js_path):
    with open(js_path, encoding="utf-8") as f:
        d = json.load(f)
    W, H = d["imageWidth"], d["imageHeight"]
    lines, counts = [], {}
    for sh in d["shapes"]:
        lab = sh["label"]
        if lab not in CLASS_MAP:
            print(f"  ! unknown label '{lab}' skipped"); continue
        (x1, y1), (x2, y2) = sh["points"][0], sh["points"][1]
        xmin, xmax = sorted([x1, x2]); ymin, ymax = sorted([y1, y2])
        cx = (xmin + xmax) / 2 / W
        cy = (ymin + ymax) / 2 / H
        w  = (xmax - xmin) / W
        h  = (ymax - ymin) / H
        # clamp into [0,1]
        cx, cy, w, h = (min(max(v, 0.0), 1.0) for v in (cx, cy, w, h))
        lines.append(f"{CLASS_MAP[lab]} {cx:.6f} {cy:.6f} {w:.6f} {h:.6f}")
        counts[lab] = counts.get(lab, 0) + 1
    out = os.path.splitext(js_path)[0] + ".txt"
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + ("\n" if lines else ""))
    print(f"{os.path.basename(js_path)}  ({W}x{H})  ->  {os.path.basename(out)}  "
          f"[{len(lines)} boxes: {counts}]")

for p in sys.argv[1:]:
    convert(p)
