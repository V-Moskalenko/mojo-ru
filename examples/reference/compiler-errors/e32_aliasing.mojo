# ожидается: aliasing values passed mutably


def bump(mut x: Int, mut y: Int):
    x += 1
    y += 1


def main():
    var n = 1
    bump(n, n)
