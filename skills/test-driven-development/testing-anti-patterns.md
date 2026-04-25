# 测试反模式

**在以下情况加载这份参考：** 编写或修改测试、添加 mock，或者你正想往生产代码里加只给测试用的方法时。

## 概览

测试必须验证真实行为，而不是 mock 的行为。Mock 是隔离手段，不是被测试对象本身。

**核心原则：** 测试代码做了什么，而不是 mock 做了什么。

**严格遵循 TDD，可以避免这些反模式。**

## 铁律

```
1. 绝不测试 mock 的行为
2. 绝不在生产类里加入只给测试用的方法
3. 绝不在没搞清依赖关系前就开始 mock
```

## 反模式 1：测试 Mock 行为

**违规示例：**
```typescript
// ❌ BAD: Testing that the mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**为什么这是错的：**
- 你验证的是 mock 能不能工作，而不是组件能不能工作
- 测试在 mock 存在时通过，不存在时失败
- 它对真实行为毫无说明力

**你的 human partner 的提醒：** “我们现在是在测 mock 的行为吗？”

**修正方式：**
```typescript
// ✅ GOOD: Test real component or don't mock it
test('renders sidebar', () => {
  render(<Page />);  // Don't mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

// OR if sidebar must be mocked for isolation:
// Don't assert on the mock - test Page's behavior with sidebar present
```

### 门禁函数

```
在对任何 mock 元素做断言之前：
  问："我是在测试真实组件行为，还是只是在确认 mock 存在？"

  如果是在测试 mock 是否存在：
    停止 - 删除这个断言，或者取消对该组件的 mock

  改为测试真实行为
```

## 反模式 2：在生产代码里加只给测试用的方法

**违规示例：**
```typescript
// ❌ BAD: destroy() only used in tests
class Session {
  async destroy() {  // Looks like production API!
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... cleanup
  }
}

// In tests
afterEach(() => session.destroy());
```

**为什么这是错的：**
- 生产类被测试专用代码污染了
- 如果在生产环境被误调用会很危险
- 违反 YAGNI，也破坏关注点分离
- 把对象生命周期和实体生命周期混在了一起

**修正方式：**
```typescript
// ✅ GOOD: Test utilities handle test cleanup
// Session has no destroy() - it's stateless in production

// In test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// In tests
afterEach(() => cleanupSession(session));
```

### 门禁函数

```
在给生产类添加任何方法之前：
  问："这个方法是不是只会在测试里用？"

  如果是：
    停止 - 不要加
    把它放进测试工具函数里

  再问："这个类真的拥有这份资源的生命周期吗？"

  如果不是：
    停止 - 这个方法放错类了
```

## 反模式 3：没搞清楚依赖就开始 Mock

**违规示例：**
```typescript
// ❌ BAD: Mock breaks test logic
test('detects duplicate server', () => {
  // Mock prevents config write that test depends on!
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // Should throw - but won't!
});
```

**为什么这是错的：**
- 被 mock 的方法带有测试所依赖的副作用（写配置）
- 为了“保险起见”过度 mock，反而破坏了真实行为
- 测试会因为错误原因通过，或者莫名其妙失败

**修正方式：**
```typescript
// ✅ GOOD: Mock at correct level
test('detects duplicate server', () => {
  // Mock the slow part, preserve behavior test needs
  vi.mock('MCPServerManager'); // Just mock slow server startup

  await addServer(config);  // Config written
  await addServer(config);  // Duplicate detected ✓
});
```

### 门禁函数

```
在 mock 任何方法之前：
  停止 - 先别 mock

  1. 问："真实方法有哪些副作用？"
  2. 问："这个测试是否依赖其中任何副作用？"
  3. 问："我是否真的完全理解这个测试需要什么？"

  如果依赖副作用：
    在更低层 mock（真正慢/外部的操作）
    或使用能保留必要行为的 test double
    不要去 mock 测试本身依赖的那个高层方法

  如果你还不确定测试依赖什么：
    先用真实实现跑一遍测试
    观察真正需要发生什么
    然后再在正确层级上加最小化的 mock

  红旗信号：
    - "我先 mock 一下比较安全"
    - "这个可能会很慢，还是 mock 掉吧"
    - 在没理解依赖链的情况下直接 mock
```

## 反模式 4：不完整的 Mock

**违规示例：**
```typescript
// ❌ BAD: Partial mock - only fields you think you need
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // Missing: metadata that downstream code uses
};

// Later: breaks when code accesses response.metadata.requestId
```

**为什么这是错的：**
- **局部 mock 会掩盖结构假设**：你只 mock 了你知道的字段
- **下游代码可能依赖你没包含的字段**：于是就会静默失败
- **测试通过，但集成失败**：因为 mock 不完整，而真实 API 是完整的
- **制造虚假信心**：这个测试并不能证明真实行为

**铁律：** mock 的必须是现实中完整存在的数据结构，而不只是当前测试直接用到的字段。

**修正方式：**
```typescript
// ✅ GOOD: Mirror real API completeness
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // All fields real API returns
};
```

### 门禁函数

```
在构造 mock 响应之前：
  检查："真实 API 响应包含哪些字段？"

  动作：
    1. 查看文档/示例中的真实 API 响应
    2. 包含系统在下游可能消费的全部字段
    3. 确认 mock 与真实响应 schema 完整一致

  关键点：
    只要你要创建 mock，你就必须理解整个结构
    局部 mock 会在代码依赖被省略字段时静默失效

  如果不确定：把所有文档里定义的字段都带上
