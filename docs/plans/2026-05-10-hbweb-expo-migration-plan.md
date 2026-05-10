# HbwebExpo Expo 迁移实施计划 v2

> **Claude 行动计划**: 本计划按阶段推进，每个阶段可独立交付，建议使用 subagent 分阶段执行。

**目标**: 在 `d:\DevRepos\HbwebExpo` 搭建 Expo 应用，适配 iOS + Android，复用 `react-vite-admin-phase1` 的业务层代码，首期交付「Shop 订货前台 + 扫码能力」。

**架构概述**: 新建 Expo 项目，不做 Web 后台复刻。共享层抽类型/接口/业务模型，UI 层按移动端原生交互重做。后端 JWT 双令牌认证已完整支持，Expo 端直接用 Bearer Token 调用。

**技术栈**: Expo SDK 最新 · TypeScript · Expo Router · TanStack Query · Zustand · React Native Paper · Axios · js-sha256 · expo-secure-store · expo-camera · expo-clipboard · expo-av

---

## 一、Expo 项目目标目录结构

```
HbwebExpo/
├── app/                              # Expo Router 文件路由
│   ├── _layout.tsx                   # 根布局 (Paper Provider)
│   ├── index.tsx                     # 启动页 → 路由判断
│   ├── (auth)/                       # 认证流程路由组
│   │   ├── _layout.tsx               # Auth Layout
│   │   └── login.tsx                 # 登录页
│   ├── (tabs)/                       # 底部 Tab 路由组
│   │   ├── _layout.tsx               # Tab Layout
│   │   ├── home.tsx                  # 首页/商品浏览
│   │   ├── orders.tsx                # 订单历史
│   │   └── settings.tsx              # 设置/用户
│   ├── orders/                        # 堆栈路由（无 Tab）
│   │   └── [id].tsx                  # 订单详情
│   ├── product/                      # 商品详情
│   │   └── [code].tsx
│   ├── cart.tsx                      # 购物车页
│   └── scanner.tsx                   # 扫码入口页
├── src/
│   ├── shared/                        # 共享基础层
│   │   ├── api/
│   │   │   ├── client.ts             # Axios 实例 + 信封解包 + Token 拦截 + 401 刷新
│   │   │   └── error-handler.ts      # 统一错误处理
│   │   ├── constants/
│   │   │   ├── api.ts                # API Base URL、路由前缀
│   │   │   └── app.ts                # App 常量
│   │   ├── storage/
│   │   │   ├── secure.ts             # expo-secure-store 封装
│   │   │   └── async-storage.ts      # AsyncStorage 封装
│   │   ├── utils/
│   │   │   ├── format.ts             # 金额/日期/数量格式化
│   │   │   ├── barcode.ts            # EAN13 校验（纯逻辑，无 DOM 依赖）
│   │   │   ├── clipboard.ts          # expo-clipboard 封装
│   │   │   ├── password.ts           # SHA256 密码哈希（js-sha256）
│   │   │   └── access.ts             # 权限模型 buildAccess()
│   │   └── types/
│   │       └── index.ts              # ApiResponse<T>, PagedResult<T>, RequestError
│   ├── modules/                       # 业务领域模块
│   │   ├── auth/
│   │   │   ├── api.ts                # 登录/刷新/登出/当前用户
│   │   │   ├── types.ts              # LoginRequest, TokenResponse, CurrentUser, AccessControl
│   │   │   ├── use-login.ts          # 登录 Hook
│   │   │   └── use-current-user.ts   # 当前用户 Hook
│   │   ├── shop/
│   │   │   ├── api.ts                # 门店列表、商品列表、购物车
│   │   │   ├── types.ts              # Product, CartItem, CartSummary, Store
│   │   │   ├── use-stores.ts         # 门店选择 Hook
│   │   │   ├── use-products.ts       # 商品列表 Hook
│   │   │   ├── use-cart.ts           # 购物车 Hook
│   │   │   └── use-submit-order.ts   # 提交订单 Hook
│   │   ├── orders/
│   │   │   ├── api.ts                # 订单列表、订单详情
│   │   │   ├── types.ts              # Order, OrderDetail, OrderLine, StoreOrderFlowStatus
│   │   │   ├── use-orders.ts         # 订单列表 Hook
│   │   │   └── use-order-detail.ts    # 订单详情 Hook
│   │   └── scanner/
│   │       ├── api.ts                # 扫码查商品 (POST scan-lookup)
│   │       ├── types.ts              # ScanResult, ScanSource
│   │       ├── use-camera-scan.ts    # 摄像头扫码 Hook (CameraView)
│   │       ├── use-hid-scan.ts       # 蓝牙 HID 扫码 Hook
│   │       └── use-scan-result.ts    # 扫码结果处理 Hook
│   ├── components/                    # 通用 RN 组件
│   │   ├── ui/
│   │   │   ├── PageContainer.tsx     # 页面容器 (SafeArea + ScrollView)
│   │   │   ├── ProductCard.tsx       # 商品卡片
│   │   │   ├── CartItem.tsx          # 购物车行
│   │   │   ├── OrderCard.tsx         # 订单卡片
│   │   │   ├── QuantityStepper.tsx   # 数量步进器
│   │   │   ├── StoreChip.tsx         # 门店标签
│   │   │   ├── EmptyState.tsx        # 空态组件
│   │   │   ├── LoadingOverlay.tsx    # 加载遮罩
│   │   │   └── ErrorState.tsx        # 错误态组件
│   │   ├── form/
│   │   │   ├── FormTextInput.tsx     # 统一文本输入
│   │   │   └── FormPicker.tsx        # 统一选择器
│   │   └── feedback/
│   │       ├── Toast.tsx              # Toast 提示
│   │       ├── SoundFeedback.tsx     # 声音反馈
│   │       └── HapticFeedback.tsx    # 震动反馈
│   └── store/
│       ├── auth-store.ts              # 认证状态 (user, token, role, access)
│       └── cart-store.ts             # 购物车状态
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── placeholder.png
│   │   └── icons/
│   └── sounds/
│       ├── success.mp3
│       ├── error.mp3
│       └── scan.mp3
├── docs/
│   └── plans/
│       └── 2026-05-10-hbweb-expo-migration-plan.md
└── eas.json                            # EAS Build 配置
```

