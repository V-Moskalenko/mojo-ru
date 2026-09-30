# Пути как объекты: склейка через /, части имени, чтение и запись.
from std.os import makedirs
from std.pathlib import Path
from std.tempfile import TemporaryDirectory


def main() raises:
    var p = Path("data") / "2026" / "report.final.csv"
    print(p)
    print(p.name(), p.suffix())
    print(p.parts())

    with TemporaryDirectory() as tmp:
        var root = Path(tmp)
        (root / "a.txt").write_text("альфа")
        (root / "b.csv").write_text(String("x,y\n", 1, ",", 2, "\n"))
        makedirs(root / "sub" / "deep")

        print((root / "a.txt").read_text())
        print((root / "a.txt").exists(), (root / "zzz").exists())
        print((root / "a.txt").is_file(), (root / "sub").is_dir())

        # listdir() не обещает порядок — сортируем сами
        var names = List[String]()
        for child in root.listdir():
            names.append(child.name())
        sort(names)
        print(names)
