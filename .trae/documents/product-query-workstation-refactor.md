# 商品查询页「工作台模式」改造计划

## 目标

把 product-query 从「长页面滚动」模式改成「查询后进入明细工作台」模式：
- 查询区保留在顶部，但压缩到最小
- 命中商品后，明细区域变成接近全屏的工作面板
- **第一屏**直接露出：商品图 + 货号/条码/类型/供应商 + 分店价格 + 清货价
- **第二屏（往下滚动）**：setCodes 和 multiCodes
- setCodes / multiCodes 做成可折叠区（Accordion / List.Accordion）

---

## 设计图

### 当前布局（改造前）

```
┌─────────────────────────────────────┐
│  商品查询                    📷  🔄  │  ← QueryHeader
│  当前分店：Sunnybank                │
├─────────────────────────────────────┤
│  [ 条码 / 货号 / 编码     ] 🔍  ✕  │  ← SearchPanel
│  最近命中：12345 / 9300...          │
├─────────────────────────────────────┤
│ ┌─────────┐  商品名称 ABC          │
│ │         │  Grade A               │
│ │  商品图  │  ┌────────────────┐    │
│ │         │  │ 货号  12345     │    │  ← ProductHeroCard
│ │         │  │ 类型  普商品     │    │
│ └─────────┘  │ 供应商 XX公司   │    │
│              └────────────────┘    │
│  条码  9300123456789   [条码图]     │
├─────────────────────────────────────┤
│ ──── ↑ 以上第一屏已占满 ────        │
│                                     │
│  Sunnybank                          │
│  [进货 10.00]  [零售 15.00]        │  ← StorePriceStrategyCard
│  Rate 1.50 · 自动策略               │     (需要滚动才看到!)
│  [自动 ○]  [特殊 ●]                │
├─────────────────────────────────────┤
│  分店清货价                          │
│  分店 Sunnybank                     │  ← StoreClearancePriceCard
│  清货价 8.00                        │     (需要滚动才看到!)
├─────────────────────────────────────┤
│  套装条码                            │
│  9300... · 数量2 · 12.00           │  ← SetCodeCompactSection
│  9300... · 数量1 · 8.00            │
├─────────────────────────────────────┤
│  9300999001                         │
│  [进货 5.00]  [零售 8.00]          │  ← MultiCodeCompactList
│  Rate 1.60                          │
│  [自动 ○] [特殊 ●]         [存]    │
│  9300999002                         │
│  [进货 6.00]  [零售 9.00]          │
│  ...                                │
├─────────────────────────────────────┤
│  改动 2 项           [放弃] [全部保存] │  ← StickyActionBar
└─────────────────────────────────────┘

问题：价格信息在第一屏下方，需要滚动才能看到
```

### 改造后布局（工作台模式）

```
┌─────────────────────────────────────┐
│  商品查询                    📷  🔄  │  ← QueryHeader (不变)
│  当前分店：Sunnybank                │
├─────────────────────────────────────┤
│  [ 条码 / 货号 / 编码     ] 🔍  ✕  │  ← SearchPanel (不变)
│  最近命中：12345 / 9300...          │
╞═════════════════════════════════════╡  ← 工作台区域开始
│ ┌─────────┐  商品名称 ABC          │
│ │         │  Grade A               │
│ │  商品图  │  ┌────────────────┐    │
│ │         │  │ 货号  12345     │    │  ← ProductHeroCard (不变)
│ │         │  │ 类型  普商品     │    │
│ └─────────┘  │ 供应商 XX公司   │    │
│              └────────────────┘    │
│  条码  9300123456789   [条码图]     │
├─────────────────────────────────────┤
│  Sunnybank                          │
│  [进货 10.00]  [零售 15.00]        │  ← StorePriceStrategyCard
│  Rate 1.50 · 自动策略               │     ✅ 第一屏可见!
│  [自动 ○]  [特殊 ●]                │
├─────────────────────────────────────┤
│  分店清货价                          │
│  分店 Sunnybank                     │  ← StoreClearancePriceCard
│  清货价 8.00                        │     ✅ 第一屏可见!
├─────────────────────────────────────┤
│  ▶ 套装条码 (2)                     │  ← List.Accordion
│    (折叠, 点击展开)                  │     默认收起
├─────────────────────────────────────┤
│  ▼ 多码价格 (3)                     │  ← List.Accordion
│  ┌───────────────────────────────┐  │     默认展开
│  │ 9300999001                    │  │
│  │ [进货 5.00]  [零售 8.00]     │  │
│  │ Rate 1.60                     │  │
│  │ [自动 ○] [特殊 ●]    [存]    │  │
│  ├───────────────────────────────┤  │
│  │ 9300999002                    │  │
│  │ [进货 6.00]  [零售 9.00]     │  │
│  │ ...                           │  │
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  改动 2 项           [放弃] [全部保存] │  ← StickyActionBar (不变)
└─────────────────────────────────────┘

✅ 价格信息无需滚动即可查看
✅ setCodes/multiCodes 折叠后不占首屏空间
```

### 第一屏可视范围对比

