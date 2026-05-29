# HbwebExpo 国际化补齐实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 `HbwebExpoApp` 所有页面与提示文本的国际化补齐，确保中英文切换后页面文案、提示文案、错误文案、状态文案都能稳定跟随语言输出。

**Architecture:** 保留现有 `i18next + react-i18next` 架构，在共享层补统一错误消息解析 helper，并按页面分批接入。优先消除 `error.message` 直出与提示文案硬编码，再处理状态映射、placeholder、Alert、空状态和残留展示层硬编码。

**Tech Stack:** Expo Router、React Native、React Native Paper、TypeScript、i18next、react-i18next。

---

### Task 1: 共享错误国际化基础

**Files:**
- Create: `HbwebExpoApp/src/shared/i18n/error-message.ts`
- Test: `HbwebExpoApp/src/shared/i18n/error-message.test.ts`
- Modify: `HbwebExpoApp/src/locales/zh/common.json`
- Modify: `HbwebExpoApp/src/locales/en/common.json`

- [x] **Step 1: 写共享错误消息测试**
- [x] **Step 2: 运行测试确认缺少实现时报错**
- [x] **Step 3: 实现统一错误消息 helper**
- [x] **Step 4: 补充通用错误 locale 文案**
- [x] **Step 5: 重新运行测试并通过**

### Task 2: 第一批核心页面接入 helper

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/settings.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/warehouse.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/local-supplier-invoices.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/product-query.tsx`

- [x] **Step 1: 设置页接入共享错误 helper**
- [x] **Step 2: 仓库页接入共享错误 helper**
- [x] **Step 3: 澳洲进货单页接入共享错误 helper**
- [~] **Step 4: 商品维护页分批替换错误提示**
- [x] **Step 5: 运行 `npx tsc --noEmit` 验证**

### Task 3: 第二批购物与订单流页面接入 helper

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/home.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/cart.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/domestic-purchase.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/store-vouchers.tsx`
- Modify: `HbwebExpoApp/app/(tabs)/installment-orders.tsx`

- [x] **Step 1: 首页接入共享错误 helper**
- [x] **Step 2: 购物车页接入共享错误 helper**
- [x] **Step 3: 中国采购页接入共享错误 helper**
- [x] **Step 4: 门店代金券页接入共享错误 helper**
- [x] **Step 5: 分期订单页接入共享错误 helper**
- [ ] **Step 6: 运行类型检查与残留扫描**

### Task 4: 用户与员工资料页提示统一

**Files:**
- Modify: `HbwebExpoApp/app/staff/[userGuid].tsx`
- Modify: `HbwebExpoApp/app/(tabs)/employee-profile.tsx`
- Modify: `HbwebExpoApp/src/shared/api/error-message.ts`（如需要）

- [ ] **Step 1: 盘点现有 `extractApiErrorMessage` 与 `profileQuery.error.message` 用法**
- [ ] **Step 2: 统一英文界面下的错误兜底策略**
- [ ] **Step 3: 替换资料页残留直接展示的原始错误**
- [ ] **Step 4: 运行类型检查**

### Task 5: 商品维护与业务模块残留清理

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/product-query.tsx`
- Modify: `HbwebExpoApp/src/modules/domestic-purchase/DomesticProductList.tsx`
- Modify: `HbwebExpoApp/src/components/attendance/AttendanceScreen.tsx`
- Modify: `HbwebExpoApp/src/modules/seasonal-cards/seasonal-cards-screen.tsx`
- Modify: 其余扫描命中的 UI 展示层文件

- [ ] **Step 1: 收掉 `product-query.tsx` 剩余错误提示直出**
- [ ] **Step 2: 收掉中国采购列表子模块残留**
- [ ] **Step 3: 收掉考勤主屏残留**
- [ ] **Step 4: 收掉季节卡与其他命中页面残留**
- [ ] **Step 5: 运行类型检查**

### Task 6: placeholder / Alert / 可访问性文本与验收

**Files:**
- Modify: 扫描命中的页面与组件
- Verify: `HbwebExpoApp/app/**`
- Verify: `HbwebExpoApp/src/components/**`
- Verify: `HbwebExpoApp/src/modules/**`

- [ ] **Step 1: 扫描 placeholder、Alert、accessibilityLabel 的残留硬编码**
- [ ] **Step 2: 补 locale key 并替换展示文本**
- [ ] **Step 3: 运行 `npx tsc --noEmit`**
- [ ] **Step 4: 再跑一次残留硬编码扫描**
- [ ] **Step 5: 记录仍允许保留的业务数据型文本**
