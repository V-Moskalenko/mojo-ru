# Три внешние программы работают одновременно; ждём каждую и читаем код возврата.
from std.os import Process
from std.time import perf_counter


def main() raises:
    var t0 = perf_counter()
    var jobs = List[Process]()
    for _ in range(3):
        jobs.append(Process.run("sleep", ["0.3"]))  # запуск не ждёт конца

    # List[Process] не перебрать через for: Process нельзя копировать
    for i in range(len(jobs)):
        var status = jobs[i].wait()
        print("задача", i, "код:", status.exit_code.value())
    print("вместе, а не по очереди:", perf_counter() - t0 < 0.8)

    var failed = Process.run("sh", ["-c", "exit 3"])
    print("sh вернул:", failed.wait().exit_code.value())
