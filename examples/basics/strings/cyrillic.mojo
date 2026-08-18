def main():
    var text = String("мама мыла раму")

    # Три разных «длины» — выбираем осознанно
    print("байт:", text.byte_length())
    print("символов:", len(text.codepoints()))
    print("видимых знаков:", len(text.graphemes()))

    # Поиск возвращает позицию в БАЙТАХ, и срез по байтам с ней согласован
    var position = text.find("мыла")
    print("позиция подстроки:", position)
    print("вырезали:", text[byte=position : position + 8])

    # Срез по символам — когда важны буквы, а не байты
    print("первое слово:", text[codepoint=0:4])

    # Перебор по символам
    for symbol in String("ёжик").codepoints():
        print(symbol, end="|")
    print()

    # Регистр работает и для кириллицы, включая букву ё
    print(String("ёжик").upper(), String("ЁЖИК").lower())

    # Эмодзи: один видимый знак может занимать много байт
    var family = String("👨‍👩‍👧")
    print("эмодзи — байт:", family.byte_length())
    print("эмодзи — кодовых точек:", len(family.codepoints()))
    print("эмодзи — видимых знаков:", len(family.graphemes()))
