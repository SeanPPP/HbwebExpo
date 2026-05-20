# 零售价、折扣价、清货价格后添加毛利率显示

## 需求
在零售价、折扣价、清货价格**同行右侧**显示毛利率，格式为 `GP:99%`（一行内紧凑显示）

## GP 计算公式
```
GP% = (售价 - 进货价) / 售价 × 100
```
- 零售价 GP：`(retailPrice - purchasePrice) / retailPrice × 100`
- 折扣价 GP：`(discountedRetailPrice - purchasePrice) / discountedRetailPrice × 100`
- 清货价 GP：`(clearancePrice - purchasePrice) / clearancePrice × 100`
- 进货价或售价无效时显示 `--`

## 实现步骤

### 步骤 1：添加 GP 计算工具函数
**文件**: `HbwebExpoApp/app/(tabs)/product-query.tsx`

在工具函数区域添加 `calcGpPercent`，计算并返回格式化字符串如 `"99%"`。

### 步骤 2：更新 StorePriceStrategyCard 组件
**文件**: `HbwebExpoApp/src/components/product-maintenance/StorePriceStrategyCard.tsx`

- 新增 props：`retailGp?: string`、`discountedRetailGp?: string`
- **零售价**区域改为一行：`[TextInput flex:1] [GP文字]`（GP 紧贴输入框右侧）
- **折扣价**区域改为一行：`[TextInput flex:1] [GP文字]`（同上）
- GP 样式：小字加粗，颜色跟随对应价格（零售价蓝色、折扣价绿色）

### 步骤 3：更新 StoreClearancePriceCard 组件
**文件**: `HbwebExpoApp/src/components/product-maintenance/StoreClearancePriceCard.tsx`

- 新增 prop：`clearanceGp?: string`
- 在价格文本右侧同行显示 `GP:XX%`
- GP 样式：小字灰色

### 步骤 4：更新 product-query.tsx 传递 GP 计算值
**文件**: `HbwebExpoApp/app/(tabs)/product-query.tsx`

- 计算 `retailGp`、`discountedRetailGp`、`clearanceGp`
- 传递给 `StorePriceStrategyCard` 和 `StoreClearancePriceCard`

### 步骤 5：验证 TypeScript 编译