---

## 二、Web → Expo 模块映射表

| Web 源文件 | 迁移方向 | 复用方式 |
|-----------|---------|---------|
| `src/types/api.ts` | `src/shared/types/index.ts` | `ApiResponse<T>` + `PagedResult<T>` 直接复用 |
| `src/types/auth.ts` | `src/modules/auth/types.ts` | `LoginRequest`, `TokenResponse`, `CurrentUser`, `AccessControl` 直接复用 |
| `src/types/storeOrder.ts` | `src/modules/orders/types.ts` + `src/modules/shop/types.ts` | 按领域拆分，`StoreOrderFlowStatus` 枚举直接复用 |
| `src/types/user.ts` | `src/modules/auth/types.ts` | `UserStoreDto` 复用 |
| `src/services/auth.ts` | `src/modules/auth/api.ts` | 接口签名复用，改用 Axios |
| `src/services/storeOrderService.ts` | `src/modules/orders/api.ts` + `src/modules/shop/api.ts` | 按订单流和商品流拆分；`unwrapEnvelope` 迁入 client.ts |
| `src/store/auth.ts` | `src/store/auth-store.ts` + `src/modules/auth/` | 保留状态模型，重写持久化 |
| `src/store/shop.ts` | `src/store/cart-store.ts` + `src/modules/shop/` | 保留购物车模型，Zustand 重写 |
| `src/store/tabs.ts` | **不迁移** | RN 不需要 Tabs/KeepAlive |
| `src/utils/request.ts` | `src/shared/api/client.ts` | `unwrapApiData` / `unwrapPagedResult` 迁入，请求改用 Axios |
| `src/utils/access.ts` | `src/shared/utils/access.ts` | `buildAccess()` 完整迁移（160行），纯逻辑无 DOM 依赖 |
| `src/utils/password.ts` | `src/shared/utils/password.ts` | `CryptoJS.SHA256` → `js-sha256` 替换 |
| `src/utils/barcode.ts` | `src/shared/utils/barcode.ts` | `calculateEAN13CheckDigit` + `isValidEAN13` + `resolveBarcodeFormat` 迁入（纯逻辑），Canvas 渲染部分不迁移 |
| `src/utils/clipboard.ts` | `src/shared/utils/clipboard.ts` | 改用 expo-clipboard |
| `src/hooks/useBarcodeScanner.ts` | `src/modules/scanner/` | 摄像头扫码 + HID 扫码两套实现，不直接迁移 |
| `src/layout/ShopLayout.tsx` | `app/(tabs)/` + `app/cart.tsx` | 不复用 UI，按 RN 交互重做 |
| `src/layout/AdminLayout.tsx` | **不迁移** | 后台管理保留 Web |
| `src/layout/MobileLayout.tsx` | **不迁移** | 同上 |
| `src/pages/ShopHome/**` | `app/(tabs)/home.tsx` | 复用商品/分类业务逻辑 |
| `src/pages/ShopOrders/**` | `app/(tabs)/orders.tsx` | 复用订单列表/分页逻辑 |
| `src/pages/ShopOrderDetail/**` | `app/orders/[id].tsx` | 复用订单详情业务逻辑 |
| `src/components/ShopCartDrawer.tsx` | `app/cart.tsx` | 改用 RN Modal/Screen |
| `src/components/ShopScanBar.tsx` | `app/scanner.tsx` | 改用 expo-camera CameraView |
| `src/pages/Warehouse/StoreOrders/Detail.tsx` | **暂不迁移** | 后期移动作业版再处理 |
| `src/pages/System/**` | **不迁移** | 保留 Web |
| `src/pages/DomesticPurchase/**` | **不迁移** | 保留 Web |
| `src/pages/Warehouse/Products/**` | **不迁移** | 保留 Web |
| `src/pages/PosAdmin/**` | **不迁移** | 保留 Web |

