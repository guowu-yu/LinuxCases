---
slug: ubuntu-pytest-roadmap
title: pytest 学习路线图：2 周从入门到实战（每天可照做）
date: 2026-10-13
tags: [pytest, Python, 自动化测试, 测试, 学习路线]
summary: 一张 2 周（14 天）pytest 学习路线图，从环境搭建、断言、fixture、参数化，到 mock、覆盖率、CI 集成与实战项目，每天含目标、示例与练习。
---

> 本篇是「Ubuntu Server 技能提升路线图」中自动化测试的延伸专题，和你已经搭好的 Docker + Jenkins CI/CD 直接衔接：学完 pytest，就能把它接进流水线自动跑测试。目标——**每天 1 小时左右，14 天从零到能独立给真实项目写测试**。

## 这张路线图能带你到哪

```
Day1 环境    Day2 断言   Day3-4 fixture   Day5 参数化
   │            │            │               │
   └────────────┴────────────┴───────────────┘
                   第一周：把测试写对、写稳
Day6 标记    Day7 mock   Day8 配置   Day9 覆盖率/插件
   │            │           │            │
Day10 CI集成  Day11 数据库  Day12 最佳实践 Day13 实战 Day14 复习
                   第二周：把测试写专业、接进流水线
```

学完你能做到：给任意 Python 项目写单元/集成测试、用 fixture 管理测试数据、用参数化消灭重复、用 mock 隔离外部依赖、出覆盖率报告、并在 Jenkins/GitHub Actions 里自动跑。

---

## 学习前准备

- 本机装好 **Python 3.8+**（LinuxCases 服务器上也行：`python3 --version`）。
- 一个顺手的编辑器（VS Code 最佳，装 Python 插件）。
- 基本 Python 语法（函数、类、异常）即可，不需要框架经验。

创建专用练习目录：

```bash
mkdir -p ~/pytest-learn && cd ~/pytest-learn
python3 -m venv venv          # 建虚拟环境，避免污染系统
source venv/bin/activate      # Linux/Mac 激活；Win 用 venv\Scripts\activate
pip install -U pip pytest      # 安装 pytest
pytest --version               # 看到版本号即成功
```

---

## 总览：14 天安排

| 周 | 天 | 主题 | 你将达到 |
|----|----|------|----------|
| 1 | 1 | 环境与第一支测试 | 能装 pytest、跑通一个测试 |
| 1 | 2 | 断言与异常 | 写出有意义的断言、测异常 |
| 1 | 3 | fixture 入门 | 用 fixture 准备测试前置 |
| 1 | 4 | fixture 进阶 | 作用域/清理/自动 fixture |
| 1 | 5 | 参数化 | 一组数据跑多遍，消灭复制 |
| 2 | 6 | 标记与跳过 | 分类/跳过/预期失败 |
| 2 | 7 | Mock 与 monkeypatch | 隔离外部依赖 |
| 2 | 8 | 配置与命令行 | 用 ini/conftest 统一管理 |
| 2 | 9 | 覆盖率与插件 | 看覆盖率、并行跑、出报告 |
| 2 | 10 | 接入 CI/CD | Jenkins/GitHub Actions 自动跑 |
| 2 | 11 | 测数据库与网络 | 隔离、起服务、回滚 |
| 2 | 12 | 最佳实践 | 目录结构、FIRST 原则 |
| 2 | 13 | 实战项目 | TDD 写一个迷你项目 |
| 2 | 14 | 复习与进阶 | 踩坑、下一步方向 |

---

## 第一周

### Day 1 · 环境与第一支测试

**目标**：跑通你的第一个 pytest 测试。

pytest 约定：文件名以 `test_` 开头或 `_test` 结尾，函数以 `test_` 开头，类以 `Test` 开头且不含 `__init__`。

`test_sample.py`：

```python
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
```

运行：

```bash
pytest                      # 自动发现并运行
pytest test_sample.py -v    # -v 看每个用例名字
```

看到 `1 passed` 即成功。绿色通过，红色失败。

**练习**
1. 写 `test_sub()` 测减法并跑通。
2. 故意把 `assert add(2,3)==6` 改错，看失败长什么样（记下 traceback 格式）。

---

### Day 2 · 断言与异常

**目标**：写出能精准定位问题的断言，并测试异常。

`test_assert.py`：

