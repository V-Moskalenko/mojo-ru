"""Утилита wordfreq: частотный словарь текста."""

from std.sys import argv, exit, stderr

comptime USAGE = """Использование: wordfreq [-n N] [--min-len K] ФАЙЛ...

Показывает, какие слова чаще всего встречаются в текстовых файлах.

  -n N          сколько слов показать (по умолчанию 10)
  --min-len K   не считать слова короче K букв (по умолчанию 1)
  -h, --help    показать эту справку

Вместо имени файла можно указать «-»: текст прочитается
из стандартного ввода."""

comptime PUNCTUATION = ".,:;!?()[]{}«»\"'`*_—–-…/\\|<>#=+~"


@fieldwise_init
struct Options(Movable):
    var top: Int
    var min_len: Int
    var files: List[String]


def positive_int(flag: String, value: String) raises -> Int:
    var n: Int
    try:
        n = Int(value)
    except:
        raise Error(
            String("после ", flag, " нужно целое число, а не «", value, "»")
        )
    if n <= 0:
        raise Error(String("после ", flag, " нужно число больше нуля"))
    return n


def parse_args(mut options: Options) raises:
    var args = argv()
    var i = 1
    while i < len(args):
        var arg = String(args[i])
        if arg == "-h" or arg == "--help":
            print(USAGE)
            exit(0)
        elif arg == "-n" or arg == "--min-len":
            if i + 1 >= len(args):
                raise Error(String("после ", arg, " нужно число"))
            var value = positive_int(arg, String(args[i + 1]))
            if arg == "-n":
                options.top = value
            else:
                options.min_len = value
            i += 1
        elif arg.startswith("-") and arg != "-":
            raise Error(String("неизвестный ключ ", arg))
        else:
            options.files.append(arg)
        i += 1
    if len(options.files) == 0:
        raise Error("не указано ни одного файла")


def read_all(path: String) raises -> String:
    var name = "/dev/stdin" if path == "-" else path
    with open(name, "r") as f:
        return f.read()


def count_words(
    text: String, min_len: Int, mut counts: Dict[String, Int]
) -> Int:
    var total = 0
    # split() режет только по ASCII-пробелам, а в русских текстах после
    # типографа часто стоит неразрывный пробел U+00A0: превращаем его в обычный
    for raw in text.lower().replace("\u00a0", " ").split():
        var word = raw.strip(PUNCTUATION)
        if len(word.codepoints()) < min_len:
            continue
        total += 1
        var key = String(word)
        counts[key] = counts.get(key, 0) + 1
    return total


def main():
    var options = Options(top=10, min_len=1, files=[])
    try:
        parse_args(options)
    except e:
        print("wordfreq:", e, file=stderr)
        print("Подробнее: wordfreq --help", file=stderr)
        exit(2)

    var counts = Dict[String, Int]()
    var total = 0
    var failed = False
    for path in options.files:
        try:
            total += count_words(read_all(path), options.min_len, counts)
        except e:
            print(String("wordfreq: ", path, ": ", e), file=stderr)
            failed = True

    var pairs = List[Tuple[String, Int]]()
    for item in counts.items():
        pairs.append((item.key, item.value))

    def more_frequent(a: Tuple[String, Int], b: Tuple[String, Int]) -> Bool:
        if a[1] != b[1]:
            return a[1] > b[1]
        return a[0] < b[0]

    sort(pairs, more_frequent)

    print(String("всего слов: ", total, ", различных: ", len(pairs)))
    for i in range(min(options.top, len(pairs))):
        var word = pairs[i][0]
        var number = String(i + 1)
        var left = " " * (3 - number.byte_length())
        var right = " " * max(16 - len(word.codepoints()), 1)
        print(left, number, ". ", word, right, pairs[i][1], sep="")

    if failed:
        exit(1)
