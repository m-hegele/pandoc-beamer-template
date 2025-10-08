---
title: "asyncio pitfalls"
author: "Marius Hegele"
institute: "ChargeHere GmbH"
topic: "EV Charging"
theme: "Frankfurt"
colortheme: "crane"
fonttheme: "professionalfonts"
mainfont: "Fira Code"
fontsize: 9pt
urlcolor: blue
linkstyle: bold
aspectratio: 169
titlegraphic:  # img/png_ChargeHere_Bild-Logo.png
logo: # img/png_ChargeHere_Bild-Logo.png 
date: 2025-06-18
section-titles: false
toc: true
---

<!-- markdownlint-disable MD025 -->

# asyncio pitfalls

## we want to run things concurrenctly

```python
async def failing_coro():
    print("running failing coro ...")
    raise Exception("some exception")

async def good_coro():
    print("runnning good coro ...")
    await asyncio.sleep(0.1)
    print("good coro finished")

```

## pitfall: not picking up exceptions in tasks

```python
async def main1():
    _ = asyncio.create_task(failing_coro())
    await good_coro()
    print("main1 finished")
```

swallows the exception until the whole program terminates

```txt
runnning good coro ...
running failing coro ...
good coro finished
main1 finished
Task exception was never retrieved
...
Exception: some exception
```

## propagating exceptions

::: columns

:::: column

use `asyncio.gather` or `await task`

```python
async def main2():
    await asyncio.gather(
      failing_coro(), good_coro())
    print("main2 finished")

async def main3():
    failing_task = asyncio.create_task(failing_coro())
    await good_coro()
    await failing_task
    print("main3 finished")
```

::::

:::: column

both propagate the exception

```txt
running failing coro ...
runnning good coro ...
Traceback (most recent call last):
...
Exception: some exception
```

::::

:::

## problem can be hidden inside a class

::: columns

:::: column

```python
class MyTask:
    def start(self) -> None:
        self._task = asyncio.create_task(
          self._main())

    async def _main(self) -> None:
        raise Exception("some exception")

    def shutdown(self) -> None:
        self._task.cancel()


async def main4():
    task = MyTask()
    task.start()
    await asyncio.sleep(0.1)
    print("main4 finished")
```

::::

:::: column

```txt
main4 finished
Task exception was never retrieved
...
Exception: some exception
```

::::

:::

## use `ocppproxy.InterruptibleTask` instead: implementation

```python
class InterruptibleTask(BlockingTask):
    ...

    async def blocking_start(self) -> None:
        log.info(f"Starting {self.name} task...")
        self._task = asyncio.create_task(self._main())
        try:
            await self._task
        except asyncio.CancelledError:
            pass

    async def shutdown(self) -> None:
          self._task.cancel()

    async def _main(self) -> None: ...

```

## use `ocppproxy.InterruptibleTask` instead: usage

```python
class InternalLoadOptimizer:

    async def blocking_start(self) -> None:
        self._load_optimizer_loop = InterruptibleTask(
            coroutine=self.load_optimizer_loop(GET_DATA_FREQUENCY_IN_SEC),
            name="InternalLoadOptimizerLoop",
        )
        ...
        await self._load_optimizer_loop.blocking_start()

    async def shutdown(self) -> None:
        if self._load_optimizer_loop is not None:
            await self._load_optimizer_loop.shutdown()

```

## or implement `BlockingTask` interface

```python

class ModbusTCPServer(BlockingTask):
    async def blocking_start(self):
        self._server = ModbusTcpServer(
            context=self.context,
            identity=self.identity,
            address=(str(self._config.host), self._config.port),
        )
        await self._server.serve_forever()
```

## `TaskSetManager` managing coroutines dynamically

use cases: capacity group tasks, multiple backend clients

```python

class TaskSetManager(BlockingTask):
    async def blocking_start(self, **kwargs) -> None: ...
    async def shutdown(self) -> None: ...
    async def update_coroutines_deferring_start(
      self, tasks: Sequence[BlockingTask]) -> None: ...

class LoadControl:
    capacity_groups: CapacityGroupSet
    capacity_group_task_set: TaskSetManager

    async def update_config(self, config: LoadControlConfig) -> None:
      ...
      await self.capacity_group_task_set.update_coroutines_deferring_start(
          tasks=list(self.capacity_groups.values())
      )

- 
```

## `wait_until_first_completed` - spot the error

