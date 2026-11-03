# ожидается: cannot be implicitly copied, it does not conform to 'ImplicitlyCopyable'


def main():
    var a: List[Int] = [1]
    var b = a
    print(b)
