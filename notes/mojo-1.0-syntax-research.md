# Синтаксис Mojo 1.0 — фактура для учебника

Источники: официальный мануал https://mojolang.org/docs/manual/ и подстраницы, https://mojolang.org/docs/changelog (страница `changelog` как таковая отдаёт 404 — актуальные release notes лежат под `/releases/vX.Y.Z`), https://mojolang.org/releases.

Версии, зафиксированные на странице релизов на момент проверки (18.08.2026):

| Версия | Дата | Заметки |
|---|---|---|
| **v1.0.0 (stable)** | 11 авг 2026 | текущий релиз, на него ориентирован учебник |
| v1.0.0b2 | 18 июн 2026 | бета, `fn` уже даёт ошибку компиляции |
| v1.0.0b1 | 7 мая 2026 | бета, `fn` даёт warning |
| v0.26.2 | 19 мар 2026 | здесь `def` стал стандартным ключевым словом, убран `owned` |
| v0.26.1 | 29 янв 2026 | |
| v0.25.7 / v0.25.6 | осень 2025 | ещё «классический» Mojo (`fn`, `let` уже не было, но `borrowed`/`inout` ещё существовали в более ранних версиях) |

Прямую страницу `/releases/v1.0.0` со сводным changelog зафетчить не удалось (404 при прямом обращении, хотя `/releases` на неё ссылается) — см. раздел «Неподтверждённые моменты». Ниже данные опираются на актуальные страницы `/docs/manual/*`, `/docs/tools/*` и на changelog-и v1.0.0b1/b2/v0.26.2, которые открылись напрямую.

---

## 1. `/docs/manual/basics` — структура программы, точка входа

Источник: https://mojolang.org/docs/manual/basics

В Mojo 1.0 **точка входа объявляется только через `def main()`**. Отдельного `fn main()` в примерах манула нет — страница вообще не упоминает `fn` как альтернативу.

```mojo
def main():
    print("Hello, world!")
```

Ключевые тезисы страницы:
- «Every Mojo program must include a function named `main()` as the entry point» — это обязательно, top-level script-режима (как в чистом Python) нет.
- Функции по умолчанию объявляются `def`.
- Примечание в мануале: «This page omits `def main():` for many brief examples. To test these, add them to a `main()` function.» — то есть в учебнике сниппеты без `main()` нормальны, но рабочий файл должен его содержать.

---

## 2. `/docs/manual/functions` — `def` vs `fn`, сигнатуры, аргументы

Источник: https://mojolang.org/docs/manual/functions

### `def` vs `fn` — главное изменение

**`fn` в Mojo 1.0 не используется вообще.** Хронология по changelog-ам:
- v0.26.2 (19.03.2026): `def` становится стандартным ключевым словом; `def`-функции больше не «raising по умолчанию» — теперь у `def` и `fn` одна и та же семантика (non-raising by default, `raises` нужно объявлять явно). Это и есть то самое «сближение» `def`/`fn`, о котором просили уточнить, — но оно кончилось не слиянием, а **устранением `fn`**.
- v1.0.0b1 (07.05.2026): `fn` deprecated, компилятор выдаёт warning.
- v1.0.0b2 (18.06.2026): использование `fn` — **ошибка компиляции**.
- Страница `/docs/manual/functions` в 1.0 прямым текстом: «Use `def` for all function declarations. The `fn` keyword will be removed in a future release» (то есть формально `fn` как ключевое слово ещё зарезервировано/распознаётся компилятором, но использовать его нельзя — это ошибка).

**Практический вывод для учебника: везде писать `def`, ни одного примера с `fn` в коде для Mojo 1.0 быть не должно.**

### Сигнатура функции

```
def function_name[parameters](arguments) -> return_type:
    function_body
```

Всё, кроме тела — опционально. Типы аргументов обязательны для каждого параметра/аргумента (Mojo — не Python, аннотации типов не опциональны для `def` в этом смысле).

### Значения по умолчанию

```mojo
def my_pow(base: Int, exp: Int = 2) -> Int:
    ...
```
Обязательные аргументы идут перед аргументами со значением по умолчанию. Важное ограничение: **аргументы с конвенцией `mut` не могут иметь значение по умолчанию.**

