comptime MAX_RUBLE_DIGITS = 15
"""Больше 15 цифр рублей — и сумма в копейках не влезет в Int."""


def _only_digits(text: StringSlice) -> Bool:
    if text.byte_length() == 0:
        return False
    for byte in text.as_bytes():
        if byte < UInt8(ord("0")) or byte > UInt8(ord("9")):
            return False
    return True


def parse_cents(text: String) raises -> Int:
    """Переводит «12.50» в 1250 копеек, а «12» — в 1200."""
    var clean = text.strip()
    if clean.startswith("-"):
        raise Error("сумма не может быть отрицательной: " + text)

    var parts = clean.split(".")
    if len(parts) > 2:
        raise Error("лишняя точка: " + text)
    if not _only_digits(parts[0]):
        raise Error("до точки нужны только цифры: " + text)
    if parts[0].byte_length() > MAX_RUBLE_DIGITS:
        raise Error("слишком большая сумма: " + text)

    var kopecks = 0
    if len(parts) == 2:
        if parts[1].byte_length() != 2 or not _only_digits(parts[1]):
            raise Error("после точки нужны ровно две цифры: " + text)
        kopecks = Int(parts[1])
    return Int(parts[0]) * 100 + kopecks


def split_bill(total: Int, people: Int) raises -> List[Int]:
    """Делит счёт поровну; лишние копейки достаются первым по одной."""
    if total < 0:
        raise Error("сумма не может быть отрицательной")
    if people <= 0:
        raise Error("некому платить")
    var share = total // people
    var extra = total % people
    var result = List[Int]()
    for i in range(people):
        result.append(share + (1 if i < extra else 0))
    return result^
