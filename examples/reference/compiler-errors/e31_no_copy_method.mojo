# ожидается: value has no attribute 'copy'


struct Connection:
    var name: String

    def __init__(out self, name: String):
        self.name = name


def main():
    var c = Connection("db")
    var d = c.copy()
