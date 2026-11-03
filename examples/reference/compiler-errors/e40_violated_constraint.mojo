# ожидается: violated constraint


def pow2[n: Int]() -> Int where n > 0:
    return 1 << n


def main():
    print(pow2[0]())
