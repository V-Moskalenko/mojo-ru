"""Сравнение: тот же расчёт на чистом Python и через модуль на Mojo.

Запуск (нужен Python из окружения, где установлен mojo):
    python run_hotspot.py

Важно: файл называется run_hotspot.py, а не hotspot.py — иначе Python
попытается импортировать сам скрипт вместо модуля на Mojo.
"""

import math
import timeit

import mojo.importer  # noqa: F401  — включает импорт .mojo-файлов
import hotspot

N = 200_000


def sum_roots_python(n):
    total = 0.0
    for i in range(n):
        total += math.sqrt(i)
    return total


expected = sum_roots_python(N)
actual = hotspot.sum_roots(N)
print("результаты совпадают:", abs(expected - actual) < 1e-6)
print("список квадратов:", hotspot.squares(5))

repeat = 5
py = min(timeit.repeat(lambda: sum_roots_python(N), number=1, repeat=repeat))
mo = min(timeit.repeat(lambda: hotspot.sum_roots(N), number=1, repeat=repeat))
print(f"Python: {py * 1000:.3f} мс")
print(f"Mojo:   {mo * 1000:.3f} мс")
print(f"быстрее примерно в {py / mo:.0f} раз")