```python
async def wait_until_first_completed(coroutines: Sequence[asyncio.Task]) -> None:
    _, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    for task in pending:
        task.cancel()

async def main5():
    await wait_until_first_completed([failing_coro(), good_coro()])
    print("main5 finished")
```

```txt
running failing coro ...
runnning good coro ...
Task exception was never retrieved
...
Exception: some exception
main5 finished

```

## `wait_until_first_completed` - pick up exceptions

```python

async def wait_until_first_completed(coroutines: Sequence[asyncio.Task]) -> None:
    done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)

    for future in pending:
        future.cancel()
        try: 
          await future # pick up ignored exception
        except (asyncio.CancelledError, concurrent.futures.CancelledError): 
          pass

    for future in done: 
        await future # pick up exception and propagate
```


# asyncio ruff rules

# internal asyncio task library

# General information

## Themes, fonts, etc

- I use default **pandoc** themes.
- This presentation is made with **Frankfurt** theme and **beaver** color theme.
- I like **professionalfonts** font scheme.

## Links

- Matrix of beamer themes: [https://hartwork.org/beamer-theme-matrix/](https://hartwork.org/beamer-theme-matrix/)
- Font themes: [http://www.deic.uab.es/~iblanes/beamer_gallery/index_by_font.html](http://www.deic.uab.es/~iblanes/beamer_gallery/index_by_font.html)
- Nerd Fonts: [https://nerdfonts.com](https://nerdfonts.com)

# Formatting

## Text formatting

Normal text.
*Italic text* and **bold text**.
~~Strike out~~ is supported.

## Notes

> This is a note.
> > Nested notes are not supported.
> And it continues.

## Blocks

### This is a block A

- Line A
- Line B

###

New block without header.

### This is a block B

- Line C
- Line D

## Listings

Listings out of the block.

```sh
#!/bin/bash
echo "Hello world!"
echo "line"
```

### Listings in the block

```sh
#!/bin/bash
echo "Hello world!"
echo "line"
```

## Table

**Item** | **Description** | **Q-ty**
:--------|-----------------:|:---:
Item A | Item A description | 2
Item B | Item B description | 5
Item C | N/A | 100

## Single picture

This is how we insert picture. Caption is produced automatically from the alt text.

```
![Aleph 0](img/aleph0.png) 
```

![Aleph 0](img/aleph0.png)

## Two or more pictures in a raw

Here are two pictures in the raw. We can also change two pictures size (height or width).

###

```
![](img/aleph0.png){height=10%}\ ![](img/aleph0.png){height=30%} 
```

![](img/aleph0.png){ height=10% }\ ![](img/aleph0.png){ height=30% }

## Lists

1. Idea 1
2. Idea 2

- genius idea A
- more genius 2

3. Conclusion

## Two columns of equal width

::: columns

:::: column

Left column text.

Another text line.

::::

:::: column

- Item 1.
- Item 2.
- Item 3.

::::

:::

## Two columns of with 40:60 split

::: columns

:::: {.column width=40%}

Left column text.

Another text line.

::::

:::: {.column width=60%}

- Item 1.
- Item 2.
- Item 3.

::::

:::

## Three columns with equal split

::: columns

:::: column

Left column text.

Another text line.

::::

:::: column

Middle column list:

1. Item 1.
2. Item 2.

::::

:::: column

Right column list:

- Item 1.
- Item 2.

::::

:::

## Three columns with 30:40:30 split

::: columns

:::: {.column width=30%}

Left column text.

Another text line.

::::

:::: {.column width=40%}

Middle column list:

1. Item 1.
2. Item 2.

::::

:::: {.column width=30%}

Right column list:

- Item 1.
- Item 2.

::::

:::

## Two columns: image and text

::: columns

:::: column

![](img/aleph0.png){height=50%}

::::

:::: column

Text in the right column.  

List from the right column:

- Item 1.
- Item 2.
::::

:::

## Two columns: image and table

::: columns

:::: column

![](img/aleph0.png){height=50%}

::::

:::: column

| **Item** | **Option** |
|:---------|:----------:|
| Item 1   | Option 1   |
| Item 2   | Option 2   |

::::

:::

## Fancy layout

### Proposal

- Point A
- Point B

::: columns

:::: column

### Pros

- Good
- Better
- Best

::::

:::: column

### Cons

- Bad
- Worse
- Worst

::::

:::

### Conclusion

- Let's go for it!
- No way we go for it!
