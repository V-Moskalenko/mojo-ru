# ожидается: cannot call raising function in comptime initializer


def parse() raises -> Int:
    return 1


comptime N = parse()


def main():
    print(N)
