# -*- coding: utf-8 -*-
"""Generate web/manifest.json: the chapter list consumed by the web reader.

Run after adding or renaming a handbook chapter:
    python web/build_manifest.py
"""
import io
import json
import os
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
BOOK = os.path.join(ROOT, "shader-handbook")

# Chapters sort by their leading number; README first, appendices last.
def sort_key(name):
    if name.lower().startswith("readme"):
        return (0, 0, name)
    m = re.match(r"^(\d+)-", name)
    if m:
        return (1, int(m.group(1)), name)
    return (2, 0, name)


PART_OF = {
    "README": "开始",
    "00": "第一部分 · 心法",
    "01": "第一部分 · 心法",
    "02": "第二部分 · 2D 基本功",
    "03": "第二部分 · 2D 基本功",
    "04": "第二部分 · 2D 基本功",
    "05": "第二部分 · 2D 基本功",
    "06": "第二部分 · 2D 基本功",
    "07": "第三部分 · 3D",
    "08": "第三部分 · 3D",
    "09": "第三部分 · 3D",
    "10": "第三部分 · 3D",
    "11": "第三部分 · 3D",
    "12": "第三部分 · 3D",
    "13": "第四部分 · 系统与工程",
    "14": "第四部分 · 系统与工程",
    "15": "第四部分 · 系统与工程",
    "16": "第四部分 · 系统与工程",
    "17": "第四部分 · 系统与工程",
    "18": "第五部分 · 实战与附录",
    "19": "第五部分 · 实战与附录",
}


def part_for(name):
    if name.lower().startswith("readme"):
        return PART_OF["README"]
    m = re.match(r"^(\d+)-", name)
    if m:
        return PART_OF.get(m.group(1), "其它")
    return "第五部分 · 实战与附录"


def title_of(path, fallback):
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("# "):
                return line[2:].strip()
    return fallback


def main():
    files = sorted((f for f in os.listdir(BOOK) if f.endswith(".md")), key=sort_key)
    chapters = []
    for f in files:
        path = os.path.join(BOOK, f)
        stem = os.path.splitext(f)[0]
        chapters.append({
            "file": f,
            "id": stem,
            "title": title_of(path, stem),
            "part": part_for(f),
            "bytes": os.path.getsize(path),
        })

    examples = []
    ex_dir = os.path.join(BOOK, "examples")
    if os.path.isdir(ex_dir):
        examples = sorted(f for f in os.listdir(ex_dir) if f.endswith(".glsl"))

    out = {
        "bookDir": "shader-handbook",
        "corpusDir": "shaders/shaders",
        "chapters": chapters,
        "examples": examples,
    }
    dest = os.path.join(HERE, "manifest.json")
    with open(dest, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("wrote %s (%d chapters, %d examples)" % (dest, len(chapters), len(examples)))


if __name__ == "__main__":
    main()
