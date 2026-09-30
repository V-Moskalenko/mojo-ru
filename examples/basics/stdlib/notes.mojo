# Запись, дозапись и чтение текстового файла.
# Файл создаётся во временном каталоге, который удаляется сам.
from std.os.path import join
from std.tempfile import TemporaryDirectory


def main() raises:
    with TemporaryDirectory() as tmp:
        var path = join(tmp, "notes.txt")

        # "w" — создать файл или стереть старое содержимое
        with open(path, "w") as f:
            f.write("первая строка\n")
            f.write("число: ", 42, ", дробь: ", 2.5, "\n")

        # "a" — дописать в конец
        with open(path, "a") as f:
            f.write("дописали в конец\n")

        # "r" — прочитать; read() без аргумента отдаёт весь файл
        with open(path, "r") as f:
            var text = f.read()
            for i, line in enumerate(text.splitlines()):
                print(i + 1, "|", line)
