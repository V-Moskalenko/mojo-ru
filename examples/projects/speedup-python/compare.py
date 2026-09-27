"""Все шаги из главы на одном тексте: время и совпадение с чистым Python.

Запуск из окружения, где установлен mojo:
    python compare.py текст.txt
Если установлен rapidfuzz (pip install rapidfuzz numpy), он тоже
попадёт в сравнение.
"""

import re
import sys
import time
from collections import Counter

import mojo.importer  # noqa: F401
import fuzzy
import typos

text = open(sys.argv[1], encoding="utf-8").read().lower().replace("\\n", " ")
counts = Counter(re.findall(r"[а-яёa-z]+", text))
rare, common, expected = typos.find_typos(counts)
M = typos.MAX_DIST


def levenshtein_cutoff(a, b, limit):
    """Python-версия с ранним выходом — для честности сравнения."""
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        if min(cur) > limit:
            return limit + 1
        prev = cur
    return prev[-1]


def pairs(distance):
    """Двойной цикл на Python с данной функцией расстояния."""
    found = []
    for word in rare:
        for cand in common:
            if abs(len(word) - len(cand)) <= M and distance(word, cand) <= M:
                found.append((word, cand))
    return found


variants = [
    ("чистый Python", lambda: typos.find_typos(counts)[2], 1),
    ("Python с ранним выходом", lambda: pairs(lambda a, b: levenshtein_cutoff(a, b, M)), 1),
    ("1. levenshtein() на Mojo, цикл на Python", lambda: pairs(fuzzy.levenshtein), 3),
    ("   similar() на Mojo для каждого слова", lambda: [(w, c) for w in rare for c in fuzzy.similar(w, common, M)], 3),
    ("   all_pairs() — весь цикл на Mojo", lambda: fuzzy.all_pairs(rare, common, M), 5),
    ("2. без проверок границ", lambda: fuzzy.all_pairs_unchecked(rare, common, M), 5),
    ("3. с ранним выходом", lambda: fuzzy.all_pairs_cutoff(rare, common, M), 5),
    ("4. битовый алгоритм Майерса", lambda: fuzzy.all_pairs_myers(rare, common, M), 5),
]

try:
    import numpy as np
    from rapidfuzz import process
    from rapidfuzz.distance import Levenshtein

    def rapidfuzz_cdist():
        d = process.cdist(rare, common, scorer=Levenshtein.distance, score_cutoff=M, workers=1)
        return [(rare[i], common[j]) for i, j in zip(*np.nonzero(d <= M))]

    variants += [
        ("rapidfuzz: цикл на Python", lambda: pairs(lambda a, b: Levenshtein.distance(a, b, score_cutoff=M)), 3),
        ("rapidfuzz.cdist, 1 поток", rapidfuzz_cdist, 5),
    ]
except ImportError:
    print("(rapidfuzz не установлен — его в сравнении не будет)")

base = None
for name, run, repeat in variants:
    best = float("inf")
    for _ in range(repeat):
        start = time.perf_counter()
        result = run()
        best = min(best, time.perf_counter() - start)
    base = base or best
    same = sorted(map(tuple, result)) == sorted(expected)
    print(f"{name:42} {best:8.3f} с  ×{base / best:6.1f}  {'совпадает' if same else 'НЕ СОВПАДАЕТ'}")
