# ожидается: unqualified access to struct parameter 'T'; use 'Self.T' instead


struct Box[T: Copyable]:
    var item: T


def main():
    pass
