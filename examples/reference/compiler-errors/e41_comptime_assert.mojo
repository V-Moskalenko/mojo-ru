# ожидается: число должно быть чётным


def main():
    comptime N = 3
    comptime assert N % 2 == 0, "число должно быть чётным"