---

## 三、后端 JWT 认证对接方案

### 认证接口（已确认后端支持）

```
POST /api/auth/login
  Body: { "username": "xxx", "password": "<SHA256哈希后的密码>" }
  Response envelope: { success: true, data: { accessToken, refreshToken, accessTokenExpiry, refreshTokenExpiry } }

POST /api/auth/refresh
  Body: { "refreshToken": "xxx" }
  Response envelope: { success: true, data: { accessToken, refreshToken, ... } }

GET /api/auth/current
  Headers: Authorization: Bearer <accessToken>
  Response envelope: { success: true, data: { userGUID, username, email, fullName, permissions[], roleNames[], stores[] } }

POST /api/auth/logout
  Headers: Authorization: Bearer <accessToken>
  Body: { "refreshToken": "xxx" }
```

### 关键细节：密码 SHA256 哈希

Web 端登录时密码经过 `CryptoJS.SHA256(password).toString()` 后再提交（见 `src/utils/password.ts`）。Expo 端必须做同样处理，否则后端验证不通过。

Expo 端使用 `js-sha256` 替代 `crypto-js`（体积更小，RN 兼容）：

```typescript
// src/shared/utils/password.ts
import { sha256 } from 'js-sha256'

export function hashPassword(password: string): string {
  return sha256(password)
}
```

### 关键细节：API 信封解包

后端所有接口返回统一信封格式 `{ success, data, message }`，部分接口甚至多层嵌套。Web 端 `storeOrderService.ts` 有 `unwrapEnvelope()` 处理此问题。Expo 端在 Axios 响应拦截器中统一解包。

### Expo 端 Token 管理策略

1. **登录时**: 密码先 SHA256 哈希 → 调用 `/api/auth/login` → 后端返回 accessToken + refreshToken。
2. **存储**: accessToken + refreshToken 均存 `expo-secure-store`（iOS Keychain / Android Keystore）。
3. **请求时**: Axios 拦截器从 secure-store 读取 accessToken，注入 `Authorization: Bearer` 请求头。
4. **401 处理**: 拦截到 401，用 refreshToken 调用 `/api/auth/refresh` 换新 accessToken；若 refreshToken 也过期，清除本地 token，跳转登录页。
5. **登出时**: 调用 `/api/auth/logout`，清除本地 token。
6. **启动时**: 先尝试从 secure-store 恢复 token，若有则调 `/api/auth/current` 验证有效性，有效直接进主页，无效进登录页。

### Expo 端请求层设计

```typescript
// src/shared/api/client.ts

// 信封解包：从 { success, data } 中提取 data
function unwrapEnvelope<T>(payload: unknown): T {
  let current = payload
  for (let depth = 0; depth < 3; depth++) {
    if (typeof current !== 'object' || current === null || !('data' in current)) break
    const keys = Object.keys(current)
    const looksLikeEnvelope = keys.includes('data') &&
      (keys.includes('success') || keys.includes('isSuccess') || keys.includes('message'))
    if (!looksLikeEnvelope) break
    current = (current as Record<string, unknown>).data
  }
  return current as T
}

// Axios 实例
const apiClient = axios.create({ baseURL: env.API_BASE_URL, timeout: 15000 })

// 请求拦截：注入 Bearer Token
apiClient.interceptors.request.use(async (config) => {
  const token = await SecureStorage.getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 响应拦截：信封解包 + 401 刷新
apiClient.interceptors.response.use(
  (response) => {
    response.data = unwrapEnvelope(response.data)
    return response
  },
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true
      const refreshed = await tryRefreshToken()
      if (refreshed) {
        error.config.headers.Authorization = `Bearer ${refreshed}`
        return apiClient(error.config)
      }
      await SecureStorage.clearAll()
      router.replace('/(auth)/login')
    }
    return Promise.reject(error)
  }
)
```

---

## 四、扫码能力设计

### 双模式扫码架构

```
┌─────────────────────────────────┐
│         ScanProvider            │  统一扫码上下文
│  ┌─────────────────────────┐   │
│  │  CameraScanController    │   │  摄像头扫码
│  │  - expo-camera CameraView │   │
│  │  - onBarcodeScanned      │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │  HidScanController       │   │  蓝牙HID/扫码枪
│  │  - TextInput onFocus     │   │
│  │  - onKeyPress 捕获       │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
         ↓ 统一回调
  onBarcodeScanned(barcode: string, source: 'camera' | 'hid')
```

### 摄像头扫码（使用 CameraView）

```typescript
// expo-camera SDK 52+ 使用 CameraView 而非旧版 BarCodeScanner
import { CameraView } from 'expo-camera'

<CameraView
  style={StyleSheet.absoluteFillObject}
  onBarcodeScanned={handleBarCodeScanned}
  barcodeScannerSettings={{
    barcodeTypes: ['ean13', 'code128', 'qr'],
  }}
/>
```

### 蓝牙 HID 扫码枪

