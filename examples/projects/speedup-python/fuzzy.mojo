"""Модуль для Python: поиск похожих слов по расстоянию Левенштейна.

Все шаги ускорения из главы — отдельными функциями, чтобы их можно было
сравнить. В настоящей программе нужна только последняя, all_pairs_myers.
"""

from std.os import abort
from std.python import Python, PythonObject
from std.python.bindings import PythonModuleBuilder


@export
def PyInit_fuzzy() abi("C") -> PythonObject:
    try:
        var m = PythonModuleBuilder("fuzzy")
        m.def_function[levenshtein](
            "levenshtein", docstring="Расстояние между двумя словами"
        )
        m.def_function[similar](
            "similar", docstring="Слова из списка, похожие на данное"
        )
        m.def_function[all_pairs](
            "all_pairs", docstring="Все пары похожих слов"
        )
        m.def_function[all_pairs_unchecked](
            "all_pairs_unchecked", docstring="То же без проверок границ"
        )
        m.def_function[all_pairs_cutoff](
            "all_pairs_cutoff", docstring="То же с ранним выходом"
        )
        m.def_function[all_pairs_myers](
            "all_pairs_myers", docstring="То же битовым алгоритмом Майерса"
        )
        return m.finalize()
    except e:
        abort(String("не удалось создать модуль fuzzy: ", e))


# --- Общее: слова как списки кодов символов ---------------------------------


def to_codepoints(obj: PythonObject) raises -> List[UInt32]:
    """Строка Python → коды символов: сравниваем буквы, а не байты UTF-8.

    String(py=...), а не String(...): если строку Python нельзя перевести
    в UTF-8 (одиночный суррогат вроде U+D800), первое бросает обычное
    исключение, а второе роняет весь процесс."""
    var out = List[UInt32]()
    for c in String(py=obj).codepoints():
        out.append(c.to_u32())
    return out^


def to_codepoint_lists(words: PythonObject) raises -> List[List[UInt32]]:
    var out = List[List[UInt32]]()
    for w in words:
        out.append(to_codepoints(w))
    return out^


def longest(words: List[List[UInt32]]) -> Int:
    var n = 0
    for w in words:
        n = max(n, len(w))
    return n


# --- Шаг 1. Та же динамика, что в Python ------------------------------------


def distance(a: List[UInt32], b: List[UInt32], mut rows: List[Int]) -> Int:
    """Две строки таблицы лежат в одном буфере rows; prev и cur — смещения,
    и «поменять строки» значит поменять смещения."""
    var n = len(b)
    var prev = 0
    var cur = n + 1
    for j in range(n + 1):
        rows[prev + j] = j
    for i in range(1, len(a) + 1):
        rows[cur] = i
        for j in range(1, n + 1):
            var cost = 0 if a[i - 1] == b[j - 1] else 1
            rows[cur + j] = min(
                rows[prev + j] + 1,
                rows[cur + j - 1] + 1,
                rows[prev + j - 1] + cost,
            )
        swap(prev, cur)
    return rows[prev + n]


def levenshtein(py_a: PythonObject, py_b: PythonObject) raises -> PythonObject:
    """Одна пара за вызов: Python зовёт её миллион раз."""
    var a = to_codepoints(py_a)
    var b = to_codepoints(py_b)
    var rows = List[Int](length=2 * (len(b) + 1), fill=0)
    return PythonObject(distance(a, b, rows))


def similar(
    py_word: PythonObject, py_candidates: PythonObject, py_max: PythonObject
) raises -> PythonObject:
    """Одно слово против всех кандидатов за вызов."""
    var word = to_codepoints(py_word)
    var max_dist = Int(py=py_max)
    var out = Python.list()
    for py_c in py_candidates:
        var c = to_codepoints(py_c)
        if abs(len(word) - len(c)) > max_dist:
            continue
        var rows = List[Int](length=2 * (len(c) + 1), fill=0)
        if distance(word, c, rows) <= max_dist:
            out.append(py_c)
    return out


def all_pairs(
    py_rare: PythonObject, py_common: PythonObject, py_max: PythonObject
) raises -> PythonObject:
    """Весь двойной цикл за один вызов; слова переводятся в коды один раз."""
    var max_dist = Int(py=py_max)
    var rare = to_codepoint_lists(py_rare)
    var common = to_codepoint_lists(py_common)
    var rows = List[Int](length=2 * (longest(common) + 1), fill=0)
    var out = Python.list()
    for i in range(len(rare)):
        for j in range(len(common)):
            if abs(len(rare[i]) - len(common[j])) > max_dist:
                continue
            if distance(rare[i], common[j], rows) <= max_dist:
                out.append(Python.tuple(py_rare[i], py_common[j]))
    return out


# --- Шаги 2 и 3. Без проверок границ и с ранним выходом ---------------------


