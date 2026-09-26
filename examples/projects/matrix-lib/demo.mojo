from matrix import (
    Matrix,
    matmul,
    matmul_naive,
    matmul_pointers,
    matmul_reordered,
    matmul_simd,
    matmul_threads,
)


def same(x: Matrix, y: Matrix) -> String:
    return "да" if x.max_abs_diff(y) < 1e-12 else "НЕТ"


def main() raises:
    var a = Matrix(2, 3)
    var b = Matrix(3, 2)
    for i in range(2):
        for j in range(3):
            a[i, j] = Float64(i * 3 + j + 1)
            b[j, i] = Float64(j * 2 + i + 1)
    print(a @ b)

    # Размеры нарочно «неудобные»: 67 не делится на 4, 53 — на ширину полосы.
    var x = Matrix.random(67, 45, 1)
    var y = Matrix.random(45, 53, 2)
    var expected = matmul_naive(x, y)
    print("совпадает с наивным умножением (до 1e-12):")
    print("  переставленные циклы:", same(expected, matmul_reordered(x, y)))
    print("  указатели:           ", same(expected, matmul_pointers(x, y)))
    print("  SIMD:                ", same(expected, matmul_simd(x, y)))
    print("  SIMD и потоки:       ", same(expected, matmul_threads(x, y)))
    print("  упаковка:            ", same(expected, matmul(x, y)))
    print("  упаковка, 1 поток:   ", same(expected, matmul(x, y, workers=1)))

    try:
        _ = a @ a
    except e:
        print("ошибка:", e)