- 扫码枪模拟键盘输入，行为等同于外接键盘
- 在全局 TextInput 上 `onKeyPress` 捕获完整条码
- 判断是否完整条码（以回车结尾 / 超时拼接）
- 支持蓝牙配对后的 HID 扫码枪

### 扫码 API（POST）

```typescript
// src/modules/scanner/api.ts
export async function scanLookup(barcode: string): Promise<StoreOrderScanLookupResult> {
  const response = await apiClient.post('/react/v1/store-order/products/scan-lookup', {
    barcode,
  })
  return {
    barcode: response.data.barcode ?? barcode,
    items: Array.isArray(response.data.items) ? response.data.items : [],
  }
}
```

### 扫码结果处理（两套共用）

```typescript
// src/modules/scanner/use-scan-result.ts
async function handleScan(barcode: string, source: 'camera' | 'hid') {
  SoundFeedback.playScan()
  const result = await scanLookup(barcode)
  if (result.items.length === 1) {
    const product = result.items[0]
    const qty = product.minOrderQuantity > 0 ? product.minOrderQuantity : 1
    await addToCart(currentStoreCode, product.productCode, qty)
    showToast('已加入购物车')
  } else if (result.items.length > 1) {
    showProductPicker(result.items)
  } else {
    SoundFeedback.playError()
    showToast('未找到商品')
  }
}
```

---

## 五、阶段任务明细

### 阶段 0：确认迁移范围（已完成）

- [x] 确认 Expo 首期只做移动端高价值场景
- [x] 确认 UI 方案：React Native Paper
- [x] 确认后端 JWT 双令牌认证已完整支持
- [x] 确认扫码方案：摄像头 + 蓝牙 HID 扫码枪
- [x] 梳理 Web 可迁移资产与迁移边界

---

### 阶段 1：Expo 基础工程搭建

**目标**: 在 `d:\DevRepos\HbwebExpo` 初始化完整的 Expo 项目，跑通 iOS/Android 双平台。

**Step 1.1: 创建 Expo 项目**（在 PowerShell 中执行）

```powershell
cd D:\DevRepos\HbwebExpo
npx create-expo-app@latest HbwebExpoApp --template blank-typescript
```

**Step 1.2: 安装核心依赖**

```powershell
cd HbwebExpoApp

# 路由 + 关联 Expo 模块
npx expo install expo-router expo-linking expo-constants expo-status-bar

# UI
npx expo install react-native-paper react-native-safe-area-context

# 数据请求
npx expo install axios @tanstack/react-query

# 状态管理
npx expo install zustand

# 表单
npx expo install react-hook-form zod @hookform/resolvers

# 存储
npx expo install expo-secure-store @react-native-async-storage/async-storage

# 设备能力
npx expo install expo-camera expo-clipboard expo-av expo-haptics expo-screen-orientation

# 密码哈希（替代 crypto-js）
npx expo install js-sha256

# Babel 路径别名
npm install --save-dev babel-plugin-module-resolver

# EAS Build（全局安装）
npm install -g eas-cli
```

> **注意**: `react-native-vector-icons` 不需要单独安装，`react-native-paper` 已依赖 `@expo/vector-icons`。
> **注意**: `expo-linking`、`expo-constants`、`expo-status-bar` 在最新 Expo SDK 中已默认包含，此处显式安装确保版本对齐。

**Step 1.3 ~ 1.7**: TypeScript、Babel、环境变量、app.json、EAS、Git 配置 → 详见初始化清单文档。

**交付物**: 可 `npx expo run:ios` / `npx expo run:android` 跑通空白壳。

---

### 阶段 2：共享层建设（Core + Auth）

**目标**: 搭建请求层、存储层、认证链路、类型迁移、权限模型，为业务模块奠基。

**Step 2.1: 目录结构搭建**

```powershell
New-Item -ItemType Directory -Force -Path src\shared\api, src\shared\constants, src\shared\storage, src\shared\utils, src\shared\types
New-Item -ItemType Directory -Force -Path src\modules\auth, src\modules\shop, src\modules\orders, src\modules\scanner
New-Item -ItemType Directory -Force -Path src\components\ui, src\components\form, src\components\feedback
New-Item -ItemType Directory -Force -Path src\store
New-Item -ItemType Directory -Force -Path assets\images\icons, assets\sounds
```

**Step 2.2: 核心类型迁移**（从 Web `src/types/api.ts` + `src/types/auth.ts`）

文件: `src/shared/types/index.ts`
- `ApiResponse<T>` — 后端统一信封结构
- `PagedResult<T>` — 分页结果结构
- `RequestError` — 请求错误类型
- `unwrapApiData<T>()` — 从信封提取 data
- `unwrapPagedResult<T>()` — 从信封提取分页数据

