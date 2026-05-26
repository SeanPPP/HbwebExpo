# Store Payment And Voucher Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two branch finance management pages in HbwebExpo: installment payment orders with payment records, and store voucher management with issue/use history plus related orders.

**Architecture:** Keep backend transport and normalization in isolated modules, keep entity color/tag UI in shared components, and keep each page as a route-level composition over those modules. Reuse the existing `local-supplier-invoices` filter pattern: always-visible filter panel, `StorePickerModal`, one shared `MonthDatePicker` modal for start/end date selection, and card-based result rows.

**Tech Stack:** Expo Router, React Native, React Native Paper, TanStack Query, local i18n JSON namespaces, existing `apiClient`.

---

## Decoupled Workstreams

1. **Shared UI foundation**
   - Owns entity tag colors, generic selection modal, and reusable date range helpers.
   - Files:
     - Create: `HbwebExpoApp/src/shared/utils/entity-color.ts`
     - Create: `HbwebExpoApp/src/shared/utils/entity-color.test.ts`
     - Create: `HbwebExpoApp/src/components/ui/EntityTag.tsx`
     - Create: `HbwebExpoApp/src/components/ui/SelectionListModal.tsx`

2. **Installment order data module**
   - Owns types, API payload builders, response normalization, and tests.
   - Use current React POSM endpoint evidence: `POST /react/v1/posm-sales-orders/list` and `GET /react/v1/posm-sales-orders/detail/{orderGuid}`. Default order type is `Installment = 4`; status remains a separate optional filter, and phone/name filters are kept in UI state and folded into the existing `keyword` transport until backend exposes dedicated fields.
   - Files:
     - Create: `HbwebExpoApp/src/modules/installment-orders/types.ts`
     - Create: `HbwebExpoApp/src/modules/installment-orders/api.ts`
     - Create: `HbwebExpoApp/src/modules/installment-orders/api-normalization.test.ts`

3. **Store voucher data module**
   - Owns types, API payload builders, response normalization, and tests.
   - Prefer React-style paths under `/react/v1/store-vouchers`; allow normalization to accept older POS-style fields from `StoreVoucher` (`ID`, `VoucherCode`, `RemainingAmount`, `CreateTime`, `Status`, etc.).
   - Files:
     - Create: `HbwebExpoApp/src/modules/store-vouchers/types.ts`
     - Create: `HbwebExpoApp/src/modules/store-vouchers/api.ts`
     - Create: `HbwebExpoApp/src/modules/store-vouchers/api-normalization.test.ts`

4. **Installment orders page**
   - Owns route UI and page state.
   - Requirements covered:
     - Branch/status/user phone/user name/date range filters.
     - Date range uses one `MonthDatePicker` modal with `datePickerTarget`.
     - Branch filter uses modal list.
     - Rows show branch color tag, status badge, customer phone/name, totals.
     - Detail modal displays order detail and payment records.
   - Files:
     - Create: `HbwebExpoApp/app/(tabs)/installment-orders.tsx`

5. **Store vouchers page**
   - Owns route UI and page state.
   - Requirements covered:
     - Branch/supplier/status/date range filters.
     - Branch and supplier filters use modal lists.
     - Rows show branch/supplier colored tags when values exist.
     - Detail modal displays issue/use ledger and related orders.
   - Files:
     - Create: `HbwebExpoApp/app/(tabs)/store-vouchers.tsx`

6. **Navigation and i18n integration**
   - Owns route registration, tab grouping, route tests, and bilingual strings.
   - Files:
     - Modify: `HbwebExpoApp/app/(tabs)/_layout.tsx`
     - Modify: `HbwebExpoApp/src/modules/navigation/default-route.ts`
     - Modify: `HbwebExpoApp/src/modules/navigation/default-route.test.ts`
     - Modify: `HbwebExpoApp/src/components/navigation/tab-grouping.ts`
     - Modify: `HbwebExpoApp/src/components/navigation/tab-grouping.test.ts`
     - Modify: `HbwebExpoApp/src/shared/i18n/i18n.ts`
     - Modify: `HbwebExpoApp/src/locales/zh/common.json`
     - Modify: `HbwebExpoApp/src/locales/en/common.json`
     - Create: `HbwebExpoApp/src/locales/zh/screens/installmentOrders.json`
     - Create: `HbwebExpoApp/src/locales/en/screens/installmentOrders.json`
     - Create: `HbwebExpoApp/src/locales/zh/screens/storeVouchers.json`
     - Create: `HbwebExpoApp/src/locales/en/screens/storeVouchers.json`

