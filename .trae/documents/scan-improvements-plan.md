# 扫码功能改进计划

## 问题分析

用户提出 4 个需求：

### 1. 商品页添加扫码重置功能按钮
- 当前已有 `filter-remove-outline` 清除过滤按钮，但只在有 `scannedProductCodes` 过滤条件时显示
- 需要：常驻的"扫码重置"按钮，清除扫码过滤并恢复默认商品列表

### 2. 扫码页面打开后扫码没有响应，只有点击搜索框后才有
- **根因**：当前使用隐藏 `TextInput` + `focus()` 方案接收 HID 扫码枪输入
- 页面加载或 Tab 切换后焦点可能不在隐藏输入框上，导致扫码无响应
- 只有手动点击搜索框触发某些操作后，`armHiddenScannerInput` 才有机会重新聚焦

### 3. 商品页和购物车页默认激活扫码查询功能
- 同根因：依赖隐藏输入框的焦点状态

### 4. 购物车取消扫码加购按钮（开摄像头）
- 购物车移除相机扫码，只保留 HID 扫码枪

## 技术方案：用 `expo-key-event` 替代隐藏 TextInput

参考 Web 端 `useBarcodeScanner` 的全局键盘监听方案，在 React Native 中使用 `expo-key-event` 实现类似的无焦点扫码。

### 为什么比隐藏 TextInput 方案更好
| 对比 | 隐藏 TextInput（当前） | expo-key-event（新方案） |
|------|----------------------|------------------------|
| 焦点依赖 | 必须保持焦点在隐藏输入框 | 无焦点依赖，全局监听 |
| 与搜索框冲突 | 搜索框抢走焦点后扫码失效 | 搜索框有焦点时仍能接收扫码枪输入 |
| Tab 切换 | 需 useFocusEffect 重新聚焦 | 页面 mount 即生效 |
| 可靠性 | 焦点被系统弹窗等抢走后失效 | 不受 UI 状态影响 |

### expo-key-event 兼容性
- 项目当前 Expo SDK 54，`expo-key-event` 要求 SDK 52+，完全兼容
- 支持 iOS / Android / Web

## 实施步骤

### Step 1: 安装 expo-key-event
- `npx expo install expo-key-event`
- 运行 `npx expo prebuild`（如需原生构建）

### Step 2: 新建 `useHidBarcodeScanner` hook
- 文件：`src/modules/scanner/use-hid-barcode-scanner.ts`
- 参考 Web 端 `useBarcodeScanner` 的缓冲 + 超时逻辑
- 使用 `expo-key-event` 的 `useKeyEventListener` 全局监听按键
- 内部维护字符缓冲区，按 `idleMs` 超时后自动提交条码
- 检测当前焦点是否在可编辑元素（TextInput），如果是则跳过（避免干扰正常输入）
- 接口参数：`{ enabled, idleMs, minLength, onScan }`

### Step 3: 改造商品页（home.tsx）
1. **替换扫码 hook**：删除 `useHidScan` + 隐藏 `TextInput` + `armHiddenScannerInput`，改用新的 `useHidBarcodeScanner`
2. **添加扫码重置按钮**：在搜索行添加常驻的"扫码重置"按钮（`filter-remove-outline`），点击后清除 `scannedProductCodes`、`searchInput`、`keyword`
3. **保留相机扫码**：商品页保留相机扫码功能不变
4. **删除焦点管理相关代码**：移除 `hidInputRef`、`armHiddenScannerInput`、隐藏 `TextInput` 及相关 useEffect

### Step 4: 改造购物车页（cart.tsx）
1. **替换扫码 hook**：同上，删除 `useHidScan` + 隐藏 `TextInput`，改用 `useHidBarcodeScanner`
2. **移除相机扫码**：删除 `useCameraScan`、`cameraVisible` 状态、相机弹窗（Modal + CameraView）、"扫码加购"按钮
3. **删除焦点管理相关代码**：同上
4. **删除 camera 相关 import**：`CameraView`、`Modal`、`Portal`（如不再使用）

### Step 5: 清理旧代码
- 评估 `use-hid-scan.ts` 是否仍被其他页面引用，如果不再使用可以删除
- 保留 `use-camera-scan.ts`（商品页仍在使用）

## 涉及文件
| 文件 | 操作 |
|------|------|
| `src/modules/scanner/use-hid-barcode-scanner.ts` | **新建** — 无焦点扫码 hook |
| `app/(tabs)/home.tsx` | **修改** — 替换扫码方案 + 添加重置按钮 |
| `app/(tabs)/cart.tsx` | **修改** — 替换扫码方案 + 移除相机扫码 |
| `src/modules/scanner/use-hid-scan.ts` | **评估** — 不再使用则删除 |
| `package.json` | **修改** — 新增 expo-key-event 依赖 |
