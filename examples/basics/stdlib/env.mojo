# Функции os.path работают со строками; getenv читает переменные окружения.
from std.os import getenv, setenv, unsetenv
from std.os.path import basename, dirname, join, split_extension


def main() raises:
    var p = join("data", "2026", "report.csv")
    print(p)
    print(basename(p), "|", dirname(p))
    var stem_ext = split_extension(p)
    print(stem_ext[0], "|", stem_ext[1])

    # нет переменной — пустая строка или запасное значение
    print(getenv("MOJO_KURS_NO_SUCH_VAR") == "")
    print(getenv("MOJO_KURS_NO_SUCH_VAR", "по умолчанию"))

    _ = setenv("MOJO_KURS_LEVEL", "3")
    print(getenv("MOJO_KURS_LEVEL"))
    _ = unsetenv("MOJO_KURS_LEVEL")
    print(getenv("MOJO_KURS_LEVEL", "нет"))