def distance_fast(
    a: List[UInt32],
    b: List[UInt32],
    mut rows: List[Int],
    max_dist: Int,
    cutoff: Bool,
) -> Int:
    """Та же динамика через указатели. Если cutoff — бросаем счёт, как только
    вся строка таблицы больше max_dist: дальше значения только растут."""
    var n = len(b)
    var pa = a.unsafe_ptr()
    var pb = b.unsafe_ptr()
    var r = rows.unsafe_ptr()
    var prev = 0
    var cur = n + 1
    for j in range(n + 1):
        r.unsafe_store(prev + j, j)
    for i in range(1, len(a) + 1):
        r.unsafe_store(cur, i)
        var ca = pa.unsafe_load(i - 1)
        var row_min = i
        for j in range(1, n + 1):
            var cost = 0 if ca == pb.unsafe_load(j - 1) else 1
            var v = min(
                r.unsafe_load(prev + j) + 1,
                r.unsafe_load(cur + j - 1) + 1,
                r.unsafe_load(prev + j - 1) + cost,
            )
            r.unsafe_store(cur + j, v)
            row_min = min(row_min, v)
        if cutoff and row_min > max_dist:
            return max_dist + 1
        swap(prev, cur)
    return r.unsafe_load(prev + n)


def pairs_fast(
    py_rare: PythonObject,
    py_common: PythonObject,
    py_max: PythonObject,
    cutoff: Bool,
) raises -> PythonObject:
    var max_dist = Int(py=py_max)
    var rare = to_codepoint_lists(py_rare)
    var common = to_codepoint_lists(py_common)
    var rows = List[Int](length=2 * (longest(common) + 1), fill=0)
    var out = Python.list()
    for i in range(len(rare)):
        for j in range(len(common)):
            if abs(len(rare[i]) - len(common[j])) > max_dist:
                continue
            if (
                distance_fast(rare[i], common[j], rows, max_dist, cutoff)
                <= max_dist
            ):
                out.append(Python.tuple(py_rare[i], py_common[j]))
    return out


def all_pairs_unchecked(
    py_rare: PythonObject, py_common: PythonObject, py_max: PythonObject
) raises -> PythonObject:
    return pairs_fast(py_rare, py_common, py_max, cutoff=False)


def all_pairs_cutoff(
    py_rare: PythonObject, py_common: PythonObject, py_max: PythonObject
) raises -> PythonObject:
    return pairs_fast(py_rare, py_common, py_max, cutoff=True)


# --- Шаг 4. Другой алгоритм: битовый метод Майерса --------------------------


def myers(pattern_len: Int, peq: List[UInt64], text: List[UInt32]) -> Int:
    """Расстояние Левенштейна битовым методом Майерса (в варианте Хюрё).

    Столбец таблицы динамики хранится не числами, а двумя масками по 64 бита:
    в каких строках значение на 1 больше, чем строкой выше (vp), и в каких
    на 1 меньше (vn). Один символ text обрабатывается десятком битовых
    операций — сразу для всех символов образца. peq[c] — маска позиций,
    где в образце стоит символ c. Нужно pattern_len <= 64."""
    if pattern_len == 0:
        return len(text)
    var top = UInt64(1) << UInt64(pattern_len - 1)
    var vp = ~UInt64(0)
    var vn = UInt64(0)
    var dist = pattern_len
    var pp = peq.unsafe_ptr()
    var pt = text.unsafe_ptr()
    for j in range(len(text)):
        var eq = pp.unsafe_load(Int(pt.unsafe_load(j)))
        var x = eq | vn
        var d0 = (((x & vp) + vp) ^ vp) | x
        var hp = vn | ~(d0 | vp)
        var hn = vp & d0
        if hp & top:
            dist += 1
        if hn & top:
            dist -= 1
        x = (hp << 1) | 1
        vn = x & d0
        vp = (hn << 1) | ~(x | d0)
    return dist


def encode(
    obj: PythonObject, mut letters: Dict[UInt32, UInt32]
) raises -> List[UInt32]:
    """Каждой букве — свой небольшой номер, чтобы маски искать по индексу."""
    var out = List[UInt32]()
    for c in String(py=obj).codepoints():
        var code = c.to_u32()
        var idx = letters.get(code, UInt32(len(letters)))
        if Int(idx) == len(letters):
            letters[code] = idx
        out.append(idx)
    return out^


def all_pairs_myers(
    py_rare: PythonObject, py_common: PythonObject, py_max: PythonObject
) raises -> PythonObject:
    var max_dist = Int(py=py_max)
    var letters = Dict[UInt32, UInt32]()
    var rare = List[List[UInt32]]()
    for w in py_rare:
        rare.append(encode(w, letters))
    var common = List[List[UInt32]]()
    for w in py_common:
        common.append(encode(w, letters))

    var peq = List[UInt64](length=len(letters), fill=0)
    var rows = List[Int](length=2 * (longest(common) + 1), fill=0)
    var out = Python.list()
    for i in range(len(rare)):
        ref word = rare[i]
        # Маска — 64 бита, поэтому слова длиннее считаем обычной динамикой
        var bits = len(word) <= 64
        if bits:
            for k in range(len(word)):
                peq[Int(word[k])] |= UInt64(1) << UInt64(k)
        for j in range(len(common)):
            if abs(len(word) - len(common[j])) > max_dist:
                continue
            var d: Int
            if bits:
                d = myers(len(word), peq, common[j])
            else:
                d = distance_fast(word, common[j], rows, max_dist, cutoff=True)
            if d <= max_dist:
                out.append(Python.tuple(py_rare[i], py_common[j]))
        if bits:
            for k in range(len(word)):
                peq[Int(word[k])] = 0
    return out
