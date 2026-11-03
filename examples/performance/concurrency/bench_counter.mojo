"""Четыре способа посчитать сумму в несколько потоков. Вывод у каждой машины свой.

Запуск: mojo build bench_counter.mojo && ./bench_counter 10000000
"""

from std.atomic import Atomic
from std.benchmark import keep
from std.runtime import parallelism_level
from std.sys import argv
from std.time import perf_counter_ns
from std.utils import BlockingScopedLock, BlockingSpinLock
from max.algorithm import parallelize


def value(i: Int) -> Int:
    """Работа над одним элементом: дешёвая, но не сворачиваемая."""
    return (i * 2654435761) % 1000


def one_thread(n: Int) -> Int:
    var total = 0
    for i in range(n):
        total += value(i)
    return total


def atomic_each(n: Int) -> Int:
    var total = Atomic[Int](0)

    def work(i: Int) {mut total}:
        total += value(i)

    parallelize(work, n)
    return total.load()


def lock_each(n: Int) -> Int:
    var total = 0
    var lock = BlockingSpinLock()

    def work(i: Int) {mut total, mut lock}:
        var v = value(i)
        with BlockingScopedLock(lock):
            total += v

    parallelize(work, n)
    return total


def partial_sums(n: Int) -> Int:
    var workers = parallelism_level()
    var partial = List[Int](length=workers, fill=0)

    def work(w: Int) {mut partial, imm n, imm workers}:
        var s = 0
        for i in range(w * n // workers, (w + 1) * n // workers):
            s += value(i)
        partial[w] = s  # у каждого потока своя ячейка

    parallelize(work, workers)
    var total = 0
    for p in partial:
        total += p
    return total


def best_ms[f: def(Int) thin -> Int](n: Int, expected: Int) raises -> Float64:
    """Лучшее время из пяти запусков; заодно проверяем ответ."""
    var best = Float64.MAX
    for _ in range(5):
        var t0 = perf_counter_ns()
        var result = f(n)
        var t1 = perf_counter_ns()
        keep(result)
        if result != expected:
            raise Error(String("неверный ответ: ", result, " вместо ", expected))
        best = min(best, Float64(t1 - t0) / 1e6)
    return best


def main() raises:
    var n = Int(argv()[1]) if len(argv()) > 1 else 10_000_000
    var expected = one_thread(n)
    print("элементов:", n, " потоков:", parallelism_level())
    print("один поток       ", round(best_ms[one_thread](n, expected), 2), "мс")
    print("атомик           ", round(best_ms[atomic_each](n, expected), 2), "мс")
    print("блокировка       ", round(best_ms[lock_each](n, expected), 2), "мс")
    print("частичные суммы  ", round(best_ms[partial_sums](n, expected), 2), "мс")
