# ожидается: does not conform to trait 'Shape'


trait Shape:
    def area(self) -> Float64:
        ...


@fieldwise_init
struct Rock:
    var weight: Int


def report[T: Shape](s: T):
    print(s.area())


def main():
    report(Rock(1))
