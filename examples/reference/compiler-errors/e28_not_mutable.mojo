# ожидается: expression must be mutable for in-place operator destination


def bump(counter: Int):
    counter += 1


def main():
    bump(1)
