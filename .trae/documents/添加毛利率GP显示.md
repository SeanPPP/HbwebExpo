# 零售价、折扣价、清货价格后添加毛利率显示

## 需求
- 在零售价、折扣价、清货价格**同行右侧**显示毛利率，格式如 `GP:99.50%`
- GP 保留 **2 位小数**
- 零售价/折扣价的 GP **加粗显示**

## GP 计算公式
```
GP% = (售价 - 进货价) / 售价 × 100，保留 2 位小数
```
- 进货价或售价无效时显示 `--`

## 实现步骤

### 步骤 1：添加 GP 计算工具函数
**文件**: `HbwebExpoApp/app/(tabs)/product-query.tsx`

在工具函数区域添加 `calcGpPercent`：
```typescript
function calcGpPercent(sellPrice?: number | null, purchasePrice?: number | null): string {
  if (sellPrice == null || !Number.isFinite(sellPrice) || sellPrice <= 0) return "";
  if (purchasePrice == null || !Number.isFinite(purchasePrice) || purchasePrice < 0) return "";
  const gp = ((sellPrice - purchasePrice) / sellPrice) * 100;
  if (!Number.isFinite(gp)) return "";
  return gp.toFixed(2) + "%";
}
```

### 步骤 2：更新 StorePriceStrategyCard 组件
**文件**: `HbwebExpoApp/src/components/product-maintenance/StorePriceStrategyCard.tsx`

- 新增 props：`retailGp?: string`、`discountedRetailGp?: string`
- 零售价区域改为一行：`[TextInput flex:1] [GP文字 加粗]`
- 折扣价区域改为一行：`[TextInput flex:1] [GP文字 加粗]`
- GP 文字样式：`fontWeight:"700"`，`fontSize:12`，颜色跟随对应价格

### 步骤 3：更新 StoreClearancePriceCard 组件
**文件**: `HbwebExpoApp/src/components/product-maintenance/StoreClearancePriceCard.tsx`

- 新增 prop：`clearanceGp?: string`
- 在价格文本右侧同行显示 GP（普通字重）
- 样式：`fontSize:10`，灰色

### 步骤 4：更新 product-query.tsx 传递 GP 计算值
**文件**: `HbwebExpoApp/app/(tabs)/product-query.tsx`

- 计算 `retailGp`、`discountedRetailGp`、`clearanceGp`
- 传递给 `StorePriceStrategyCard` 和 `StoreClearancePriceCard`

### 步骤 5：验证 TypeScript 编译
