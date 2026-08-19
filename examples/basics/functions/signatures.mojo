def greet(name: String, greeting: String = "Привет") -> String:
    """Значение по умолчанию и именованные аргументы — как в Python."""
    return greeting + ", " + name + "!"


def describe(value: Int):
    """Перегрузка: одно имя, разные типы аргумента."""
    print("целое:", value)


def describe(value: String):
    print("строка:", value)


def divide(a: Int, b: Int) -> Tuple[Int, Int]:
    """Вернуть несколько значений можно кортежем."""
    return (a // b, a % b)


def total(*values: Int) -> Int:
    """Вариативные аргументы: сколько угодно чисел."""
    var sum = 0
    for value in values:
        sum += value
    return sum


def bump(mut counter: Int):
    """Аргумент mut означает, что функция меняет переменную вызывающего кода."""
    counter += 1


def repeat[count: Int](text: String):
    """Параметр count известен на этапе компиляции — он в квадратных скобках."""
    for _ in range(count):
        print(text, end=" ")
    print()


def main():
    print(greet("Мир"))
    print(greet(name="Mojo", greeting="Здравствуй"))

    describe(42)
    describe(String("сорок два"))

    var result = divide(17, 5)
    print("частное и остаток:", result[0], result[1])

    print("сумма:", total(1, 2, 3, 4))

    var counter = 10
    bump(counter)
    print("после bump:", counter)

    repeat[3](String("эй"))
