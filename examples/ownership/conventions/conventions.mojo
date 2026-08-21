# Пять конвенций передачи аргументов на одном примере.


@fieldwise_init
struct Report(ImplicitlyCopyable, Writable):
    """Отчёт: название и число страниц."""

    var title: String
    var pages: Int

    def write_to[W: Writer](self, mut writer: W):
        """Печатает отчёт человекочитаемо."""
        writer.write(self.title, ", страниц: ", self.pages)


def describe(report: Report):
    """Только читает аргумент — конвенция по умолчанию."""
    print("  ", report)


def add_page(mut report: Report):
    """Меняет аргумент на месте, изменение видно вызывающему коду."""
    report.pages += 1


def archive(var report: Report):
    """Забирает владение: после вызова оригинал недоступен."""
    report.title += " (в архиве)"
    print("  ", report)


def longer(ref a: String, ref b: String) -> ref [a, b] String:
    """Возвращает ссылку на более длинную из двух строк."""
    return a if a.byte_length() > b.byte_length() else b


def make_default(out report: Report):
    """Создаёт значение прямо в аргументе-результате."""
    report = Report("Без названия", 1)


def main():
    var report = Report("Отчёт за август", 10)

    print("по умолчанию — только чтение:")
    describe(report)

    print("mut — изменение на месте:")
    add_page(report)
    add_page(report)
    describe(report)

    print("ref — ссылка, которую можно вернуть наружу:")
    var short = String("раз")
    var long = String("двадцать")
    print("   длиннее:", longer(short, long))
    longer(short, long) = String("заменено")
    print("   после записи по ссылке:", short, "|", long)

    print("out — результат приходит через аргумент:")
    var fresh = make_default()
    describe(fresh)

    print("var — передача владения:")
    archive(report^)
