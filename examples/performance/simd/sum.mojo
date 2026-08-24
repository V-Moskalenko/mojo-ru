# Сумма массива: поэлементно и вектором.
#
# Длина нарочно не кратна ширине вектора — так бывает почти всегда,
# и хвост приходится досчитывать отдельно.

from std.sys import simd_width_of

comptime W = simd_width_of[DType.float32]()
comptime N = 1001  # нечётное: хвост будет при любой ширине вектора


def scalar_sum(data: List[Float32]) -> Float32:
    """По одному числу за раз."""
    var total = Float32(0)
    for i in range(len(data)):
        total += data[i]
    return total


def vector_sum(data: List[Float32]) -> Float32:
    """По W чисел за раз, плюс хвост."""
    var ptr = data.unsafe_ptr()
    var accumulator = SIMD[DType.float32, W](0)

    # Основная часть: столько полных векторов, сколько влезло.
    var full = (len(data) // W) * W
    for i in range(0, full, W):
        accumulator += ptr.unsafe_load[width=W](i)

    # Складываем полосы аккумулятора в одно число.
    var total = accumulator.reduce_add()

    # Хвост: оставшиеся элементы — по одному.
    for i in range(full, len(data)):
        total += data[i]

    return total


def main():
    var data = List[Float32](capacity=N)
    for i in range(N):
        data.append(Float32((i * 37) % 100))

    var a = scalar_sum(data)
    var b = vector_sum(data)

    # W у каждой машины своё, поэтому печатаем не его, а то,
    # что от машины не зависит.
    print("элементов:", N)
    print("поэлементно:", a)
    print("вектором:   ", b)
    print("совпало:", a == b)
    print("длина нечётная, значит хвост есть при любой ширине вектора")
