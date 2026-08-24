# vectorize делает то же, что мы писали руками в главе про SIMD:
# режет массив на векторы и досчитывает хвост. Только сам.
#
# Обратите внимание на список захвата {imm ptr} — без него вложенная
# функция не увидит переменных снаружи.

from std.algorithm import vectorize
from std.sys import simd_width_of

comptime W = simd_width_of[DType.float32]()
comptime N = 1001  # нечётное: хвост будет при любой ширине


def scale_by_hand(mut data: List[Float32], k: Float32):
    """Ручная версия: основная часть плюс хвост."""
    var ptr = data.unsafe_ptr()
    var full = (len(data) // W) * W

    for i in range(0, full, W):
        ptr.unsafe_store(i, ptr.unsafe_load[width=W](i) * k)

    for i in range(full, len(data)):
        ptr.unsafe_store(i, ptr.unsafe_load(i) * k)


def scale_with_vectorize(mut data: List[Float32], k: Float32):
    """То же самое, но нарезку и хвост берёт на себя библиотека."""
    var ptr = data.unsafe_ptr()

    # width приходит параметром: для основной части он равен W,
    # для хвоста библиотека вызовет эту же функцию с width = 1.
    def step[width: Int](idx: Int) {imm ptr, imm k}:
        ptr.unsafe_store(idx, ptr.unsafe_load[width=width](idx) * k)

    vectorize[W](len(data), step)


def main():
    var a = List[Float32](length=N, fill=0)
    var b = List[Float32](length=N, fill=0)
    for i in range(N):
        a[i] = Float32(i)
        b[i] = Float32(i)

    scale_by_hand(a, 2.0)
    scale_with_vectorize(b, 2.0)

    var same = True
    for i in range(N):
        if a[i] != b[i]:
            same = False

    print("элементов:", N)
    print("первый и последний:", a[0], a[N - 1])
    print("руками и через vectorize совпало:", same)