### Перегрузка (overloading)

Порядок разрешения перегруженных вызовов компилятором:
1. меньше неявных преобразований типов;
2. невариативные аргументы предпочтительнее вариативных;
3. невариативные параметры предпочтительнее вариативных;
4. более короткая сигнатура параметров;
5. методы экземпляра предпочтительнее статических методов.

### Ключевые слова конвенций аргументов, актуальные в 1.0

Подробности — в разделе 6 (ownership), но кратко по `/docs/manual/functions`: упоминаются `mut` (мутируемый аргумент) и `out` (именованный результат/неинициализированный аргумент, только в конструкторах и `-> out`-возвратах), а также `ref`-биндинги.

**Важно: `read` НЕ существует как отдельное ключевое слово в 1.0.** Я отдельно проверил текст страницы `/docs/manual/values/ownership` на вхождение слова `read` как ключевого слова — не найдено. Слово «read» встречалось в одном из промежуточных фетчей страницы `/docs/manual/functions` в контексте общего описания («read convention context»), но это не воспроизвелось при точечной проверке на странице ownership и нигде в примерах кода `read` как ключевое слово не используется. Дефолтная (безымянная) конвенция — это просто отсутствие ключевого слова перед именем аргумента.

---

## 3. `/docs/manual/variables` — объявление переменных

Источник: https://mojolang.org/docs/manual/variables

**`let` в языке нет.** Страница вообще не упоминает `let` — есть только `var` (явное объявление) и «неявное» объявление без `var`.

```mojo
# Явное объявление
var name = "Sam"
var user_id: Int
var name: String = "Sam"

# Неявное объявление (по первому присваиванию)
name = "Sam"
user_id = 0
```

- Все переменные в Mojo 1.0 **мутируемы** — прямая цитата: «All variables in Mojo are mutable—their value can be changed.» То есть неизменяемости на уровне переменных (как раньше давал `let`) больше нет вовсе — это не просто переименование `let`→`var`, а исчезновение immutable-биндингов как концепции для локальных переменных.
- Константы времени компиляции — через `comptime`, это отдельный механизм, не связанный с мутируемостью обычных переменных.
- Область видимости:
  - явные (`var`) переменные — блочная область видимости (block-scope), с шедоуингом во вложенных блоках, время жизни ограничено блоком;
  - неявные переменные (без `var`) — область видимости на уровне функции (как в Python: присваивание внутри `if` влияет на всю функцию).
  - «Nested code can read and modify variables defined in an outer scope. An outer scope can't read variables defined in an inner scope.»

---

## 4. `/docs/manual/types` — базовые типы, Prelude vs импорт

Источник: https://mojolang.org/docs/manual/types

**Всегда доступны без импорта (built-in / Prelude):**
- `Int`
- `Float64`
- `Bool`
- `String`
- `SIMD`
- `Tuple`

**Требуют явного импорта (коллекции стандартной библиотеки):**
```mojo
from std.collections.list import List
from std.collections.dict import Dict
from std.collections.set import Set
from std.collections.optional import Optional
```

Важный нюанс для учебника: путь импорта — `std.collections.*` (не `collections.*`, как было в более ранних версиях доязыка/доков; проверить точное имя пакета в 1.0 — см. «Неподтверждённые моменты», так как это цитата из summarизированного фетча, не дословный код-блок).

Мануал подчёркивает, что стандартные типы не привилегированы: «These standard types aren't privileged. Each of the standard library types is defined just like user-defined types—even basic types like Int and String.»

---

## 5. `/docs/manual/structs` — структуры, конструктор, декораторы, трейты

Источник: https://mojolang.org/docs/manual/structs

### Базовый синтаксис

```mojo
struct MyPair:
    var first: Int
    var second: Int
```

### Конструктор — `def __init__(out self)`

Конструктор объявляется через `def` (не `fn`!), первый параметр — `out self`:

```mojo
struct MyPair:
    var first: Int
    var second: Int

    def __init__(out self, first: Int, second: Int):
        self.first = first
        self.second = second
```

`out` означает, что `self` на входе не инициализирован и должен быть полностью инициализирован до `return`. `self` никогда не передаётся вызывающим кодом явно — Mojo подставляет его автоматически.

