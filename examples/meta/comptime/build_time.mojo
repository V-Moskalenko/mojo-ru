# Одна маленькая задача: перевести число байт в человекочитаемый вид.
# Вся таблица множителей считается на сборке — в готовой программе
# от неё остаются только готовые числа.

from std.builtin.globals import global_constant

comptime UNITS = 5


def build_scale() -> Array[Int, UNITS]:
    """Степени 1024: 1, 1024, 1048576, ..."""
    var table = Array[Int, UNITS](fill=1)
    for index in range(1, UNITS):
        table[index] = table[index - 1] * 1024
    return table^


comptime SCALE = build_scale()
comptime NAMES: Array[StaticString, UNITS] = ["Б", "КБ", "МБ", "ГБ", "ТБ"]

# Параметризованное значение: своё для каждого аргумента.
comptime Doubled[value: Int]: Int = value * 2


def human(size: Int) -> String:
    """Подбирает ступень и форматирует размер."""
    # global_constant кладёт таблицу в статическую память программы,
    # а ref связывает ссылку на неё — копии не возникает.
    ref scale = global_constant[SCALE]()
    ref names = global_constant[NAMES]()

    var index = 0
    while index + 1 < UNITS and size >= scale[index + 1]:
        index += 1

    return String(size // scale[index]) + " " + String(names[index])


def main():
    comptime assert UNITS > 1, "нужна хотя бы одна ступень"

    print("таблица посчитана при сборке, в программе — готовые числа")
    print("  ", human(512))
    print("  ", human(2048))
    print("  ", human(5 * 1024 * 1024))

    print("самая большая ступень:", comptime (SCALE[UNITS - 1]))
    print("параметризованное значение:", Doubled[21])
