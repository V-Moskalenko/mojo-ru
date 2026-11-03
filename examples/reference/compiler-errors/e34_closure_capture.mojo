# ожидается: Could not infer capture convention of the captured value k


def main():
    var k = 2

    def times(x: Int) -> Int:
        return x * k

    print(times(3))
