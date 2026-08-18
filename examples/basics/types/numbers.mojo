def main() raises:
    # Int — целое машинное слово, на 64-битной системе это 64 бита
    var big = 2**62
    print("большое целое:", big)

    # Размерные типы указываются явно и НЕ смешиваются с Int автоматически
    var small: Int8 = 127
    small += 1
    print("Int8 после переполнения:", small)

    # Деление: осторожно
    var a = 7
    var b = 2
    print("Int / Int:", a / b)
    print("после преобразования:", Float64(a) / Float64(b))
    print("целочисленное деление:", a // b)

    # SIMD — обычный тип языка, операции идут сразу над всеми элементами
    var vector = SIMD[DType.float32, 4](1, 2, 3, 4)
    print("вектор * 2:", vector * 2)
    print("сумма элементов:", vector.reduce_add())

    # Преобразования всегда явные
    var text = String(255)
    var back = Int(text)
    print("строка и обратно:", text, back + 1)
