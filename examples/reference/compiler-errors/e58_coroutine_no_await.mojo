# ожидается: type 'Coroutine' does not conform to 'Deinitable' and must be explicitly destroyed
async def add(a: Int, b: Int) -> Int:
    return a + b


def main():
    var c = add(1, 2)