文件: `src/modules/auth/types.ts`
- `LoginRequest` — `{ username, password }`
- `TokenResponse` — `{ accessToken, refreshToken, accessTokenExpiry, refreshTokenExpiry, success, message }`
- `RefreshTokenRequest` — `{ accessToken, refreshToken }`
- `CurrentUser` — `{ userGUID, username, email, fullName, permissions[], roleNames[], stores[] }`
- `AccessControl` — 权限对象（30+ 个 boolean + hasPermission/hasRole 等方法）
- `UserStoreDto` — `{ storeCode, storeName }`

**Step 2.3: 权限模型迁移**（从 Web `src/utils/access.ts`）

文件: `src/shared/utils/access.ts`
- 完整迁移 `buildAccess(currentUser)` 函数（约 160 行）
- 此函数是纯逻辑，无 DOM 依赖，可直接复用
- 根据 `permissions[]` 和 `roleNames[]` 计算 30+ 个权限标志

**Step 2.4: 密码哈希迁移**（从 Web `src/utils/password.ts`）

文件: `src/shared/utils/password.ts`
- Web 端使用 `crypto-js` 的 `CryptoJS.SHA256`
- Expo 端改用 `js-sha256`（体积更小，RN 原生兼容）

```typescript
import { sha256 } from 'js-sha256'
export function hashPassword(password: string): string {
  return sha256(password)
}
```

**Step 2.5: 条码校验迁移**（从 Web `src/utils/barcode.ts`）

文件: `src/shared/utils/barcode.ts`
- 只迁移纯逻辑部分：`calculateEAN13CheckDigit`、`isValidEAN13`、`resolveBarcodeFormat`
- 不迁移 `renderBarcodeToCanvas`、`generateBarcodeDataUrl`（依赖 DOM Canvas）
- RN 端条码渲染改用 `react-native-svg` 方案（后续按需实现）

**Step 2.6: 请求层**

文件: `src/shared/api/client.ts`
- Axios 实例，baseURL 从 env 读取
- 请求拦截：注入 Bearer Token（从 SecureStore 异步读取）
- 响应拦截 1：信封解包（`unwrapEnvelope`），统一从 `response.data.data` 提取业务数据
- 响应拦截 2：401 → 加锁刷新 Token → 重试队列 → 刷新失败清除 token 跳转登录

文件: `src/shared/api/error-handler.ts`
- 统一错误归类：网络错误、401、403、500、接口业务错误
- 返回结构化错误对象

**Step 2.7: 安全存储**

文件: `src/shared/storage/secure.ts`
- `setToken` / `getToken` / `removeToken`
- `setRefreshToken` / `getRefreshToken` / `removeRefreshToken`
- `setUser` / `getUser<T>` / `clearAll`

文件: `src/shared/storage/async-storage.ts`
- `setObject(key, value)` / `getObject<T>(key)`
- 用于非敏感缓存（筛选偏好、购物车快照、记住用户名）

**Step 2.8: 认证模块**

文件: `src/modules/auth/api.ts`
- `login(username, password)` → 密码先 SHA256 哈希 → POST `/api/auth/login`
- `refreshToken(refreshToken)` → POST `/api/auth/refresh`
- `getCurrentUser()` → GET `/api/auth/current`
- `logout(refreshToken)` → POST `/api/auth/logout`

文件: `src/store/auth-store.ts`
- Zustand store：保存 user、access (AccessControl)、isAuthenticated
- `login(payload)` → 哈希密码 → 调 API → 存 token → 获取用户 → 计算权限
- `logout()` → 调 API → 清 token
- `restoreSession()` → 读 token → 调 current → 恢复状态
- `refreshUser()` → 重新获取用户信息

文件: `src/modules/auth/use-login.ts`
- React Hook：`const { login, isLoading, error } = useLogin()`
- 整合表单提交、密码哈希、API 调用、状态更新、token 存储

文件: `src/modules/auth/use-current-user.ts`
- React Hook：TanStack Query 缓存当前用户信息

**Step 2.9: 基础组件**

文件: `src/components/ui/PageContainer.tsx` — SafeAreaView + ScrollView
文件: `src/components/feedback/Toast.tsx` — 全局 Snackbar
文件: `src/components/feedback/SoundFeedback.tsx` — expo-av 声音反馈

**交付物**: 请求层可正常解包信封、注入 Token、401 自动刷新；登录页可跑通。

---

### 阶段 3：登录页实现

**目标**: 完成用户登录全链路，包含 Splash → Login → Session 恢复。

**Step 3.1: 路由配置**

文件: `app/_layout.tsx`（根布局）
- Paper Provider + SafeAreaProvider + QueryClientProvider 包裹
- Stack 路由，headerShown: false

文件: `app/index.tsx`（启动页）
- 从 SecureStore 读 token
- 有 token → 调 `/api/auth/current` 验证 → 成功进首页 / 失败进登录
- 无 token → 进登录页

文件: `app/(auth)/_layout.tsx` — 认证路由组布局

文件: `app/(auth)/login.tsx`
- 用户名输入 + 密码输入 + 登录按钮
- 密码提交前先 SHA256 哈希
- 错误提示 Snackbar
- 记住用户名功能（用 AsyncStorage 存 `remembered_username`）

