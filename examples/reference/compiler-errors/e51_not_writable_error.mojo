# ожидается: cannot implicitly convert 'ParseError' value to 'Error'


@fieldwise_init
struct ParseError(Copyable):
    var position: Int


def parse(text: String) raises -> Int:
    raise ParseError(3)


def main():
    try:
        _ = parse("x")
    except e:
        print(e)
