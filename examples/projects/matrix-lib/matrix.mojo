"""Матричная библиотека: от наивного умножения до упаковки и потоков."""

from std.algorithm import vectorize
from std.random import random_float64, seed
from std.sys import simd_width_of
from std.sys.info import CompilationTarget
from max.algorithm import parallelize

comptime W = simd_width_of[DType.float64]()
"""Сколько Float64 помещается в один векторный регистр."""


struct Matrix(Movable, Writable):
    """Матрица Float64, строки лежат в памяти одна за другой."""

    var rows: Int
    var cols: Int
    var data: List[Float64]

    def __init__(out self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[Float64](length=rows * cols, fill=0.0)

    @staticmethod
    def random(rows: Int, cols: Int, seed_value: Int) -> Matrix:
        seed(seed_value)
        var m = Matrix(rows, cols)
        for i in range(rows * cols):
            m.data[i] = random_float64(-1.0, 1.0)
        return m^

    @staticmethod
    def identity(n: Int) -> Matrix:
        var m = Matrix(n, n)
        for i in range(n):
            m[i, i] = 1.0
        return m^

    def __getitem__(self, i: Int, j: Int) -> Float64:
        return self.data[i * self.cols + j]

    def __setitem__(mut self, i: Int, j: Int, value: Float64):
        self.data[i * self.cols + j] = value

    def __matmul__(self, other: Matrix) raises -> Matrix:
        """Оператор `a @ b`, как в NumPy."""
        return matmul(self, other)

    def max_abs_diff(self, other: Matrix) -> Float64:
        """Наибольшее расхождение; бесконечность, если размеры разные или есть NaN.
        """
        if self.rows != other.rows or self.cols != other.cols:
            return Float64.MAX
        var worst: Float64 = 0.0
        for i in range(len(self.data)):
            var d = abs(self.data[i] - other.data[i])
            # `not (d <= worst)` ловит и NaN: с ним любое сравнение ложно
            if not (d <= worst):
                worst = d if d == d else Float64.MAX
        return worst

    def write_to(self, mut writer: Some[Writer]):
        for i in range(self.rows):
            writer.write("[")
            for j in range(self.cols):
                if j > 0:
                    writer.write(", ")
                writer.write(self[i, j])
            writer.write("]\n")


def check_shapes(a: Matrix, b: Matrix) raises:
    if a.cols != b.rows:
        raise Error(
            String(
                "нельзя умножить ",
                a.rows,
                "×",
                a.cols,
                " на ",
                b.rows,
                "×",
                b.cols,
            )
        )


# --- Шаг 1. Как в учебнике ----------------------------------------------


def matmul_naive(a: Matrix, b: Matrix) raises -> Matrix:
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    for i in range(a.rows):
        for j in range(b.cols):
            var acc: Float64 = 0.0
            for k in range(a.cols):
                acc += a[i, k] * b[k, j]
            c[i, j] = acc
    return c^


# --- Шаг 2. Другой порядок циклов: B читается по строкам -------------------


def matmul_reordered(a: Matrix, b: Matrix) raises -> Matrix:
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    for i in range(a.rows):
        for k in range(a.cols):
            var aik = a[i, k]
            for j in range(b.cols):
                c[i, j] += aik * b[k, j]
    return c^


# --- Шаг 3. Указатели вместо индексов списка -------------------------------


def matmul_pointers(a: Matrix, b: Matrix) raises -> Matrix:
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    var pa = a.data.unsafe_ptr()
    var pb = b.data.unsafe_ptr()
    var pc = c.data.unsafe_ptr()
    var n = b.cols
    for i in range(a.rows):
        for k in range(a.cols):
            var aik = pa.unsafe_load(i * a.cols + k)
            for j in range(n):
                var dst = i * n + j
                pc.unsafe_store(
                    dst, pc.unsafe_load(dst) + aik * pb.unsafe_load(k * n + j)
                )
    return c^


# --- Шаг 4. SIMD: строка C обновляется векторами ---------------------------


def matmul_simd(a: Matrix, b: Matrix) raises -> Matrix:
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    var pa = a.data.unsafe_ptr()
    var pb = b.data.unsafe_ptr()
    var pc = c.data.unsafe_ptr()
    var n = b.cols
    for i in range(a.rows):
        for k in range(a.cols):
            var aik = pa.unsafe_load(i * a.cols + k)

            def update[
                width: Int
            ](j: Int) {imm pb, imm pc, imm aik, imm i, imm k, imm n}:
                var dst = i * n + j
                pc.unsafe_store(
                    dst,
                    pc.unsafe_load[width=width](dst)
                    + aik * pb.unsafe_load[width=width](k * n + j),
                )

            vectorize[W](n, update)
    return c^


# --- Шаг 5. SIMD и потоки: строки C делятся между ядрами -------------------


def matmul_threads(a: Matrix, b: Matrix) raises -> Matrix:
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    var pa = a.data.unsafe_ptr()
    var pb = b.data.unsafe_ptr()
    var pc = c.data.unsafe_ptr()
    var n = b.cols
    var inner = a.cols

    def one_row(i: Int) {imm pa, imm pb, imm pc, imm n, imm inner}:
        for k in range(inner):
            var aik = pa.unsafe_load(i * inner + k)

            def update[
                width: Int
            ](j: Int) {imm pb, imm pc, imm aik, imm i, imm k, imm n}:
                var dst = i * n + j
                pc.unsafe_store(
                    dst,
                    pc.unsafe_load[width=width](dst)
                    + aik * pb.unsafe_load[width=width](k * n + j),
                )

            vectorize[W](n, update)

    parallelize(one_row, a.rows)
    return c^


# --- Шаг 6. Упаковка полосы B и блок 4 × BLOCK в регистрах -----------------

comptime BLOCK = (
    2 * W if CompilationTarget.is_x86()
    and not CompilationTarget.has_avx512f() else 4 * W
)
"""Ширина полосы. Сумматоров ROWS × BLOCK / W должно хватить регистров:
у AVX-512 и ARM их 32 — берём 4 вектора на строку (16 сумматоров),
у AVX2 всего 16 — только 2 (8 сумматоров), иначе они не поместятся."""
comptime ROWS = 4
"""Сколько строк C считается за один проход по полосе."""


def matmul(a: Matrix, b: Matrix, workers: Int = 0) raises -> Matrix:
    """Быстрое умножение: C = A × B.

    workers — сколько потоков использовать; 0 — все ядра.
    """
    check_shapes(a, b)
    var c = Matrix(a.rows, b.cols)
    var pa = a.data.unsafe_ptr()
    var pb = b.data.unsafe_ptr()
    var pc = c.data.unsafe_ptr()
    var m = a.rows
    var n = b.cols
    var inner = a.cols
    var strips = (n + BLOCK - 1) // BLOCK

    def one_strip(s: Int) {imm pa, imm pb, imm pc, imm m, imm n, imm inner}:
        var j0 = s * BLOCK
        var width = min(BLOCK, n - j0)

        # Столбцы j0 … j0 + BLOCK - 1 всех строк B — подряд в одном буфере.
        # Последняя полоса может быть уже: недостающее остаётся нулями.
        var strip = List[Float64](length=inner * BLOCK, fill=0.0)
        var ps = strip.unsafe_ptr()
        for k in range(inner):
            for t in range(width):
                ps.unsafe_store(k * BLOCK + t, pb.unsafe_load(k * n + j0 + t))

        var i = 0
        while i + ROWS <= m:
            # 4 строки × BLOCK столбцов C копятся в регистрах по всем k
            var acc0 = SIMD[DType.float64, BLOCK](0)
            var acc1 = SIMD[DType.float64, BLOCK](0)
            var acc2 = SIMD[DType.float64, BLOCK](0)
            var acc3 = SIMD[DType.float64, BLOCK](0)
            for k in range(inner):
                var bk = ps.unsafe_load[width=BLOCK](k * BLOCK)
                acc0 += pa.unsafe_load((i + 0) * inner + k) * bk
                acc1 += pa.unsafe_load((i + 1) * inner + k) * bk
                acc2 += pa.unsafe_load((i + 2) * inner + k) * bk
                acc3 += pa.unsafe_load((i + 3) * inner + k) * bk
            for t in range(width):
                pc.unsafe_store((i + 0) * n + j0 + t, acc0[t])
                pc.unsafe_store((i + 1) * n + j0 + t, acc1[t])
                pc.unsafe_store((i + 2) * n + j0 + t, acc2[t])
                pc.unsafe_store((i + 3) * n + j0 + t, acc3[t])
            i += ROWS

        # Оставшиеся строки, если m не делится на ROWS
        while i < m:
            var acc = SIMD[DType.float64, BLOCK](0)
            for k in range(inner):
                acc += pa.unsafe_load(i * inner + k) * ps.unsafe_load[
                    width=BLOCK
                ](k * BLOCK)
            for t in range(width):
                pc.unsafe_store(i * n + j0 + t, acc[t])
            i += 1

    if workers > 0:
        parallelize(one_strip, strips, workers)
    else:
        parallelize(one_strip, strips)
    return c^