### `@value` — устарел, заменён на `@fieldwise_init`

**`@value` в примерах манула 1.0 не встречается вообще.** Актуальный декоратор — `@fieldwise_init`:

```mojo
@fieldwise_init
struct MyPair:
    var first: Int
    var second: Int
```

Это подтверждает вопрос задания — `@value` нужно считать устаревшим для 1.0, писать `@fieldwise_init`.

### Трейты `Copyable` / `Movable` / `ImplicitlyCopyable`

По умолчанию структуры **не копируемы и не перемещаемы**. Чтобы структура стала копируемой:

```mojo
struct MyPair(Copyable):
    ...
```
— автоматически генерируется конструктор копирования, и структура также становится Movable.

Для move-only типа:
```mojo
struct MyPair(Movable):
    ...
```

Для неявного копирования (используется осторожно) — трейт `ImplicitlyCopyable`, который включает в себя одновременно `Copyable` и `Movable`.

### Методы и мутабельность

Методы экземпляра по умолчанию получают **неизменяемый** `self`. Чтобы модифицировать поля — нужен `mut self`:

```mojo
struct MyStruct:
    var value: Int

    def increment(mut self):
        self.value += 1
```

Статические методы — через `@staticmethod`:
```mojo
@staticmethod
def log_info(message: String):
    print("Info: ", message)
```

---

## 6. `/docs/manual/values/ownership` — конвенции передачи аргументов

Источник: https://mojolang.org/docs/manual/values/ownership

Актуальный на 1.0 набор ключевых слов конвенций аргументов:

| Ключевое слово | Смысл | Пример |
|---|---|---|
| *(без ключевого слова, дефолт)* | неизменяемая ссылка только для чтения («immutable read-only reference») — самый дешёвый способ передать большое значение | `def print_list(list: List[Int]):` |
| `mut` | мутируемая ссылка: функция может читать и изменять оригинал, изменения видны вызывающему коду. Действует «argument exclusivity» — мутируемая ссылка не может сосуществовать с другими ссылками на то же значение | `def add(mut x: Int, y: Int): x += y` |
| `var` | передача владения (transfer ownership) значением функции; получатель — единственный мутируемый владелец и отвечает за уничтожение значения; происходит либо прямой transfer через сигил `^`, либо копированием, либо через новое значение | `def take(var s: String): pass` / `def add_to_list(var name: String, mut list: List[String]): list.append(name^)` |
| `ref` | параметрическая мутабельность — «следует» мутабельности переданного значения; продвинутая тема, подробнее раскрыта в отдельном разделе про lifetimes/references | — |
| `out` | используется только в конструкторах и именованных результатах: аргумент не инициализирован на входе, должен быть инициализирован на выходе | `def __init__(out self, ...):` |
| `deinit` | используется в деструкторах и consuming-move методах: инициализирован на входе, не инициализирован на выходе | — |

Ключевой инвариант владения: «every value has only one owner at a time», деструкторы вызываются сразу по завершении владения (ASAP-семантика, как раньше).

### Таблица «устарело → актуально в Mojo 1.0»