**Step 3.2: 登录页 UI**

使用 React Native Paper 组件（注意 `Text` 和 `TextInput` 从 `react-native-paper` 导入）：
- `TextInput`（用户名，mode="outlined"）
- `TextInput`（密码，secureTextEntry，mode="outlined"）
- `Checkbox`（记住用户名）
- `Button`（登录，mode="contained"，loading 状态）
- `Snackbar`（错误提示）

**交付物**: 输入正确账号可登录成功，进入首页；Token 正确存储，下次冷启动自动恢复会话。

---

### 阶段 4：门店选择 + Shop 首页

**目标**: 完成门店切换和商品列表浏览。

**Step 4.1: 门店 + 商品 API**

文件: `src/modules/shop/api.ts`
- `getAccessibleStores()` → GET `/api/react/v1/store-order/accessible-branches`
- `getProducts(query)` → POST `/api/react/v1/store-order/products`
  - query: `{ storeCode, itemNumber?, productName?, categoryGUID?, pageNumber, pageSize }`
  - 返回: `StoreOrderProductListResult`（信封已由 client.ts 解包）

**Step 4.2: 商品 + 门店类型**

文件: `src/modules/shop/types.ts`
- `Store` — 从 `UserStoreDto` 映射
- `StoreOrderProductItem` — 商品信息（含 productCode, itemNumber, barcode, productName, productImage, oemPrice, minOrderQuantity, stockQuantity, isInStock, importPrice）
- `StoreOrderProductListResult` — `{ items, total, page, pageSize }`
- `StoreOrderDynamicData` — `{ productCode, lastOrderDate, lastQuantity, cartQuantity }`

**Step 4.3: 门店选择 Hook**

文件: `src/modules/shop/use-stores.ts`
- TanStack Query 获取可用门店
- 当前选中门店保存到 AsyncStorage

文件: `src/store/cart-store.ts`
- Zustand：当前门店 Code + 购物车快照

**Step 4.4: 商品列表 Hook**

文件: `src/modules/shop/use-products.ts`
- TanStack Query 封装商品列表请求
- 支持分类筛选、货号搜索
- `staleTime: 5 * 60 * 1000`

**Step 4.5: 首页 UI**

文件: `app/(tabs)/home.tsx`

布局：
- 顶部：`StoreChip`（当前分店，点击切换） + 搜索框
- 分类横向滚动
- 商品网格（2列），`ProductCard` 组件
- 右下角：`FAB`（扫码入口）+ 购物车浮球（显示数量 badge）

`ProductCard` 组件：
- 商品图片（`Image` source={uri}，fallback placeholder）
- 商品名、规格
- 价格
- 加入购物车按钮（`QuantityStepper`）

**交付物**: 选择分店后可浏览商品，支持搜索和分类筛选，点击商品可加入购物车。

---

### 阶段 5：购物车 + 订单提交

**目标**: 完成购物车全流程和订单提交。

**Step 5.1: 购物车 API**（参数与后端对齐）

文件: `src/modules/shop/api.ts` 补充：
- `getCart(storeCode)` → GET `/api/react/v1/store-order/cart/{storeCode}`
- `addToCart(storeCode, productCode, quantity)` → POST `/api/react/v1/store-order/cart/add`，body: `{ storeCode, productCode, quantity }`
- `updateCartItem(storeCode, productCode, quantity)` → POST `/api/react/v1/store-order/cart/update`，body: `{ storeCode, productCode, quantity }`
- `removeCartItem(storeCode, detailGUID)` → POST `/api/react/v1/store-order/cart/remove`，body: `{ storeCode, detailGUID }`
- `clearCart(storeCode)` → POST `/api/react/v1/store-order/cart/clear`，body: `{ storeCode }`
- `submitOrder(storeCode, remarks?)` → POST `/api/react/v1/store-order/submit`，body: `{ storeCode, remarks }`

> **注意**: 购物车接口全部以 `storeCode` 为核心参数，不是 `cartGuid`。后端根据 storeCode 自动查找或创建当前用户的购物车。

**Step 5.2: 购物车类型**

文件: `src/modules/shop/types.ts` 补充：
- `StoreOrderCartItem` — 购物车行（含 detailGUID, productCode, productName, price, quantity, minOrderQuantity）
- `StoreOrderCart` — 购物车整体（含 items[], totalAmount, totalQuantity, totalImportAmount, totalVolume）
- `StoreOrderFlowStatus` — 枚举（ShoppingCart=0, Submitted=1, Completed=2, Picking=3）

**Step 5.3: 购物车 Hook**

文件: `src/modules/shop/use-cart.ts`
- TanStack Query 管理购物车状态
- `addItem(productCode, quantity)` / `updateQuantity(productCode, quantity)` / `removeItem(detailGUID)` / `clearCart()`

**Step 5.4: 购物车页**

文件: `app/cart.tsx`

布局：
- 顶部：门店标签 + 清空按钮
- FlatList：`CartItem` 组件（图片 + 名称 + 单价 + QuantityStepper + 删除按钮）
- 底部固定栏：`OrderSummary`（总数量 + 总金额）+ 提交按钮

