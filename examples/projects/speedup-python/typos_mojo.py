"""Та же программа, но поиск пар — в модуле на Mojo (fuzzy.mojo рядом).

Запуск из окружения, где установлен mojo: python typos_mojo.py текст.txt
При первом запуске модуль компилируется — это займёт несколько секунд.
"""

import re
import sys
import time
from collections import Counter

import mojo.importer  # noqa: F401  — учит Python импортировать .mojo
import fuzzy

from typos import COMMON, MAX_DIST, MIN_LEN, RARE


def find_typos(counts):
    common = sorted(w for w, c in counts.items() if c >= COMMON and len(w) >= MIN_LEN)
    rare = sorted(w for w, c in counts.items() if c <= RARE and len(w) >= MIN_LEN)
    return rare, common, fuzzy.all_pairs_myers(rare, common, MAX_DIST)


def main():
    text = open(sys.argv[1], encoding="utf-8").read().lower().replace("\\n", " ")
    counts = Counter(re.findall(r"[а-яёa-z]+", text))
    start = time.perf_counter()
    rare, common, found = find_typos(counts)
    elapsed = time.perf_counter() - start
    print(f"редких слов: {len(rare)}, частых: {len(common)}, пар-подозрений: {len(found)}")
    for word, candidate in found[:10]:
        print(f"  {word} → {candidate}")
    print(f"поиск занял {elapsed:.2f} с")


if __name__ == "__main__":
    main()
