# ожидается: cannot call function that may raise in a context that cannot raise


def risky() raises:
    raise Error("сбой")


def main():
    risky()