**Step 5.5: 提交订单 Hook**

文件: `src/modules/shop/use-submit-order.ts`
- 提交前 Paper Dialog 确认弹窗
- 调用 submitOrder API
- 成功后清空购物车 query cache + 跳转订单详情

**交付物**: 购物车增删改可实时同步到后端，提交订单成功跳转详情。

---

### 阶段 6：订单历史 + 订单详情

**目标**: 完成订单列表浏览和订单详情查看。

**Step 6.1: 订单 API**

文件: `src/modules/orders/api.ts`
- `getOrders(query)` → POST `/api/react/v1/store-order/list`
  - query: `{ keyword?, storeCodes?, startDate?, endDate?, statusList?, pageNumber, pageSize, sortBy?, sortDescending? }`
  - 返回: `StoreOrderListResult`
- `getOrderDetail(orderGuid)` → GET `/api/react/v1/store-order/detail/{orderGuid}`

**Step 6.2: 订单类型**

文件: `src/modules/orders/types.ts`
- `StoreOrderFlowStatus` — 枚举（ShoppingCart=0, Submitted=1, Completed=2, Picking=3）
- `StoreOrderStatusOption` — `{ value, label, color }` + `StoreOrderStatusOptions[]` + `StoreOrderStatusLabelMap` + `StoreOrderStatusColorMap`
- `StoreOrderListItem` — 订单概要
- `StoreOrderListResult` — `{ items, total, page, pageSize }`
- `StoreOrderDetail` — 订单详情（含 items: StoreOrderDetailLine[]）
- `StoreOrderDetailLine` — 订单行

> **注意**: `StoreOrderFlowStatus`、`StoreOrderStatusOptions`、`StoreOrderStatusLabelMap` 等直接从 Web `src/types/storeOrder.ts` 迁移，用于订单列表状态标签渲染。

**Step 6.3: 订单列表 Hook**

文件: `src/modules/orders/use-orders.ts`
- TanStack Query 封装
- 支持分页加载
- `staleTime: 1 * 60 * 1000`

**Step 6.4: 订单列表页**

文件: `app/(tabs)/orders.tsx`

布局：
- 顶部：`SegmentedButtons`（全部 / 已提交 / 配货中 / 已完成）
- FlatList 订单卡片列表
- `OrderCard` 组件
- `onEndReached` 分页加载

`OrderCard` 组件：
- 订单编号 + 门店 + 时间
- 商品数量 + 总金额
- 状态标签（使用 `StoreOrderStatusColorMap` 映射颜色）
- 点击 → 跳转订单详情

**Step 6.5: 订单详情页**

文件: `app/orders/[id].tsx`

布局：
- 顶部：`Appbar.Header` 返回 + 订单编号
- 基本信息：`StoreChip` + 下单时间 + 状态 Badge
- 商品 FlatList：`OrderLine` 卡片
- 底部：`OrderSummary`（总数量 + 总体积 + 总金额）

**交付物**: 可查看订单历史和详情，支持下拉刷新和分页。

---

### 阶段 7：扫码能力

**目标**: 完成摄像头扫码 + 蓝牙 HID 扫码枪双模式。

**Step 7.1: 扫码类型**

文件: `src/modules/scanner/types.ts`
- `StoreOrderScanLookupResult` — `{ barcode, items: StoreOrderProductItem[] }`
- `StoreOrderScanStatus` — `'ready' | 'scanning' | 'added' | 'multiple' | 'not_found' | 'blocked' | 'error'`
- `ScanSource` — `'camera' | 'hid'`

**Step 7.2: 扫码 API**

文件: `src/modules/scanner/api.ts`
- `scanLookup(barcode)` → **POST** `/api/react/v1/store-order/products/scan-lookup`
- Body: `{ barcode: string }`
- 返回: `{ barcode, items: StoreOrderProductItem[] }`（信封已由 client.ts 解包）

**Step 7.3: 摄像头扫码 Hook**（使用 CameraView）

文件: `src/modules/scanner/use-camera-scan.ts`
- 封装 `expo-camera` 的 `CameraView` 组件
- 请求 Camera 权限（`Camera.requestCameraPermissionsAsync()`）
- 监听 `onBarcodeScanned` 回调
- 防抖处理（`scannedRef` 标志 + setTimeout 重置，避免同一码短时间重复触发）
- 限制条码类型：`barcodeTypes: ['ean13', 'code128', 'qr']`
- 返回 `{ hasPermission, requestPermission, onBarcodeScanned }`

**Step 7.4: HID 扫码 Hook**

文件: `src/modules/scanner/use-hid-scan.ts`
- 全局 TextInput `onKeyPress` 捕获
- 拼接完整条码（以 `\n` 或 `\r` 结尾视为完整）
- 超时拼接（500ms 无新字符则视为完整条码）
- 返回 `{ inputRef, isListening, startListening, stopListening }`

**Step 7.5: 扫码结果处理**

