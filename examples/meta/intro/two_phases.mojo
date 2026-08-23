# Что происходит на сборке, а что — при запуске.


def triangular(n: Int) -> Int:
    """Сумма чисел от 1 до n. Обычная функция, ничего особенного."""
    var total = 0
    for value in range(1, n + 1):
        total += value
    return total


# Считается один раз при сборке — в готовой программе тут уже число.
comptime SIZE = triangular(4)


def label[verbose: Bool]() -> String:
    """Ветка выбирается на этапе компиляции, в программу попадёт только одна."""
    comptime if verbose:
        return String("подробный режим")
    else:
        return String("кратко")


def banner[times: Int](text: String):
    """Цикл разворачивается при сборке: цикла в готовой программе нет."""
    comptime for index in range(times):
        print("  ", index, text)


def main():
    print("1. значение посчитано при сборке:", SIZE)

    print("2. его можно использовать там, где нужна константа")
    var buffer = InlineArray[Int, SIZE](fill=0)
    print("   длина буфера:", len(buffer))

    print("3. ветка выбрана при сборке")
    print("  ", label[True]())
    print("  ", label[False]())

    print("4. цикл развёрнут при сборке")
    banner[3]("повтор")
