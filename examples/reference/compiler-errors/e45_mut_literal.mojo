# ожидается: invalid call to 'bump': value passed to mutable argument 'counter' must be mutable


def bump(mut counter: Int):
    counter += 1


def main():
    bump(5)
