# ожидается: lacking evidence to prove correctness


def half[n: Int]() -> Int where n % 2 == 0:
    return n // 2


def main():
    print(half[10]())