```python
def test_compare():
    assert 1 + 1 == 2
    assert "hello" in "hello world"
    assert {"a": 1} == {"a": 1}

import pytest

def test_raises():
    with pytest.raises(ZeroDivisionError):
        _ = 1 / 0

def test_raises_msg():
    with pytest.raises(ValueError, match="不能为负"):
        raise ValueError("不能为负")
```

pytest 的断言重写会详细对比左右值，失败时直接告诉你哪边不对。

**练习**
1. 测一个函数 `divide(a,b)` 在 `b==0` 时抛出 `ValueError` 且信息含 "zero"。
2. 用 `pytest.approx()` 测浮点：`assert 0.1 + 0.2 == pytest.approx(0.3)`。

---

### Day 3 · fixture 入门

**目标**：用 fixture 统一准备测试前置数据，告别重复 `setup`。

`test_fixture.py`：

```python
import pytest

@pytest.fixture
def sample_user():
    return {"name": "alice", "age": 30}

def test_user_name(sample_user):
    assert sample_user["name"] == "alice"

def test_user_age(sample_user):
    assert sample_user["age"] > 18
```

fixture 像"可注入的准备函数"，测试函数把它的名字当参数就能用。

`conftest.py`（放在测试目录，里面的 fixture 自动对所有测试可见，无需 import）：

```python
import pytest

@pytest.fixture
def db_conn():
    conn = {"connected": True}   # 真实场景这里连数据库
    yield conn                   # 测试用 conn
    conn.clear()                 # 测试后清理
```

**练习**
1. 建 `conftest.py` 放一个返回列表的 fixture，两个测试共用它。
2. 体会 fixture 比"每个测试里手写准备"好在哪（改一处即可）。

---

### Day 4 · fixture 进阶

**目标**：掌握作用域、清理（yield）、自动 fixture。

```python
import pytest

@pytest.fixture(scope="module")   # 整个模块只建一次，省时间
def expensive_resource():
    res = {"loaded": True}
    yield res
    print("清理 resource")         # 模块结束时执行

@pytest.fixture(autouse=True)      # 不用声明也会自动用，适合日志/重置状态
def reset_env():
    yield
    print("每个测试后自动重置")

@pytest.fixture(scope="session")   # 整个测试会话一次，常用于全局连接
def app_client():
    yield "client"
```

`scope` 可选：`function`（默认）/`class`/`module`/`package`/`session`，越大越省资源但要小心状态污染。

**练习**
1. 用 `scope="session"` 的 fixture 模拟一个"全局配置对象"。
2. 写一个 `autouse` fixture 在每个测试前 `print("start")`，观察输出（`pytest -s` 才显示 print）。

---

### Day 5 · 参数化测试

**目标**：一组输入多组期望，一个测试函数全覆盖，消灭复制粘贴。

```python
import pytest

@pytest.mark.parametrize("a,b,expected", [
    (1, 2, 3),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_add_params(a, b, expected):
    assert a + b == expected

# ids 让失败信息可读
@pytest.mark.parametrize("value,ok", [
    ("abc", True),
    ("", False),
], ids=["正常", "空串"])
def test_valid(value, ok):
    assert (len(value) > 0) == ok
```

**练习**
1. 把 Day1 的多个 `test_*` 合并成一个参数化测试。
2. 用笛卡尔积：两个 `@parametrize` 叠在同一函数上，会得到所有组合。

---

## 第二周

### Day 6 · 标记与跳过

**目标**：给测试分类、按需运行、处理暂不支持/预期失败。

`pytest.ini`（或 `pyproject.toml`）注册自定义标记，避免告警：

```ini
[pytest]
markers =
    slow: 耗时较长的测试
    api: 依赖外部接口的测试
```

```python
import pytest, sys

@pytest.mark.slow
def test_big():
    ...

@pytest.mark.skip(reason="功能未实现")
def test_todo():
    ...

@pytest.mark.skipif(sys.version_info < (3, 9), reason="需要 3.9+")
def test_new():
    ...

@pytest.mark.xfail(reason="已知 bug")
def test_known_bug():
    assert 1 == 2
```

运行指定标记：`pytest -m slow`（只跑 slow）、`pytest -m "not slow"`（跳过慢的）。

**练习**
1. 给几个测试打 `api` 标记，用 `pytest -m "not api"` 跳过它们。
2. 体验 `xfail` 与真正失败的区别（失败算 xfail 通过，不该失败却通过了会 XPASS 警告）。

---

