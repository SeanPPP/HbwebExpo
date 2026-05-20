# 套装/多码条码区域 UI 改造

## 需求

1. **每行显示**：条码、零售价、打印按钮在同一行（当前是条码一行，零售价+按钮另一行）
2. **点击弹窗编辑**：条码和零售价不再使用 TextInput 直接编辑，改为点击后弹窗输入
3. **添加按钮在区域上方**：新增按钮从底部移到标题行右侧，点击后弹窗输入条码

## 当前布局 vs 目标布局

### 当前布局（每项占两行）
```
标题: 套装条码 (3/10)
─────────────────
| 条码输入框          |  ← 第一行：TextInput
| $12.34  [打印] [保存] |  ← 第二行：价格 + 按钮
─────────────────
... (更多项)
─────────────────
| 新增套装条码         |  ← 底部草稿区
| 条码输入框          |
| $12.34  [新增]       |
─────────────────
```

### 目标布局（紧凑单行）
```
标题: 套装条码 (3/10)          [+ 新增]  ← 添加按钮移到标题右侧
───────────────────────────────────────
| #1 │ 9525812580371 │ $12.34 │ 🖨 打印 |  ← 行号+条码+价格+打印
| #2 │ 9525812580372 │ $15.00 │ 🖨 打印 |
| #3 │ 9525812580373 │  --    │ 🖨 打印 |
───────────────────────────────────────
加载更多
```

## 修改文件

### 1. MultiCodeCompactList.tsx — 多码条码列表

**文件**: `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/src/components/product-maintenance/MultiCodeCompactList.tsx`

**改动要点**：
- 标题行右侧添加"新增"按钮
- 删除底部草稿区（draftItem），改为弹窗输入
- 每项改为单行显示：`条码文本 | 零售价文本 | 打印图标按钮`
- 条码和零售价改为 `Pressable` + `Text`，点击触发弹窗
- 需要新增 `onEditItemBarcode` 回调（点击条码时触发弹窗）
- 需要新增 `onEditItemRetailPrice` 回调（点击零售价时触发弹窗）
- 需要新增 `onAddItem` 回调（点击新增按钮时触发弹窗）

**新的 Props 变更**：
```typescript
interface MultiCodeCompactListProps {
  items: MultiCodeEditableItem[];
  savingItemId?: string | null;
  printingItemId?: string | null;
  totalCount?: number;
  loading?: boolean;
  loadingMore?: boolean;
  hasMore?: boolean;
  onEditItemBarcode: (setCodeId: string) => void;      // 新增：点击条码弹窗编辑
  onEditItemRetailPrice: (setCodeId: string) => void;    // 新增：点击零售价弹窗编辑
  onSaveItem: (setCodeId: string) => void;
  onPrintItem: (setCodeId: string) => void;
  onAddItem: () => void;                                 // 新增：点击新增按钮弹窗
  onLoadMore?: () => void;
  // 移除: draftBarcode, mainRetailPrice, onChangeDraftBarcode, onChangeItem, onCreateItem
}
```

**每行布局**：
```
┌──────────────────────────────────────────┐
│ #1 │ 9525812580371 │  $12.34  │ 🖨 打印  │
│    │ (Pressable)   │(Pressable)│ (Button) │
└──────────────────────────────────────────┘
- 行号：序号 1, 2, 3...（基于 items 数组 index + 1）
- 条码：Pressable Text，点击弹窗编辑
- 零售价：Pressable Text，点击弹窗编辑
- 打印：图标按钮
```

### 2. SetCodeCompactSection.tsx — 套装条码列表

**文件**: `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/src/components/product-maintenance/SetCodeCompactSection.tsx`

**改动要点**：同多码列表
- 标题行右侧添加"新增"按钮
- 每项改为单行：条码 | 零售价 | 打印
- 点击条码/零售价弹窗编辑
- 删除底部草稿区

**新的 Props 变更**：
```typescript
interface SetCodeCompactSectionProps {
  items: ProductSetCodeItem[];
  savingItemId?: string | null;
  printingItemId?: string | null;
  totalCount?: number;
  loading?: boolean;
  loadingMore?: boolean;
  hasMore?: boolean;
  onEditItemBarcode: (setCodeId: string) => void;
  onEditItemRetailPrice: (setCodeId: string) => void;
  onSaveItem: (setCodeId: string) => void;
  onPrintItem: (setCodeId: string) => void;
  onAddItem: () => void;
  onLoadMore?: () => void;
  // 移除: draftBarcode, draftRetailPrice, onChangeDraftBarcode, onEditDraftRetailPrice, onChangeItem, onCreateItem
}
```

### 3. product-query.tsx — 调用方适配

**文件**: `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/app/(tabs)/product-query.tsx`

**改动要点**：
- 移除 `setDraftBarcode`、`setDraftRetailInput`、`multiDraftBarcode` 等草稿 state
- 新增弹窗状态管理（编辑条码弹窗、编辑零售价弹窗、新增弹窗）
- 将条码编辑改为弹窗模式（使用已有的 `NumericInputModal` 或 `TextInput` 弹窗）
- 新增弹窗相关 state：`codeEditModal`（{type: 'barcode'|'retail', targetId, value}）
- 新增弹窗相关 state：`codeAddModal`（{type: 'set'|'multi'}）
- 传递新的 props 给两个组件

**弹窗编辑流程**：
1. 用户点击某行的条码文本 → 设置 `codeEditModal = {type:'barcode', targetId, value}` → 弹出 TextInput 弹窗
2. 用户在弹窗中输入新条码 → 确认 → 更新 detail 中的对应条码值 → 自动触发保存
3. 用户点击某行的零售价 → 设置 `codeEditModal = {type:'retail', targetId, value}` → 弹出 NumericInputModal
4. 用户在弹窗中输入新价格 → 确认 → 更新 detail 中的对应零售价 → 自动触发保存
5. 用户点击"新增"按钮 → 弹窗输入条码 → 确认 → 调用创建 API

### 4. 国际化文件（可选）

如果需要新增翻译键（如"edit barcode"、"edit retail price"弹窗标题），需要更新：
- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/src/locales/en/screens/productQuery.json`
- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/src/locales/zh/screens/productQuery.json`

新增键：
```json
{
  "setCode": {
    "editBarcodeTitle": "编辑套装条码",
    "editRetailTitle": "编辑套装零售价"
  },
  "multiCode": {
    "editBarcodeTitle": "编辑多码条码",
    "editRetailTitle": "编辑多码零售价"
  }
}
```

## 实施步骤

1. 修改 `MultiCodeCompactList.tsx`：单行布局 + 标题添加按钮 + 点击弹窗
2. 修改 `SetCodeCompactSection.tsx`：同上
3. 修改 `product-query.tsx`：移除草稿 state，新增弹窗 state 和回调
4. 更新国际化文件
5. TypeScript 类型检查
