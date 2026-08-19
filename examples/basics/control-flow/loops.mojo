def main():
    # Ветвление и тернарный оператор
    var temperature = 25
    if temperature > 30:
        print("жарко")
    elif temperature > 20:
        print("тепло")
    else:
        print("прохладно")

    print("одеваться:", "легко" if temperature > 20 else "тепло")

    # range: с началом, концом и шагом, в том числе отрицательным
    for i in range(10, 0, -3):
        print(i, end=" ")
    print()

    # Перебор списка вместе с индексом
    var cities: List[String] = ["Москва", "Казань", "Томск"]
    for index, city in enumerate(cities):
        print(index, city)

    # Два списка параллельно
    var population: List[Int] = [13, 1, 0]
    for pair in zip(cities, population):
        print(pair[0], "—", pair[1], "млн")

    # Изменение элементов прямо в цикле: ref даёт ссылку на элемент
    var numbers: List[Int] = [1, 2, 3]
    for ref value in numbers:
        value *= 10
    print("после умножения:", numbers[0], numbers[1], numbers[2])

    # break и continue
    var sum = 0
    for value in range(1, 10):
        if value % 2 == 0:
            continue
        if value > 7:
            break
        sum += value
    print("сумма нечётных до 7:", sum)

    # У циклов есть else — он срабатывает, если не было break
    for value in range(2):
        print("шаг", value)
    else:
        print("цикл дошёл до конца")

    # Перебор словаря: items() даёт сразу ключ и значение
    var codes = Dict[String, Int]()
    codes["Москва"] = 495
    codes["Казань"] = 843
    for item in codes.items():
        print(item.key, item.value)