### Day 7 · Mock 与 monkeypatch

**目标**：隔离外部依赖（网络/时间/数据库），只测自己的逻辑。

```python
from unittest import mock
import pytest, requests

def fetch_price(url):
    return requests.get(url).json()["price"]

def test_fetch(monkeypatch):
    # 用 monkeypatch 替换 requests.get，不真发请求
    class FakeResp:
        def json(self): return {"price": 42}
    monkeypatch.setattr(requests, "get", lambda u: FakeResp())
    assert fetch_price("http://x") == 42

def test_with_mock():
    with mock.patch("requests.get") as m:
        m.return_value.json.return_value = {"price": 10}
        assert fetch_price("http://x") == 10
```

`monkeypatch` 是 pytest 内置 fixture，测试结束自动还原，比手动 mock 省心。

**练习**
1. 用 `monkeypatch.setattr` 把 `time.time` 固定为某个值，测一个依赖"当前时间"的函数。
2. 用 `mock.patch` 模拟一个会抛异常的网络调用，验证你的重试逻辑。

---

### Day 8 · 配置与命令行

**目标**：用配置文件统一管理，掌握常用命令行选项。

`pytest.ini` 常用项：

```ini
[pytest]
testpaths = tests              # 只搜这个目录
python_files = test_*.py
addopts = -ra -q              # 默认追加参数：-ra 显示摘要
filterwarnings = ignore::DeprecationWarning
```

`conftest.py` 的层级：`项目根/conftest.py` → `tests/conftest.py`，越底层优先级越高，适合分层 fixture。

高频命令：

```bash
pytest -v                 # 详细
pytest -k "add or sub"    # 按名字关键字跑
pytest -m "not slow"      # 按标记过滤
pytest -s                 # 显示 print
pytest --maxfail=3        # 失败 3 个就停
pytest tests/test_x.py::test_y   # 只跑某一个
```

**练习**
1. 建 `pytest.ini` 设 `testpaths=tests`，把测试挪进 `tests/` 目录验证仍能发现。
2. 用 `-k` 只跑名字含 `price` 的测试。

---

### Day 9 · 覆盖率与插件

**目标**：量化测试充分度，提速、出报告。

```bash
pip install pytest-cov pytest-xdist pytest-html
pytest --cov=myapp --cov-report=term-missing   # 终端看覆盖率+未覆盖行
pytest --cov=myapp --cov-report=html           # 生成 htmlcov/ 网页报告
pytest -n 4                                     # 4 进程并行（xdist）
pytest --html=report.html                       # 漂亮 HTML 报告（html）
```

常用插件：`pytest-cov`（覆盖率）、`pytest-xdist`（并行）、`pytest-html`（报告）、`pytest-mock`（mock 增强）、`pytest-django`/`pytest-asyncio`（框架适配）。

**练习**
1. 给 Day13 前的小项目跑 `--cov`，把覆盖率提到 80%+。
2. 用 `-n auto` 并行跑，对比耗时。

---

### Day 10 · 接入 CI/CD（衔接你的 Jenkins）

**目标**：push 代码自动跑 pytest，和前面搭的 Docker+Jenkins 串起来。

最小 `Jenkinsfile` 片段：

```groovy
stage('测试') {
    steps {
        sh 'python -m venv venv && . venv/bin/activate && pip install -r requirements.txt'
        sh 'pytest --junitxml=report.xml --cov=app'
    }
    post { always { junit 'report.xml' } }
}
```

GitHub Actions（`.github/workflows/test.yml`）：

```yaml
name: test
on: [push, pull_request]
jobs:
  pytest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - run: pytest --junitxml=report.xml
```

**练习**
1. 给你练习仓库加 `.github/workflows/test.yml`，push 后看 Actions 是否自动测。
2. 在 Jenkins 里把"测试"阶段接到你的流水线（回顾 CI/CD 专题第 11–13 步）。

---

### Day 11 · 测数据库与网络

**目标**：不污染真实数据，测试隔离可重复。

```python
import pytest

@pytest.fixture
def db(tmp_path):
    # 用临时文件库，跑完即删，绝不碰生产
    import sqlite3
    conn = sqlite3.connect(tmp_path / "t.db")
    conn.execute("CREATE TABLE u(id INTEGER, name TEXT)")
    yield conn
    conn.close()

def test_insert(db):
    db.execute("INSERT INTO u VALUES(1,'a')")
    assert db.execute("SELECT count(*) FROM u").fetchone()[0] == 1
```