```
  改造前                    改造后
┌──────────────┐     ┌──────────────┐
│ QueryHeader  │     │ QueryHeader  │
│ SearchPanel  │     │ SearchPanel  │
│              │     │              │
│ ProductHero  │     │ ProductHero  │
│ Card         │     │ Card         │
│              │     │              │
│              │     │ StorePrice   │ ← ✅ 现在可见!
│ ── 可视边界 ──│     │ StrategyCard │
│              │     │              │
│ StorePrice   │     │ Clearance    │ ← ✅ 现在可见!
│ (需要滚动)   │     │ PriceCard    │
│              │     │              │
│ Clearance    │     │ ▶ 套装(2)    │ ← ✅ 折叠不占空间
│ (需要滚动)   │     │ ▼ 多码(3)    │ ← ✅ 折叠不占空间
│              │     │              │
│ SetCodes     │     └──────────────┘
│ (需要滚动)   │
│ MultiCodes   │
│ (需要滚动)   │
└──────────────┘
```

---

## 当前布局结构

```
SafeAreaView
├── QueryHeader          （标题 + 分店 + 扫码/刷新按钮）
├── SearchPanel          （搜索栏 + 最近命中标签）
├── ScrollView
│   ├── ProductHeroCard  （商品图 + 货号/条码/类型/供应商）
│   ├── StorePriceStrategyCard  （分店价格：进/零售价 + 开关）
│   ├── StoreClearancePriceCard （清货价）
│   ├── SetCodeCompactSection   （套装条码列表）
│   └── MultiCodeCompactList    （多码列表，可编辑）
├── StickyActionBar      （有改动时底部固定按钮）
├── LookupResultSheet    （多结果选择底部弹窗）
├── Portal > Modal       （相机扫码弹窗）
├── Snackbar
└── Hidden TextInput     （HID 扫码枪）
```

**问题**：所有内容平铺在 ScrollView 里，价格信息需要滚动才能看到。

## 改造后布局结构

```
SafeAreaView (flex:1)
├── QueryHeader          （保留，不变）
├── SearchPanel          （保留，不变）
├── ─── 以下为「工作台区域」───
│   detail 为 null 时：空状态/错误提示（与现有一致）
│   detail 有值时：
│       ScrollView (flex:1)
│       ├── ProductHeroCard          （保持不变）
│       ├── StorePriceStrategyCard   （保持不变）
│       ├── StoreClearancePriceCard  （保持不变）
│       ├── List.Accordion "套装条码" （折叠 setCodes）
│       │   └── SetCodeCompactSection 内容
│       └── List.Accordion "多码价格" （折叠 multiCodes）
│           └── MultiCodeCompactList 内容
├── StickyActionBar
├── LookupResultSheet
├── Portal > Modal
├── Snackbar
└── Hidden TextInput
```

## 实施步骤

### 步骤 1：将 setCodes 改造为折叠区

**文件**：`src/components/product-maintenance/SetCodeCompactSection.tsx`

- 使用 `react-native-paper` 的 `List.Accordion` + `List.Item` 包裹现有内容
- 默认**折叠**状态（因为 setCodes 是次要信息）
- Accordion 标题显示数量 badge（如 "套装条码 (3)"）
- items 为空时仍返回 null

**预计改动**：
- 导入 `List` 组件
- 用 `List.Accordion` 包裹现有 Card 内容
- 标题动态显示条目数量

### 步骤 2：将 multiCodes 改造为折叠区

**文件**：`src/components/product-maintenance/MultiCodeCompactList.tsx`

- 使用 `List.Accordion` 包裹多码列表
- 默认**展开**状态（因为 multiCodes 可编辑，是核心操作区）
- Accordion 标题显示条目数量
- items 为空时仍返回 null

**预计改动**：
- 导入 `List` 组件
- 用 `List.Accordion` 包裹现有的 cards container
- 标题动态显示条目数量

### 步骤 3：更新 i18n 翻译文件

**文件**：
- `src/locales/zh/screens/productQuery.json`
- `src/locales/en/screens/productQuery.json`

添加折叠区标题相关的翻译 key：
- `setCode.accordionTitle`：如 "套装条码 ({{count}})"
- `multiCode.accordionTitle`：如 "多码价格 ({{count}})"

### 步骤 4：验证页面布局效果

- 确认第一屏可见内容：QueryHeader + SearchPanel + ProductHeroCard + StorePriceStrategyCard + StoreClearancePriceCard（无需滚动即可看到价格）
- 确认 setCodes / multiCodes 在折叠状态下不占首屏空间
- 确认展开/折叠交互正常
- 确认编辑、保存等现有功能不受影响

## 不改动的部分

- **QueryHeader**：保持不变
- **SearchPanel**：保持不变
- **ProductHeroCard**：保持不变
- **StorePriceStrategyCard**：保持不变
- **StoreClearancePriceCard**：保持不变
- **StickyActionBar**：保持不变
- **LookupResultSheet**：保持不变
- **product-query.tsx 主文件**：结构基本不变，只替换 SetCodeCompactSection 和 MultiCodeCompactList 的渲染方式（如果组件内部自行处理折叠，则主文件无需改动）
- **所有业务逻辑**（state、callback、API 调用）：完全不动

## 技术要点

- 使用 `react-native-paper` 原生的 `List.Accordion` 组件，与项目现有 UI 库一致
- 折叠/展开是纯 UI 层改造，不涉及任何状态管理或 API 变更
- `List.Accordion` 支持 `expanded` 和 `onPress` 回调，可以受控也可以非受控
