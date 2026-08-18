def main():
    var counter = 0

    # Переменная, объявленная внутри блока, живёт только в этом блоке
    if counter == 0:
        var message = "счётчик пуст"
        print(message)

    # Здесь `message` уже не существует — попытка обратиться к нему
    # не скомпилируется

    # Имя можно затенить во вложенном блоке: это разные переменные
    var name = "внешняя"
    while counter < 1:
        var name = "внутренняя"
        print("внутри блока:", name)
        counter += 1
    print("снаружи блока:", name)

    # Объявить сейчас, значение присвоить позже — можно
    var limit: Int
    if counter > 0:
        limit = 100
    else:
        limit = 0
    print("предел:", limit)
