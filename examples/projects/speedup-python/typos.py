"""Ищет вероятные опечатки: редкие слова, очень похожие на частые.

Запуск: python typos.py текст.txt
"""

import re
import sys
import time
from collections import Counter

RARE = 1  # слово встретилось не больше RARE раз — подозреваемое
COMMON = 5  # слово встретилось хотя бы COMMON раз — образец
MAX_DIST = 1  # сколько правок допускаем
MIN_LEN = 5  # короткие слова слишком похожи друг на друга


def levenshtein(a, b):
    """Расстояние Левенштейна: сколько вставок, удалений и замен букв
    нужно, чтобы из a получить b."""
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def find_typos(counts):
    common = sorted(w for w, c in counts.items() if c >= COMMON and len(w) >= MIN_LEN)
    rare = sorted(w for w, c in counts.items() if c <= RARE and len(w) >= MIN_LEN)
    found = []
    for word in rare:
        for candidate in common:
            if abs(len(word) - len(candidate)) > MAX_DIST:
                continue
            if levenshtein(word, candidate) <= MAX_DIST:
                found.append((word, candidate))
    return rare, common, found


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
