# ожидается: cannot call function that may raise 'Error' in context that supports an error type of 'AgeError'


@fieldwise_init
struct AgeError(Copyable, Writable):
    var reason: String

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.reason)


def check(age: Int) raises AgeError -> Int:
    if age < 0:
        raise AgeError("отрицательный")
    return age


def main():
    try:
        _ = check(1)
        _ = Int("abc")
    except e:
        print(e)
