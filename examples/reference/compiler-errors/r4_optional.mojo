# ожидается: `Optional.value()` called on empty `Optional`


def main():
    var maybe = Optional[Int]()
    print(maybe.value())
