def main():
    var s = "Привет"

    # В Mojo нет одной «длины строки»: нужно сказать, что именно считать
    print("байт:", s.byte_length())
    print("кодовых точек:", len(s.codepoints()))
    print("графем:", len(s.graphemes()))

    # Срезать тоже нужно осознанно — по байтам или по символам
    print("первые три символа:", s[codepoint=0:3])
    print("первые четыре байта:", s[byte=0:4])

    # Вместо f-строк — обычная передача аргументов в print
    var count = len(s.codepoints())
    print("в слове", s, "ровно", count, "букв")
