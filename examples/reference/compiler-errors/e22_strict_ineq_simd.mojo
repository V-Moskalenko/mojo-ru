# ожидается: Strict inequality is only defined for `Scalar`s


def main():
    var v = SIMD[DType.float32, 4](1, 2, 3, 4)
    print(v > 2)