文件: `src/modules/scanner/use-scan-result.ts`
- 统一的扫码结果处理逻辑
- 单结果 → 直接加购 + Toast + 震动
- 多结果 → 弹出 Paper BottomSheet 选择器
- 无结果 → 错误提示 + 错误音

**Step 7.6: 扫码入口页**

文件: `app/scanner.tsx`

布局：
- 全屏 CameraView 预览（`barcodeScannerSettings: { barcodeTypes: ['ean13', 'code128', 'qr'] }`）
- 顶部：`Appbar` 返回按钮 + 手电筒开关
- 底部：`SegmentedButtons` 模式切换（摄像头 / HID）
- 中间：扫码框 + 提示文字

HID 模式：
- 隐藏摄像头预览
- 显示「请使用扫码枪扫描」提示
- 底部隐藏 TextInput 接收 HID 输入

**交付物**: 摄像头可扫描商品条码，HID 扫码枪可正常输入并识别，支持扫码结果直接加购。

---

### 阶段 8：全局收口

**Step 8.1: 统一错误态**

文件: `src/components/ui/ErrorState.tsx`
- 网络错误 / 接口错误 / 无数据 三种状态
- 重试按钮

**Step 8.2: 空态组件**

文件: `src/components/ui/EmptyState.tsx`
- 购物车空态 / 订单空态 / 搜索无结果

**Step 8.3: 离线提示**

使用 `@react-native-community/netinfo`，在网络断开时显示顶部 Banner。

```powershell
npx expo install @react-native-community/netinfo
```

**Step 8.4: 声音反馈完善**

`assets/sounds/` 放入 success.mp3 / error.mp3 / scan.mp3。

**Step 8.5: 启动图 + 图标**

准备 `assets/images/` 下的图标和启动图。

---

### 阶段 9：测试与构建

**Step 9.1: 类型检查**

```powershell
npx tsc --noEmit
```

**Step 9.2: iOS 构建**

```powershell
eas build --profile preview --platform ios
```

**Step 9.3: Android 构建**

```powershell
eas build --profile preview --platform android
```

**Step 9.4: 真机联调清单**

- [ ] 登录：正常登录 / 密码哈希正确 / Token 过期刷新 / 登出
- [ ] 门店切换：切换后商品列表刷新
- [ ] 商品浏览：列表加载 / 分类筛选 / 搜索
- [ ] 购物车：增 / 删 / 改 / 清空 / 提交（参数与后端对齐）
- [ ] 订单：列表加载 / 分页 / 详情查看 / 状态标签正确
- [ ] 摄像头扫码：CameraView 正常扫码 + 无结果提示
- [ ] HID 扫码：扫码枪输入 + 识别 + 加购
- [ ] 离线：网络断开 Banner 显示
- [ ] 声音：扫码提示音播放
- [ ] 信封解包：接口返回 data 正确提取
- [ ] 权限：非管理员只能看到自己门店

---

## 六、优先级汇总

| 阶段 | 内容 | 优先级 |
|------|------|--------|
| 1 | Expo 基础工程 | P0 |
| 2 | 共享层（请求 + 存储 + 认证 + 类型 + 权限 + 哈希） | P0 |
| 3 | 登录页 + Session 恢复 | P0 |
| 4 | 门店选择 + Shop 首页 | P1 |
| 5 | 购物车 + 订单提交 | P1 |
| 6 | 订单历史 + 订单详情 | P1 |
| 7 | 扫码能力（摄像头 CameraView + HID） | P1 |
| 8 | 全局收口（错误态 / 空态 / 离线） | P2 |
| 9 | 测试 + iOS/Android 构建 | P2 |

**预计交付周期**: 6~8 周（可并行执行不同阶段）

---

## 七、关键风险与缓解

| 风险 | 影响 | 缓解方案 |
|------|------|---------|
| 后端 CORS 配置 | 移动端请求被拒 | 移动端不走浏览器，无 CORS 限制（原生 HTTP 请求）；但 Expo Go 开发模式下走 Metro 代理需确认 |
| 密码哈希不一致 | 登录失败 | 必须使用 `js-sha256`，与 Web 端 `CryptoJS.SHA256` 输出一致 |
| 信封嵌套 | 数据取不到 | client.ts 统一 `unwrapEnvelope` 最多解包 3 层 |
| 扫码枪兼容 | 部分 HID 扫码枪行为不一致 | 分型号测试，收敛到标准键盘输入模式 |
| Token 刷新竞态 | 并发请求在 Token 刷新时失败 | 请求拦截器加锁 + 队列，只允许一个刷新请求 |
| 弱网体验 | 商品列表/订单加载慢 | TanStack Query 缓存 + staleTime + placeholderData |
| expo-camera API 变更 | BarCodeScanner 已废弃 | 使用 CameraView + onBarcodeScanned + barcodeScannerSettings |
| Android 模拟器 localhost | API 地址不同 | Android 模拟器用 `10.0.2.2`，iOS 模拟器用 `localhost`，通过 `.env.local` 覆盖 |
