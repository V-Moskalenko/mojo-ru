def greet(name: String, greeting: String = "Привет") -> String:
    """Собирает приветствие. Значение по умолчанию — как в Python."""
    return greeting + ", " + name + "!"


def main():
    # Функции, значения по умолчанию и именованные аргументы
    print(greet("Мир"))
    print(greet(name="Mojo", greeting="Здравствуй"))

    # Списки и генераторы списков
    var squares: List[Int] = [i * i for i in range(5)]
    for value in squares:
        print(value, end=" ")
    print()

    # Словари доступны без импорта
    var ages = Dict[String, Int]()
    ages["Аня"] = 30
    ages["Борис"] = 25
    print("людей в словаре:", len(ages))

    # Циклы, условия, break и continue
    var total = 0
    for i in range(10):
        if i % 2 == 0:
            continue
        if i > 7:
            break
        total += i
    print("сумма нечётных до 7:", total)

    # Кортежи и множественное присваивание
    var left, right = 1, 2
    print("слева", left, "справа", right)