| Устарело (беты/0.2x и раньше) | Актуально в 1.0 | Комментарий |
|---|---|---|
| `let x = ...` | `var x = ...` или просто `x = ...` (неявное объявление) | `let` вообще не существует, отдельного immutable-биндинга для переменных больше нет |
| `fn main()` / `fn foo(...)` | `def main()` / `def foo(...)` | `fn` в 1.0 — ошибка компиляции (warning был ещё в 1.0.0b1, ошибкой стал в 1.0.0b2) |
| `inout x: T` | `mut x: T` | переименовано ещё до 1.0 (в бетах), в манускрипте 1.0 `inout` не встречается вообще |
| `borrowed x: T` (или дефолт в очень старых версиях) | *(без ключевого слова)* — неизменяемая ссылка по умолчанию | слово `borrowed` не встречается в документации 1.0 |
| `owned x: T` | `var x: T` | `owned` формально удалён в v0.26.2, заменён на `var` в конвенциях аргументов |
| `@value` | `@fieldwise_init` | `@value` не встречается ни в одном примере кода мануала 1.0 |
| `@register_passable`, `@register_passable("trivial")` | трейт `RegisterPassable` / соответствие трейтам | декоратор удалён в v1.0.0b1, заменён на trait conformance |
| `Stringable`, `Representable` (отдельные трейты) | унифицированный `Writable` | изменено в v0.26.2 |
| `__moveinit__()`, `__copyinit__()` | `__init__()` с keyword-only `take`/`copy` | переименовано в v0.26.2; старые имена временно поддерживались, но по состоянию на v1.0.0b1 «legacy `__moveinit__()` / `__copyinit__()` method names no longer auto-rewritten» — то есть **больше не работают автоматически** |
| Отрицательная индексация `x[-1]` | `x[len(x) - 1]` | полностью удалена в v1.0.0b1 для List/Span и др. |
| `constrained[cond, msg]()` | `comptime assert ...` | удалено в v1.0.0b2 |
| `@parameter if` / `@parameter for` | `comptime if` / `comptime for` | изменено в v0.26.2 |
| `mojo package` | `mojo precompile`, `.mojopkg` → `.mojoc` | переименовано в v1.0.0b2 |
| `@doc_private` | `@doc_hidden` | удалено/переименовано в v1.0.0b1 |

---

## 7. `/docs/changelog` и release notes — что изменилось к 1.0 (лямбды, Pointer, closures, `where`)

Прямая страница `/docs/changelog` вернула 404, актуальный changelog находится под `/releases/vX.Y.Z`. Ниже — сведения из v1.0.0b1, v1.0.0b2 и v0.26.2 (страница `/releases/v1.0.0` со сводным changelog самого релиза 1.0.0 зафетчить не удалось — 404, хотя `/releases` на неё ссылается текстом «See the Mojo 1.0.0 changelog»; вероятно, финальный релиз просто консолидирует изменения из b1/b2).

### Лямбды и замыкания (closures) — редизайн синтаксиса захвата

Источники: `/docs/manual/functions/closures`, `/docs/manual/functions/lambda`.

Мануал прямо отмечает: «Mojo's updated capture-list syntax is now available. Code examples on this page reflect the redesigned compiler behavior» — то есть синтаксис захвата (`capture list`) в 1.0 переработан относительно бет.

**Closures — список захвата в фигурных скобках после списка аргументов:**

```mojo
def function_name(args) {capture_list} -> ReturnType:
    # тело
```

Конвенции захвата:
- `imm` — неизменяемая ссылка (дефолт для «голого» имени в списке захвата): `{imm x}` или просто `{x}`
- `mut` — мутируемая ссылка, изменения видны во внешней области: `{mut histogram}`
- `var` — копия значения на момент создания замыкания (снапшот): `{var x}`
- `var name^` — перемещение (move) владения во внутрь замыкания, внешняя переменная становится неинициализированной
- `ref name` — мутабельность определяется контекстом вызывающего (часто пробрасывается из `ref`-параметра функции): `{ref name}`
- `{}` — пустой список захвата, замыкание не использует ничего из внешней области (по сути обычная вложенная функция)
- `{var^}` — «copyable closures»: перемещает все использованные внешние значения внутрь; если захваченные типы `Copyable`, само замыкание становится копируемым/присваиваемым

Голые имена в списке захвата по умолчанию трактуются как `imm`, если не указано иное. Каждый элемент списка захвата задаёт свою конвенцию независимо (конвенции не наследуются между элементами).

**Лямбды — отдельная сущность:**

```mojo
lambda (x: Int) -> Int: x + 1
```
- тело — одно выражение, вычисляется и возвращается;
- аннотации типов аргументов и возврата обязательны... кроме того, что возвращаемый тип опционален и по умолчанию равен `None` (для side-effect-лямбд):
```mojo
var collector = lambda (n: Int) {mut histogram}: increment(histogram, n)
```
- «Thin lambdas» — не захватывают состояние, не несут compile-time параметров, работают как указатели на функции и могут передаваться как compile-time параметры (обычные closures — не могут):
```mojo
lambda (x: Int) -> Int: x * 2  # thin lambda
```
- Closures-лямбды захватывают внешние значения:
```mojo
var factor = 3
lambda (x: Int) -> Int: x ** factor  # closure, захватывает factor
```
- Если конвенция захвата не указана явно — по умолчанию `imm` (immutable reference).

