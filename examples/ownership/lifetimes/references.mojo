# Ссылки, которые переживают возврат из функции, — и их происхождение.


@fieldwise_init
struct Account:
    """Счёт: имя владельца и баланс."""

    var owner: String
    var balance: Int

    def balance_ref(ref self) -> ref [self.balance] Int:
        """Возвращает ссылку на поле — через неё можно и читать, и писать."""
        return self.balance


def biggest(ref numbers: List[Int]) -> ref [numbers[0]] Int:
    """Возвращает ссылку на наибольший элемент списка."""
    var best = 0
    for index in range(len(numbers)):
        if numbers[index] > numbers[best]:
            best = index
    return numbers[best]


def main():
    print("1. ссылка на элемент списка")
    var scores: List[Int] = [3, 9, 4]
    print("   максимум:", biggest(scores))
    biggest(scores) = 0
    print("   после обнуления максимума:", scores[0], scores[1], scores[2])

    print("2. ссылка на поле структуры")
    var account = Account("Анна", 100)
    account.balance_ref() = 250
    print("  ", account.owner, "->", account.balance)

    print("3. указатель — та же ссылка, но как значение")
    var total = 10
    var pointer = Pointer(to=total)
    pointer[] += 5
    print("   total:", total)

    print("4. ссылка живёт ровно до последнего использования")
    var queue: List[Int] = [1, 2]
    var head = Pointer(to=queue[0])
    print("   первый элемент:", head[])
    queue.append(3)
    print("   после append длина:", len(queue))
