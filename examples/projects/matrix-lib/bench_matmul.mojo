"""Замер всех шагов: время и GFLOPS. Вывод у каждой машины свой.

Запуск: mojo build bench_matmul.mojo && ./bench_matmul 500
"""

from std.benchmark import keep
from std.sys import argv
from std.time import perf_counter_ns
from matrix import (
    Matrix,
    matmul,
    matmul_naive,
    matmul_pointers,
    matmul_reordered,
    matmul_simd,
    matmul_threads,
)


def best_seconds[
    f: def(Matrix, Matrix) thin raises -> Matrix
](a: Matrix, b: Matrix) raises -> Float64:
    """Лучшее время из пяти запусков."""
    var best = Float64.MAX
    for _ in range(5):
        var t0 = perf_counter_ns()
        var c = f(a, b)
        var t1 = perf_counter_ns()
        keep(c.data[len(c.data) - 1])
        best = min(best, Float64(t1 - t0) / 1e9)
    return best


def one_thread(a: Matrix, b: Matrix) raises -> Matrix:
    return matmul(a, b, workers=1)


def all_threads(a: Matrix, b: Matrix) raises -> Matrix:
    return matmul(a, b)


def report(name: String, n: Int, seconds: Float64):
    var gflops = 2.0 * Float64(n) ** 3 / seconds / 1e9
    print(
        name, "  ", round(seconds * 1000, 2), "мс  ", round(gflops, 1), "GFLOPS"
    )


def main() raises:
    var n = Int(argv()[1]) if len(argv()) > 1 else 500
    if n <= 0:
        raise Error("размер матриц должен быть больше нуля")
    var a = Matrix.random(n, n, 1)
    var b = Matrix.random(n, n, 2)
    print("матрицы", n, "×", n)
    if n <= 512:
        report("1. наивное             ", n, best_seconds[matmul_naive](a, b))
        report(
            "2. порядок циклов      ", n, best_seconds[matmul_reordered](a, b)
        )
    report("3. указатели           ", n, best_seconds[matmul_pointers](a, b))
    report("4. SIMD                ", n, best_seconds[matmul_simd](a, b))
    report("5. SIMD и потоки       ", n, best_seconds[matmul_threads](a, b))
    report("6. упаковка, 1 поток   ", n, best_seconds[one_thread](a, b))
    report("6. упаковка, все потоки", n, best_seconds[all_threads](a, b))