Из v1.0.0b1: «Unified Closures — stateless closures auto-lift to top-level functions and support `ref` capture conventions. New `thin` function effect declares plain function pointers without captured state.» Это подтверждает, что унификация closures/lambda и понятие `thin`-функций — фича именно 1.0-ветки, а не старых бет.

### Pointer — НЕ единый тип, а три отдельных

Вопреки формулировке задания «единый тип Pointer», в документации 1.0 (`/docs/manual/pointers`) описаны **три разных типа указателей**, не один унифицированный:

1. **`Pointer`** — «Mojo's primary pointer type. It points to one or more contiguous memory locations, and can refer to uninitialized memory.»
2. **`OwnedPointer`** — smart pointer с эксклюзивным владением одним значением:
```mojo
from std.memory import OwnedPointer
var ptr: OwnedPointer[Int]
ptr = OwnedPointer(100)
```
3. **`ArcPointer`** — reference-counted smart pointer с потенциально разделяемым владением.

Все параметризуются (`OwnedPointer[Int]`), разыменование — через `ptr[]`. Явного упоминания `UnsafePointer` или origin-параметризованных указателей на странице `/docs/manual/pointers` не встретилось (страница показалась усечённой при фетче — см. «Неподтверждённые моменты»), однако `UnsafePointer` фигурирует в release notes v1.0.0b1: «`UnsafePointer` is now non-null by design. The default null constructor and `__bool__()` method are deprecated. To express nullability, use `Optional[UnsafePointer[...]]`» — то есть `UnsafePointer` в 1.0 существует, но его семантика nullability изменилась (раньше указатель мог быть null напрямую, теперь для этого нужен `Optional[UnsafePointer[...]]`).

**Вывод: тезис «единый тип Pointer» из задания не подтверждается документацией — актуальнее говорить о трёх типах (`Pointer`, `OwnedPointer`, `ArcPointer`) плюс отдельно `UnsafePointer` с изменённой семантикой nullability.**

### `where`-клаузы

Источник: `/docs/manual/generics`, а также v1.0.0b2 changelog.

В 1.0 `where` используется для **условного соответствия трейтам** и **условной доступности методов**:

```mojo
struct Wrapper[T: BaseTraits](
    Writable where conforms_to(T, Writable)
):
    var value: Self.T
```

```mojo
def __bool__(self) -> Bool where conforms_to(Self.T, Boolable):
    return trait_downcast[Boolable](self.value).__bool__()
```

Несколько условий объединяются через `and`:
```mojo
struct Pair[L: BaseTraits, R: BaseTraits](
    Hashable where conforms_to(L, Hashable) and conforms_to(R, Hashable)
):
    var left: Self.L
    var right: Self.R
```

`where` работает и с числовыми параметрами-значениями:
```mojo
struct SizedListWrapper[capacity: Int, T: Copyable](
    Sized, Writable where conforms_to(T, Writable) and capacity > 0
):
    ...

def first(self) -> Self.T where Self.capacity > 0:
    return self.data[0].copy()
```

**Важный нюанс по эволюции синтаксиса `where` между бетами и релизом**, из v1.0.0b2: «`where` clauses in parameter lists are deprecated in favor of trailing `where` on declarations» — и там же «Trailing Where Clauses: Now supported on struct declarations, comptime alias declarations, and to discharge constraints from constrained types in signatures.» Т.е. в более ранних бетах `where` мог стоять внутри списка параметров `[...]`, в 1.0 актуален именно **trailing-синтаксис** (после списка трейтов/сигнатуры), как в примерах выше — писать `where` внутри `[T: Trait where ...]` в учебнике не стоит, это устаревшая форма.

Также из v1.0.0b1: «The compiler now narrows types from `where` clauses and `comptime` statements using `conforms_to()` expressions, eliminating many `trait_downcast()` calls.» — то есть `conforms_to()` — актуальная функция для условий в `where`, а ручной `trait_downcast()` в большинстве случаев больше не нужен (хотя в примере выше он всё ещё встречается для конкретного случая `Boolable`).

