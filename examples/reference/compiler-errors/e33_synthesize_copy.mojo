# ожидается: cannot synthesize implicit copy constructor because field 'items' has non-implicitly-copyable type 'List[Int]'


@fieldwise_init
struct Bag(ImplicitlyCopyable):
    var items: List[Int]


def main():
    var b = Bag([1])
    var c = b
    print(len(c.items))