```

## 反模式 5：把集成测试当作事后补充

**违规示例：**
```
✅ 实现完成
❌ 没有写测试
"Ready for testing"
```

**为什么这是错的：**
- 测试是实现的一部分，不是可选的后续动作
- TDD 本来就会抓到这个问题
- 没有测试，就不能宣称工作已完成

**修正方式：**
```
TDD cycle:
1. 先写失败测试
2. 实现到通过
3. 重构
4. 然后再宣称完成
```

## 当 Mock 变得过于复杂时

**警告信号：**
- Mock 配置比测试逻辑还长
- 为了让测试通过，什么都在 mock
- Mock 缺少真实组件本来有的方法
- Mock 一改，测试就碎

**你的 human partner 可能会问：** “这里真的需要 mock 吗？”

**可以考虑：** 使用真实组件的集成测试，往往比复杂 mock 更简单。

## TDD 如何防止这些反模式

**为什么 TDD 有帮助：**
1. **先写测试** → 强迫你先想清楚自己到底在测什么
2. **看着它失败** → 确认测试测到的是真实行为，不是 mock
3. **最小实现** → 不会顺手混入只给测试用的方法
4. **真实依赖先跑通** → 在开始 mock 前，你已经知道测试真正需要什么

**如果你在测试 mock 的行为，说明你已经违背了 TDD**：你在没先让测试对真实代码失败的情况下就加了 mock。

## 快速参考

| 反模式 | 修正方式 |
|--------|----------|
| 对 mock 元素做断言 | 测试真实组件，或者取消 mock |
| 在生产代码里加测试专用方法 | 移到测试工具里 |
| 没搞清依赖就 mock | 先理解依赖，再最小化 mock |
| 不完整的 mock | 完整镜像真实 API |
| 测试作为事后补充 | 用 TDD，测试先写 |
| 过度复杂的 mock | 考虑改用集成测试 |

## Red Flags

- 断言里检查 `*-mock` 这样的 test ID
- 某个方法只在测试文件里被调用
- Mock 配置占了测试的一半以上
- 去掉 mock 之后测试就失败
- 你说不清为什么需要这个 mock
- “先 mock 一下更保险”

## 最后的结论

**Mock 是用于隔离的工具，不是拿来测试的对象。**

如果 TDD 暴露出你在测试 mock 行为，说明方向已经错了。

修正：去测试真实行为，或者先质疑一下你为什么非得 mock。
