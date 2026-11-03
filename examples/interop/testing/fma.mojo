from std.sys import argv


def scale_minus_one(x: Float64, y: Float64) -> Float64:
    return x * y - 1.0


def main() raises:
    print("литералы:", scale_minus_one(0.1, 10.0))
    # то же 0.1, но из командной строки: при компиляции его не знает никто
    var price = atof(argv()[1])
    print("из аргументов:", scale_minus_one(price, 10.0))