## Execution Tasks

### Task 1: Shared UI Foundation

**Files:**
- Create: `HbwebExpoApp/src/shared/utils/entity-color.ts`
- Create: `HbwebExpoApp/src/shared/utils/entity-color.test.ts`
- Create: `HbwebExpoApp/src/components/ui/EntityTag.tsx`
- Create: `HbwebExpoApp/src/components/ui/SelectionListModal.tsx`

- [x] **Step 1: Add deterministic entity colors**

Implement `getEntityTone(key, kind)` with a finite palette and a small hash function. Return `{ backgroundColor, borderColor, textColor }`. Empty keys should use a neutral tone. Use different palette offsets for `store` and `supplier` so the same code does not always look identical across entity kinds.

- [x] **Step 2: Add entity color tests**

Run: `npx --yes tsx src/shared/utils/entity-color.test.ts`

Expected: same key is stable, empty key is neutral, store and supplier kinds can diverge, and a sample set maps to multiple tones.

- [x] **Step 3: Add `EntityTag`**

Create a compact pill component that accepts `kind`, `code`, `label`, and optional `compact`. It should display `label || code || "--"` and apply the tone from `getEntityTone`.

- [x] **Step 4: Add `SelectionListModal`**

Create a generic modal list for supplier/status options:
`visible`, `title`, `cancelLabel`, `items`, `selectedKey`, `includeAllOption`, `allLabel`, `loading`, `emptyLabel`, `onDismiss`, `onSelect`.
Use `Portal`, `Modal`, `ScrollView`, `RadioButton`, `Button`, and `ActivityIndicator`, following `StorePickerModal`.

### Task 2: Installment Order API

**Files:**
- Create: `HbwebExpoApp/src/modules/installment-orders/types.ts`
- Create: `HbwebExpoApp/src/modules/installment-orders/api.ts`
- Create: `HbwebExpoApp/src/modules/installment-orders/api-normalization.test.ts`

- [x] **Step 1: Define types**

Include `InstallmentOrderStatus`, `InstallmentOrderFilters`, `InstallmentOrderListItem`, `InstallmentPaymentRecord`, `InstallmentOrderDetailLine`, `InstallmentOrderDetail`, and `PagedResult<T>`.

- [x] **Step 2: Implement payload builder**

`buildInstallmentOrderListPayload({ page, pageSize, filters })` should send:
`startDate`, `endDate`, `branchCode`, `orderType`, `status`, `keyword`, `pageNumber`, `pageSize`.
Build `keyword` from `userPhone` and `userName` without losing either user-entered value.

- [x] **Step 3: Implement normalizers**

Normalize camelCase and PascalCase fields:
`orderGuid/OrderGuid`, `branchCode/BranchCode`, `branchName/BranchName`, `orderTime/OrderTime`, `status/Status`, `actualAmount/ActualAmount`, and nested `paymentDetails/PaymentDetails`.

- [x] **Step 4: Implement API functions**

`fetchInstallmentOrders(query)` posts to `/react/v1/posm-sales-orders/list`.
`fetchInstallmentOrderDetail(orderGuid)` gets `/react/v1/posm-sales-orders/detail/{orderGuid}`.

- [x] **Step 5: Add tests**

Run: `npx --yes tsx src/modules/installment-orders/api-normalization.test.ts`

Expected: payload filters are shaped correctly, pagination defaults are stable, and mixed casing responses normalize to typed data.

### Task 3: Store Voucher API

**Files:**
- Create: `HbwebExpoApp/src/modules/store-vouchers/types.ts`
- Create: `HbwebExpoApp/src/modules/store-vouchers/api.ts`
- Create: `HbwebExpoApp/src/modules/store-vouchers/api-normalization.test.ts`

- [x] **Step 1: Define types**

Include `StoreVoucherStatus`, `StoreVoucherFilters`, `StoreVoucher`, `StoreVoucherLedgerItem`, `StoreVoucherRelatedOrder`, `StoreVoucherDetail`, and `PagedResult<T>`.

