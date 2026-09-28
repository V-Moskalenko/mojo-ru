# ожидается: execution crashed

from std.sys import argv


def main():
    var b = len(argv()) - 1  # без аргументов b == 0
    print(7 / b)
