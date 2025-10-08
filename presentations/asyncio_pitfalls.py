import asyncio


async def failing_coro():
    print("running failing coro ...")
    await asyncio.sleep(2)
    raise Exception("some exception")


async def good_coro():
    print("runnning good coro ...")
    await asyncio.sleep(3)
    print("good coro finished")


async def main1():
    _ = asyncio.create_task(failing_coro())
    await good_coro()
    print("main1 finished")


async def main2():
    await asyncio.gather(failing_coro(), good_coro())
    print("main2 finished")


async def main3():
    failing_task = asyncio.create_task(failing_coro())
    await good_coro()
    await failing_task
    print("main3 finished")


class MyTask:
    def start(self) -> None:
        self._task = asyncio.create_task(self._main())

    async def _main(self) -> None:
        raise Exception("some exception")

    def shutdown(self) -> None:
        self._task.cancel()


async def main4():
    task = MyTask()
    task.start()
    await asyncio.sleep(0.1)
    print("main4 finished")


# wait_until_first_completed


async def wait_until_first_completed(coroutines) -> None:
    tasks = [asyncio.create_task(coro) for coro in coroutines]
    done_tasks, pending_tasks = await asyncio.wait(
        tasks, return_when=asyncio.FIRST_COMPLETED
    )
    for task in pending_tasks:
        task.cancel()
    # for task in done_tasks:
    #     task.result()


async def main5():
    await wait_until_first_completed([failing_coro(), good_coro()])
    print("main5 finished")


asyncio.run(main5())