### Прочие изменения к 1.0, важные для учебника (из release notes)

- **`fn` полностью убран** (см. таблицу выше).
- **`@parameter if/for` → `comptime if/for`** (v0.26.2).
- **T-strings** — новый префикс `t"..."` для структурированных строковых шаблонов (v0.26.2).
- **Reflection API переработан дважды**: сначала унифицирован в `reflect[T]()` (v1.0.0b1, заменил семейство `struct_field_*`), затем `reflect[T]` стал **comptime alias, а не вызовом функции** — «Usage changed from `reflect[Point]()` to `reflect[Point]`» (v1.0.0b2). Для учебника это значит: в актуальном 1.0 писать `reflect[Point]` без скобок.
- **Bounds checking** для CPU-коллекций включён по умолчанию (GPU — нет, по умолчанию выключен) — v1.0.0b1.
- **`NDBuffer` удалён**, миграция на `TileTensor` — v1.0.0b1.
- **Grapheme cluster support** в строках (UAX #29) — v1.0.0b1; в v1.0.0b2 добавлены `String[codepoint=1:2]` и `String[grapheme=1]` для индексации по кодпоинтам/графемам, плюс `bytes()`-итератор по UTF-8 байтам.
- **Коллекции больше не требуют `Copyable`** как нижней границы — теперь достаточно `Movable & ImplicitlyDestructible` (v1.0.0b2), то есть move-only типы можно хранить в стандартных коллекциях.

---

## 8. Запуск кода — `mojo file.mojo`, `mojo build`, REPL

Источники: `/docs/manual/get-started`, `/docs/manual/quickstart`, `/docs/tools/compilation`, `/docs/tools/testing`.

### Установка

Мануал 1.0 в разных местах рекомендует разные пакетные менеджеры (несогласованность между страницами, возможно из-за разных версий контента — отметил в «Неподтверждённые моменты»):
- `get-started`: через `pixi`
```sh
curl -fsSL https://pixi.sh/install.sh | sh
pixi init life -c https://conda.modular.com/max/ -c conda-forge && cd life
pixi add mojo
```
- `quickstart`: через `uv`
```sh
uv pip install mojo
# или
uv init temperature-analyzer
cd temperature-analyzer
uv add mojo
```

### Запуск (JIT) — БЕЗ подкоманды `run` для обычного запуска файла

Ключевое наблюдение, отличающее 1.0 от того, что писали раньше про `mojo run file.mojo`:

```sh
mojo life.mojo
```
— это JIT-компиляция и немедленный запуск («on-the-fly compilation and then runs the result»). Явной подкоманды `run` в базовом hello-world примере из `get-started` **нет** — команда просто `mojo <файл>.mojo`.

При этом подкоманда **`mojo run` тоже существует** и явно используется, например, в документации по тестированию (`/docs/tools/testing`):
```sh
mojo run test_quickstart.mojo
mojo run -I src test/my_math/test_inc.mojo --skip test_inc_max
```
с флагами `--skip <names>`, `--only <names>`, `--skip-all`.

**Вывод для учебника: `mojo file.mojo` и `mojo run file.mojo` в 1.0 — оба рабочих варианта** (похоже, `run` — необязательная явная подкоманда, а голый `mojo file.mojo` — сокращённая форма/дефолтное поведение CLI). Для базовых примеров разумно показывать короткую форму `mojo file.mojo`, но не будет ошибкой использовать и `mojo run file.mojo`.

### Сборка исполняемого файла

```sh
mojo build life.mojo
./life
```
Создаёт автономный исполняемый файл (по умолчанию с именем как у входного файла без расширения) в текущей директории.

Также `mojo build` поддерживает флаги кросс-компиляции и интроспекции таргетов:
```sh
mojo build --print-effective-target
mojo build --print-supported-targets
mojo build --print-supported-cpus --target-triple=aarch64-apple-macosx
mojo build --print-supported-accelerators
```
Кросс-компиляция в 1.0 ещё не завершена: «Cross-compilation support is still in development. You can query targets, cross-compile to object files and assembly, and target GPU architectures.» Полное связывание (linking) в исполняемый файл под чужую платформу требует внешних инструментов.

### REPL

**Явного упоминания интерактивного REPL нигде на проверенных страницах 1.0 не найдено.** Ни `/docs/manual/get-started`, ни `/docs/tools/testing`, ни `/docs/tools/compilation` не описывают команду вроде `mojo repl` или `mojo` без аргументов как интерактивный режим. Прямая цитата из фетча get-started: «The documentation does not mention an interactive REPL for Mojo 1.0. The tutorial focuses exclusively on file-based development workflows using either JIT execution or compiled binaries.»

**Для учебника: не утверждать, что REPL точно убран (это не было явно написано как «REPL removed»), но и не описывать его как рабочую фичу без дополнительной проверки** — см. «Неподтверждённые моменты». Также см. `mojo precompile` (бывший `mojo package`, из v1.0.0b2) как ещё одну CLI-подкоманду, актуальную для сборки пакетов (`.mojoc` вместо `.mojopkg`).

### Прочие относящиеся к CLI команды из release notes

- `mojo --print-cache-location`, `mojo --clear-cache` — управление кэшем компиляции (v1.0.0b2).
- `mojo precompile` (было `mojo package`) — упаковка в `.mojoc` (было `.mojopkg`) (v1.0.0b2).
- Флаг `-kgenModule` у `mojo precompile` удалён (v1.0.0b1).

---

## Итоговая сводная таблица «устарело → актуально в Mojo 1.0»

| Категория | Устарело (до/во время бет 1.0, или в версиях 2023–2025) | Актуально в Mojo 1.0 |
|---|---|---|
| Объявление функций | `fn foo(...):` | `def foo(...):` — `fn` удалён, использование — ошибка компиляции |
| Точка входа | `fn main():` | `def main():` |
| Неизменяемая переменная | `let x = ...` | Нет прямого аналога: `var x = ...` (переменные всегда мутируемы); константы времени компиляции — `comptime` |
| Мутируемый аргумент | `inout x: T` | `mut x: T` |
| Передача владения (аргумент) | `owned x: T` | `var x: T` |
| Аргумент только для чтения | `borrowed x: T` (в очень старых версиях, явно) | без ключевого слова — дефолтная неизменяемая ссылка |
| Поле-конструктор одной строкой | `@value struct S: ...` | `@fieldwise_init struct S: ...` |
| Register-passable типы | `@register_passable`, `@register_passable("trivial")` | трейт `RegisterPassable` |
| Стрингификация/репрезентация | отдельные трейты `Stringable`, `Representable` | унифицированный трейт `Writable` |
| Move/copy конструкторы | `__moveinit__()`, `__copyinit__()` | `__init__()` с keyword-only `take` / `copy` |
| Compile-time ветвление/циклы | `@parameter if`, `@parameter for` | `comptime if`, `comptime for` |
| Compile-time проверка условий | `constrained[cond, msg]()` | `comptime assert ...` |
| Отрицательная индексация | `x[-1]` | `x[len(x) - 1]` |
| Reflection | `struct_field_*()`, `get_type_name()`, `ReflectedType[T]` | `reflect[T]` (comptime alias, без скобок) → `Reflected[T]` |
| `where` в списке параметров | `[T: Trait where ...]` внутри `[...]` | trailing `where` после сигнатуры/списка трейтов: `struct S[T](Trait where conforms_to(...)):` |
| Упаковка пакета | `mojo package`, `.mojopkg` | `mojo precompile`, `.mojoc` |
| Приватность в доках | `@doc_private` | `@doc_hidden` |
| Nullable unsafe-указатель | `UnsafePointer` мог быть напрямую null | `UnsafePointer` non-null по умолчанию; для nullable — `Optional[UnsafePointer[...]]` |

---

## Неподтверждённые моменты

1. **Страница `/docs/changelog` возвращает 404** — не удалось получить единый сводный changelog по этому URL, как просили в задании. Вместо неё пришлось собирать данные постранично из `/releases/v1.0.0b1`, `/releases/v1.0.0b2`, `/releases/v0.26.2`. Страница `/releases/v1.0.0` (итоговый changelog самого релиза 1.0.0) тоже вернула 404 при прямом обращении, хотя `/releases` ссылается на неё текстом «See the Mojo 1.0.0 changelog» — возможно, проблема временная (кэш/защита от ботов) или URL отличается от ожидаемого паттерна `/releases/vX.Y.Z`. **Рекомендуется перепроверить вручную в браузере перед публикацией учебника**, особенно на предмет того, не переехали ли в самом финальном 1.0.0 какие-то фичи иначе, чем в b1/b2.

2. **Ключевое слово `read`** — в задании явно просили проверить, актуально ли `read` в 1.0. Прямая целевая проверка страницы ownership на вхождение слова «read» как ключевого слова дала отрицательный результат — `read` не задокументирован как конвенция аргументов в 1.0. Но при одном из промежуточных обращений к странице `/docs/manual/functions` инструмент-суммаризатор один раз упомянул фразу «read convention context» без явного кода. Возможно, это артефакт суммаризации (WebFetch пропускает контент через LLM), а не факт из документации. **Итоговая рекомендация — НЕ использовать `read` как ключевое слово в примерах учебника**, дефолтная конвенция передаётся без всякого ключевого слова.

3. **Единый тип `Pointer`** — задание предполагало, что в 1.0 ввели «единый тип Pointer». По факту документация описывает **три разных типа** (`Pointer`, `OwnedPointer`, `ArcPointer`), плюс отдельно упоминается `UnsafePointer` с изменившейся nullability-семантикой в release notes. Страница `/docs/manual/pointers` при фетче показалась усечённой («page content appears truncated at the comparison table») — не исключено, что там дальше есть таблица сравнения и дополнительный контекст про «унификацию», который я не увидел. **Стоит перепроверить страницу `/docs/manual/pointers` и `/docs/manual/pointers/using-pointers` вручную целиком**, прежде чем писать раздел учебника про указатели.

4. **Путь импорта коллекций** — `from std.collections.list import List` и т.п. взяты из суммаризированного (не дословного) фетча страницы `/docs/manual/types`. Стоит перепроверить точный путь модуля дословно (возможно, `std.collections.list` vs просто `collections.list` без `std.` префикса — в release notes v1.0.0b2 сказано «Implicit `std` imports are now errors; all standard library imports must be fully qualified», что подтверждает необходимость префикса `std.`, но точное написание лучше свериться напрямую по код-блоку со страницы, а не по пересказу).

5. **Пакетный менеджер для установки** — на странице `get-started` фигурирует `pixi`, на странице `quickstart` — `uv`. Это может означать, что страницы описывают разные сценарии (например, `quickstart` — для датасаентистов через `uv`, `get-started` — общий гайд через `pixi`), либо документация просто не до конца консистентна между разделами. Для учебника стоит явно выбрать один способ установки и проверить его вручную перед публикацией.

6. **REPL** — на проверенных страницах явного упоминания «REPL был удалён» или «REPL доступен» не найдено вообще (ни в положительном, ни в отрицательном ключе как явная формулировка в самой документации — только вывод суммаризатора об отсутствии упоминаний). Не проверялись страницы `/docs/manual/quickstart` и `/docs/tools/*` целиком построчно на предмет команды `mojo repl` или `mojo` без аргументов. **Перед тем как в учебнике категорично написать «REPL в 1.0 отсутствует», стоит явно попробовать выполнить `mojo` без аргументов в реальном окружении 1.0 или найти соответствующий пункт в CLI-референсе (`/docs/reference`), который не был проверен в этом ресёрче.**

7. **`/docs/reference`** (полный CLI/язык референс) и **`/docs/roadmap`** не были изучены в этом заходе — там могут быть более точные и исчерпывающие формулировки по многим из вышеперечисленных пунктов (особенно по CLI-командам и точному списку зарезервированных слов).

8. Все фактические цитаты в этом документе получены через инструмент WebFetch, который **прогоняет HTML через промежуточную суммаризирующую модель**, а не отдаёт полностью дословный markdown страницы (кроме случаев, где явно получилось получить `.md`-версию, например `/docs/manual/basics.md`). Это значит, что часть код-блоков выше — реконструкция по пересказу, а не побайтовая копия исходника. **Перед вставкой любого код-блока из этого документа в финальный текст учебника рекомендуется свериться с исходной страницей вручную**, особенно там, где это отмечено как непроверенное.
