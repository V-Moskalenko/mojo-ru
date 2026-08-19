# Разбор пользовательского ввода: исключения, Optional и with.


@fieldwise_init
struct Section(ImplicitlyCopyable):
    """Печатает заголовок и подводит черту, что бы ни случилось внутри."""

    var title: String

    def __enter__(self) -> Self:
        print("--", self.title)
        return self

    def __exit__(self):
        print("-- конец:", self.title)


def parse_age(text: String) raises -> Int:
    """Превращает строку в возраст или объясняет, почему это невозможно."""
    var value = Int(text)
    if value < 0:
        raise Error("возраст отрицательный")
    if value > 150:
        raise Error("возраст слишком большой")
    return value


def parse_or_default(text: String, fallback: Int) -> Int:
    """Возвращает разобранное значение или запасное, не роняя программу."""
    try:
        return parse_age(text)
    except:
        return fallback


def try_parse(text: String) -> Optional[Int]:
    """Возвращает значение, если разбор удался, и пустой Optional иначе."""
    try:
        return Optional[Int](parse_age(text))
    except:
        return Optional[Int]()


def main():
    var inputs: List[String] = ["30", "abc", "-5", "200"]

    with Section("подробный разбор"):
        for text in inputs:
            try:
                print(text, "->", parse_age(text))
            except e:
                print(text, "-> отклонено:", e)

    with Section("со значением по умолчанию"):
        for text in inputs:
            print(text, "->", parse_or_default(text, 18))

    with Section("через Optional"):
        for text in inputs:
            var result = try_parse(text)
            if result:
                print(text, "-> значение", result.value())
            else:
                print(text, "-> значения нет")

    with Section("порядок выполнения"):
        for text in ["7", "нет"]:
            try:
                print("пробуем:", text)
                print("разобрали:", parse_age(text))
            except e:
                print("except:", e)
            else:
                print("else: ошибок не было")
            finally:
                print("finally: выполняется всегда")
