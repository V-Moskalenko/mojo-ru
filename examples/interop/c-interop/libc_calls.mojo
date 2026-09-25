# Вызовы стандартной библиотеки C из Mojo.
#
# Всё здесь — функции libc: она есть в любой системе, ставить ничего
# не нужно. Каждый результат сверяется с тем же расчётом на Mojo.

from std.ffi import external_call, c_int, c_double, c_size_t
from std.math import sqrt


def main():
    print("1. числа: C и Mojo должны совпасть")
    var x = c_double(2.0)
    var from_c = external_call["sqrt", c_double](x)
    print("   sqrt из C:   ", from_c)
    print("   sqrt из Mojo:", sqrt(Float64(2.0)))
    print("   pow(2, 10):  ", external_call["pow", c_double](c_double(2.0), c_double(10.0)))
    print("   abs(-42):    ", external_call["abs", c_int](c_int(-42)))

    print("2. строка в C: считаются байты, а не символы")
    var word = String("привет")
    var c_length = external_call["strlen", c_size_t](word.as_c_string_span().ptr())
    print("   strlen:      ", c_length)
    print("   byte_length: ", word.byte_length())

    print("3. ловушка: срез без завершающего нуля")
    var text = String("abcdef")
    var view = text[byte=0:3]
    print("   срез:", view, "| его длина:", view.byte_length())
    # unsafe_ptr() среза указывает внутрь "abcdef": после "abc" нуля нет,
    # и C читает дальше, пока не наткнётся на ноль исходной строки.
    print("   strlen по unsafe_ptr среза:", external_call["strlen", c_size_t](view.unsafe_ptr()))
    # Правильно: сделать из среза настоящую строку — у неё ноль на месте.
    var copy = String(view)
    print("   strlen по копии:", external_call["strlen", c_size_t](copy.as_c_string_span().ptr()))