要点：测试用临时库/事务回滚/容器化依赖（docker 起 Postgres），保证每次干净。

**练习**
1. 用 `tmp_path` fixture 测一个读写文件的函数（pytest 内置 `tmp_path` 自动清理）。
2. 用 docker 起一个 Redis，在测试里连它（回顾 CI/CD 专题的 sidecar 思路）。

---

### Day 12 · 最佳实践

**目标**：写出可维护、可信赖的测试。

- **FIRST 原则**：Fast（快）、Isolated（独立）、Repeatable（可重复）、Self-validating（自校验）、Timely（及时写）。
- **分层**：`tests/unit/`（快、纯逻辑）、`tests/integration/`（带依赖）、`tests/e2e/`（端到端）。
- **命名**：`test_<被测行为>_<预期>`，如 `test_withdraw_insufficient_funds_raises`。
- **一个断言聚焦一点**；用 fixture 而非 `setup/teardown`；少 mock 多真实（能真实就真实）。
- **不测第三方库本身**，只测自己的逻辑。

推荐目录：

```
myapp/
  src/myapp/
  tests/
    unit/
    integration/
    conftest.py
```

**练习**
1. 把前几天的测试按 unit/integration 重新归位。
2. 挑一个测试，改造成符合 FIRST 原则（如发现它依赖顺序，就拆开）。

---

### Day 13 · 实战项目（TDD）

**目标**：用测试驱动开发一个迷你项目，把知识串起来。

做一个"购物车"模块 `cart.py`：

```python
class Cart:
    def __init__(self):
        self.items = {}
    def add(self, name, price, qty=1):
        if price < 0: raise ValueError("价格不能为负")
        self.items[name] = self.items.get(name, 0) + qty
    def total(self, prices):
        return sum(prices[n] * q for n, q in self.items.items())
```

先写测试（红），再补实现（绿）：

```python
def test_add_and_total():
    c = Cart()
    c.add("apple", 3, 2)
    assert c.total({"apple": 3}) == 6

def test_negative_price_raises():
    c = Cart()
    with pytest.raises(ValueError):
        c.add("x", -1)
```

**练习**：自己加 `remove()`、`count()` 方法，每个都先写测试再实现；把覆盖率推到 100%。

---

### Day 14 · 复习与进阶

**目标**：查漏补缺，知道下一步学什么。

**高频踩坑**
| 坑 | 原因 | 解法 |
|----|------|------|
| fixture 改了值影响别的测试 | 可变对象共享 | 用 `scope` 合适 + 测试内复制 |
| mock 没生效 | patch 路径错（要 patch"被导入处"） | patch 使用方的模块路径 |
| 测试互相依赖顺序 | 共享全局状态 | 每个测试自包含，fixture 清理 |
| 覆盖率虚高 | 只测快乐路径 | 补异常/边界用例 |
| CI 本地能过远端挂 | 依赖环境差异 | 固定版本、用虚拟环境/容器 |

**下一步方向**：异步测试（`pytest-asyncio`）、性能测试（locust）、契约测试（pact）、模糊测试（hypothesis）、BDD（`pytest-bdd`）。

---

## 速查表

```bash
pytest                 # 跑全部
pytest -v -k add       # 详细 + 关键字
pytest -m "not slow"   # 按标记过滤
pytest --cov=app -html=rep.html   # 覆盖率+报告
pytest -n auto         # 并行
pytest --maxfail=1 -x  # 首个失败即停
```

```python
@pytest.fixture(scope="module")        # 准备数据
@pytest.mark.parametrize("a,b,e",[...]) # 参数化
@pytest.mark.skip / xfail              # 跳过/预期失败
with pytest.raises(Err): ...            # 测异常
monkeypatch.setattr(obj,"attr",val)    # 隔离依赖
assert x == pytest.approx(0.3)         # 浮点
```

---

## 衔接你已搭的 CI/CD

学完这份路线图，把 `tests/` 接进你 LinuxCases 里那套 Docker+Jenkins：
- 流水线加"测试"阶段跑 `pytest --junitxml=report.xml --cov=app`；
- `post` 里 `junit 'report.xml'` 出报告；
- 覆盖率低于阈值就失败，挡住劣质合入。

回到专题：[实战：用 Docker + Jenkins 搭建自动化测试 CI/CD](ubuntu-cicd-docker-jenkins.md)。