- [x] **Step 2: Implement payload/query builder**

`buildStoreVoucherListPayload({ page, pageSize, filters })` should send `storeCode`, `supplierCode`, `status`, `startDate`, `endDate`, `pageNumber`, and `pageSize`.

- [x] **Step 3: Implement normalizers**

Support old POS fields (`ID`, `VoucherCode`, `VoucherType`, `RemainingAmount`, `CreateTime`, `UpdateTime`, `ExpiredDate`, `Remark`) and React-style camel fields. Ledger items need `action` values `issued` or `used`; related orders need `orderGuid`, `orderNo`, `storeCode`, `supplierCode`, `amount`, and `orderTime`.

- [x] **Step 4: Implement API functions**

`fetchStoreVouchers(query)` posts to `/react/v1/store-vouchers/list`.
`fetchStoreVoucherDetail(idOrCode)` gets `/react/v1/store-vouchers/{idOrCode}`.

- [x] **Step 5: Add tests**

Run: `npx --yes tsx src/modules/store-vouchers/api-normalization.test.ts`

Expected: payload filters are correct and old POS casing normalizes into the new UI shape.

### Task 4: Installment Orders Page

**Files:**
- Create: `HbwebExpoApp/app/(tabs)/installment-orders.tsx`

- [x] **Step 1: Build filter state and query flow**

Use `useStores`, `StorePickerModal`, `SelectionListModal`, `MonthDatePicker`, and `fetchInstallmentOrders`.

- [x] **Step 2: Render list cards**

Each card should include order number, `EntityTag` for branch, status badge/chip, customer phone/name when present, order time, SKU/item counts, total/discount/actual amounts, and a detail action.

- [x] **Step 3: Render detail modal**

Load `fetchInstallmentOrderDetail` on card action. Show payment records with payment method, payment time, amount, cashier, and reference. Show empty states for no records.

### Task 5: Store Vouchers Page

**Files:**
- Create: `HbwebExpoApp/app/(tabs)/store-vouchers.tsx`

- [x] **Step 1: Build filter state and query flow**

Use `useStores`, `StorePickerModal`, `SelectionListModal`, `MonthDatePicker`, and `fetchStoreVouchers`.

- [x] **Step 2: Render voucher cards**

Each card should include voucher code, branch tag, optional supplier tag if response carries supplier fields, status chip, amount/remaining amount, issue/update/expiry dates, and a detail action.

- [x] **Step 3: Render detail modal**

Load `fetchStoreVoucherDetail` on card action. Show two sections: issue/use ledger and related orders. Mark ledger actions as `issued` or `used`.

### Task 6: Navigation And I18n

**Files:**
- Modify/create all files listed in Workstream 6.

- [x] **Step 1: Register routes**

Add `installment-orders` and `store-vouchers` to Expo tabs, `TAB_PATHS`, `AppTabPath`, and `STORE_ROUTE_NAMES`.

- [x] **Step 2: Register strings**

Add `common.tabs.installmentOrders`, `common.tabs.storeVouchers`, plus screen namespaces `installmentOrders` and `storeVouchers` in Chinese and English.

- [x] **Step 3: Update tests**

Extend default route and tab grouping tests so both new routes are recognized and grouped under the Store tab when tab overflow occurs.

## Verification

- Run targeted tests:
  - `npx --yes tsx src/shared/utils/entity-color.test.ts`
  - `npx --yes tsx src/modules/installment-orders/api-normalization.test.ts`
  - `npx --yes tsx src/modules/store-vouchers/api-normalization.test.ts`
  - `npx --yes tsx src/modules/navigation/default-route.test.ts`
  - `npx --yes tsx src/components/navigation/tab-grouping.test.ts`
- Run full TypeScript check:
  - `npx tsc --noEmit`
- Smoke app startup if time permits:
  - `npx expo start --web --port <free-port>`

## Subagent Assignment

- Agent A, GPT-5.4: Task 1, shared UI foundation.
- Agent B, GPT-5.4: Task 2 and Task 3, API/types/tests only.
- Agent C, GPT-5.4: Task 6, navigation and i18n only.
- Main agent: integrate Task 4 and Task 5 pages after A/B/C land, then run verification and fix conflicts.
