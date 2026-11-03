def status(code: Int) -> String:
    match code:
        case 200:
            return "всё хорошо"
        case 301 | 302:
            return "страница переехала"
        case 404 as missing:
            return String("нет такой страницы (", missing, ")")
        case c if c >= 500:
            return String("сломался сервер, код ", c)
        case _:
            return "что-то другое"


def answer(text: String) -> String:
    match text:
        case "да" | "yes":
            return "согласие"
        case "нет" | "no":
            return "отказ"
        case _:
            return "непонятно"


def fizzbuzz(n: Int) -> String:
    match n % 3 == 0, n % 5 == 0:
        case True, True:
            return "FizzBuzz"
        case True, False:
            return "Fizz"
        case False, True:
            return "Buzz"
        case False, False:
            return String(n)


def main():
    for code in [200, 302, 404, 503, 418]:
        print(code, "—", status(code))

    print(answer("yes"), answer("нет"), answer("может быть"))

    for n in range(1, 16):
        print(fizzbuzz(n), end=" ")
    print()
