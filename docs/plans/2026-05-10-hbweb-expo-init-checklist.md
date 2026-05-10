# HbwebExpo Expo 项目初始化清单与命令方案 v2

> 本文档是「阶段 1：Expo 基础工程搭建」的完整执行手册。
> **所有命令均为 PowerShell 兼容格式**，直接在 Windows PowerShell 中执行。

---

## 准备工作

### 环境检查

```powershell
node --version
# 期望：v18.x.x 或更高

npm --version
# 期望：9.x.x 或更高

git --version
# 期望：git version 2.x.x

npx expo --version
# 如未安装会自动下载
```

---

## Step 1：创建 Expo 项目

### 1.1 执行创建命令

```powershell
cd D:\DevRepos\HbwebExpo
npx create-expo-app@latest HbwebExpoApp --template blank-typescript
```

等待依赖安装完成（约 2~5 分钟）。

### 1.2 验证创建成功

```powershell
cd D:\DevRepos\HbwebExpo\HbwebExpoApp
Get-ChildItem
```

**期望看到**：`.gitignore`、`app.json`、`package.json`、`tsconfig.json`、`assets/`、`App.tsx` 等文件。

---

## Step 2：安装核心依赖

> 以下命令均在 `D:\DevRepos\HbwebExpo\HbwebExpoApp` 目录下执行。

### 2.1 路由 + Expo 关联模块

```powershell
npx expo install expo-router expo-linking expo-constants expo-status-bar
```

### 2.2 UI 组件库

```powershell
npx expo install react-native-paper react-native-safe-area-context
```

> **注意**: 不需要单独安装 `react-native-vector-icons`，`react-native-paper` 已依赖 `@expo/vector-icons`。

### 2.3 数据请求

```powershell
npx expo install axios @tanstack/react-query
```

### 2.4 状态管理

```powershell
npx expo install zustand
```

### 2.5 表单

```powershell
npx expo install react-hook-form zod @hookform/resolvers
```

### 2.6 存储

```powershell
npx expo install expo-secure-store @react-native-async-storage/async-storage
```

### 2.7 设备能力

```powershell
npx expo install expo-camera expo-clipboard expo-av expo-haptics expo-screen-orientation
```

### 2.8 密码哈希（替代 crypto-js）

```powershell
npx expo install js-sha256
```

### 2.9 开发工具

```powershell
npm install --save-dev babel-plugin-module-resolver
npm install -g eas-cli
```

### 2.10 验证依赖

```powershell
Get-Content package.json | Select-String "expo-router|react-native-paper|axios|tanstack|zustand|expo-camera|expo-secure-store|js-sha256"
```

---

## Step 3：配置 TypeScript

### 3.1 更新 tsconfig.json

```powershell
Set-Content -Path tsconfig.json -Value @'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@modules/*": ["src/modules/*"],
      "@components/*": ["src/components/*"],
      "@store/*": ["src/store/*"],
      "@assets/*": ["assets/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"]
}
'@
```

---

## Step 4：配置 Babel

### 4.1 更新 babel.config.js

```powershell
Set-Content -Path babel.config.js -Value @'
module.exports = function (api) {
  api.cache(true)
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      [
        'module-resolver',
        {
          root: ['./'],
          alias: {
            '@': './src',
            '@shared': './src/shared',
            '@modules': './src/modules',
            '@components': './src/components',
            '@store': './src/store',
            '@assets': './assets',
          },
        },
      ],
    ],
  }
}
'@
```

---

## Step 5：配置环境变量

### 5.1 创建 .env.development

> **平台差异**: Android 模拟器访问宿主机用 `10.0.2.2`，iOS 模拟器用 `localhost`。开发时默认用 `localhost`，Android 真机测试时创建 `.env.local` 覆盖。

```powershell
Set-Content -Path .env.development -Value @'
EXPO_PUBLIC_API_BASE_URL=http://localhost:5000/api
EXPO_PUBLIC_APP_ENV=development
'@
```

### 5.2 创建 .env.production

```powershell
Set-Content -Path .env.production -Value @'
EXPO_PUBLIC_API_BASE_URL=https://your-production-api.com/api
EXPO_PUBLIC_APP_ENV=production
'@
```

### 5.3（可选）Android 模拟器专用

```powershell
Set-Content -Path .env.local -Value @'
EXPO_PUBLIC_API_BASE_URL=http://10.0.2.2:5000/api
'@
```

---

## Step 6：配置 app.json

```powershell
Set-Content -Path app.json -Value @'
{
  "expo": {
    "name": "HbwebExpo",
    "slug": "hbweb-expo",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/images/icon.png",
    "scheme": "hbwebexpo",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/images/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": false,
      "bundleIdentifier": "com.hbweb.expo",
      "infoPlist": {
        "NSCameraUsageDescription": "Used for scanning product barcodes",
        "NSMicrophoneUsageDescription": "Used for audio feedback"
      }
    },
    "android": {
      "package": "com.hbweb.expo",
      "adaptiveIcon": {
        "foregroundImage": "./assets/images/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "permissions": ["CAMERA", "RECORD_AUDIO", "VIBRATE"]
    },
    "plugins": [
      "expo-router",
      [
        "expo-camera",
        {
          "cameraPermission": "Used for scanning product barcodes"
        }
      ]
    ],
    "experiments": {
      "typedRoutes": true
    }
  }
}
'@
```

---

## Step 7：配置 EAS Build

```powershell
Set-Content -Path eas.json -Value @'
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "android": {
        "buildType": "apk"
      }
    },
    "production": {
      "android": {
        "buildType": "apk"
      }
    }
  }
}
'@
```

---

## Step 8：创建目录结构

```powershell
$dirs = @(
  'src\shared\api', 'src\shared\constants', 'src\shared\storage', 'src\shared\utils', 'src\shared\types',
  'src\modules\auth', 'src\modules\shop', 'src\modules\orders', 'src\modules\scanner',
  'src\components\ui', 'src\components\form', 'src\components\feedback',
  'src\store',
  'assets\images\icons', 'assets\sounds',
  'docs\plans'
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
Write-Host "Directories created."
```

验证：

```powershell
Get-ChildItem -Path src -Directory -Recurse | Select-Object FullName
```

---

## Step 9：配置 Expo Router（替换 App.tsx）

### 9.1 删除旧的 App.tsx 并创建 app/ 目录

```powershell
Remove-Item App.tsx -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path app | Out-Null
```

### 9.2 创建根布局 app/_layout.tsx

```powershell
Set-Content -Path app\_layout.tsx -Value @'
import { Stack } from 'expo-router'
import { PaperProvider, MD3LightTheme } from 'react-native-paper'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StatusBar } from 'expo-status-bar'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 1,
    },
  },
})

const theme = {
  ...MD3LightTheme,
  colors: {
    ...MD3LightTheme.colors,
    primary: '#1677FF',
    secondary: '#52C41A',
    error: '#FF4D4F',
  },
}

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <PaperProvider theme={theme}>
          <StatusBar style="auto" />
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="index" />
            <Stack.Screen name="(auth)" />
            <Stack.Screen name="(tabs)" />
            <Stack.Screen name="cart" />
            <Stack.Screen name="scanner" />
            <Stack.Screen name="orders" />
          </Stack>
        </PaperProvider>
      </QueryClientProvider>
    </SafeAreaProvider>
  )
}
'@
```

### 9.3 创建启动页 app/index.tsx

```powershell
Set-Content -Path app\index.tsx -Value @'
import { useEffect, useState } from 'react'
import { router } from 'expo-router'
import { View, ActivityIndicator, Text } from 'react-native'
import { SecureStorage } from '@/shared/storage/secure'
import { apiClient } from '@/shared/api/client'

export default function Index() {
  const [status, setStatus] = useState<'checking' | 'redirecting'>('checking')

  useEffect(() => {
    checkAuth()
  }, [])

  async function checkAuth() {
    setStatus('redirecting')
    try {
      const token = await SecureStorage.getToken()
      if (!token) {
        router.replace('/(auth)/login')
        return
      }
      await apiClient.get('/api/auth/current')
      router.replace('/(tabs)/home')
    } catch {
      await SecureStorage.clearAll()
      router.replace('/(auth)/login')
    }
  }

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#fff' }}>
      <ActivityIndicator size="large" color="#1677FF" />
      <Text style={{ marginTop: 12, color: '#666' }}>Loading...</Text>
    </View>
  )
}
'@
```

### 9.4 创建认证路由组

```powershell
New-Item -ItemType Directory -Force -Path "app\(auth)" | Out-Null

Set-Content -Path "app\(auth)\_layout.tsx" -Value @'
import { Stack } from 'expo-router'

export default function AuthLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="login" />
    </Stack>
  )
}
'@

Set-Content -Path "app\(auth)\login.tsx" -Value @'
import { useRouter } from 'expo-router'
import { View, StyleSheet } from 'react-native'
import { TextInput, Button, Text, Surface, Checkbox, Snackbar } from 'react-native-paper'
import { useState } from 'react'
import { useAuthStore } from '@/store/auth-store'
import { SecureStorage } from '@/shared/storage/secure'
import { AppAsyncStorage } from '@/shared/storage/async-storage'

const REMEMBERED_USERNAME_KEY = 'remembered_username'

export default function Login() {
  const router = useRouter()
  const login = useAuthStore((s) => s.login)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [rememberUsername, setRememberUsername] = useState(false)
  const [snackbarVisible, setSnackbarVisible] = useState(false)

  useEffect(() => {
    loadRememberedUsername()
  }, [])

  async function loadRememberedUsername() {
    const saved = await AppAsyncStorage.getString(REMEMBERED_USERNAME_KEY)
    if (saved) {
      setUsername(saved)
      setRememberUsername(true)
    }
  }

  async function handleLogin() {
    setError('')
    setLoading(true)
    try {
      await login({ username, password })
      if (rememberUsername && username) {
        await AppAsyncStorage.setString(REMEMBERED_USERNAME_KEY, username)
      } else {
        await AppAsyncStorage.removeItem(REMEMBERED_USERNAME_KEY)
      }
      router.replace('/(tabs)/home')
    } catch (e: any) {
      const msg = e?.response?.data?.message || e?.message || 'Login failed'
      setError(msg)
      setSnackbarVisible(true)
    } finally {
      setLoading(false)
    }
  }

  return (
    <View style={styles.container}>
      <Surface style={styles.card} elevation={2}>
        <Text variant="headlineMedium" style={styles.title}>HbwebExpo</Text>
        <Text variant="bodyMedium" style={styles.subtitle}>Store Order System</Text>
        <TextInput label="Username" value={username} onChangeText={setUsername} style={styles.input} mode="outlined" autoCapitalize="none" />
        <TextInput label="Password" value={password} onChangeText={setPassword} style={styles.input} mode="outlined" secureTextEntry />
        <Checkbox.Item label="Remember username" status={rememberUsername ? 'checked' : 'unchecked'} onPress={() => setRememberUsername(!rememberUsername)} />
        <Button mode="contained" onPress={handleLogin} loading={loading} disabled={loading || !username || !password} style={styles.button}>Login</Button>
      </Surface>
      <Snackbar visible={snackbarVisible} onDismiss={() => setSnackbarVisible(false)} duration={3000}>{error}</Snackbar>
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#f5f5f5' },
  card: { padding: 24, borderRadius: 12 },
  title: { textAlign: 'center', fontWeight: 'bold' },
  subtitle: { textAlign: 'center', marginBottom: 24, color: '#666' },
  input: { marginBottom: 16 },
  button: { marginTop: 8 },
})
'@
```

> **注意**: 上述 login.tsx 中导入了 `useEffect` 但未在 import 语句中包含，实际编码时需补充 `import { useState, useEffect } from 'react'`。此处为占位代码，后续阶段实现时会完善。

### 9.5 创建 Tab 路由组

```powershell
New-Item -ItemType Directory -Force -Path "app\(tabs)" | Out-Null

Set-Content -Path "app\(tabs)\_layout.tsx" -Value @'
import { Tabs } from 'expo-router'
import { MaterialCommunityIcons } from '@expo/vector-icons'

export default function TabsLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="home" options={{ title: 'Home', tabBarIcon: ({ color, size }) => <MaterialCommunityIcons name="home" color={color} size={size} /> }} />
      <Tabs.Screen name="orders" options={{ title: 'Orders', tabBarIcon: ({ color, size }) => <MaterialCommunityIcons name="clipboard-list" color={color} size={size} /> }} />
      <Tabs.Screen name="settings" options={{ title: 'Settings', tabBarIcon: ({ color, size }) => <MaterialCommunityIcons name="cog" color={color} size={size} /> }} />
    </Tabs>
  )
}
'@

Set-Content -Path "app\(tabs)\home.tsx" -Value @'
import { View, StyleSheet } from 'react-native'
import { Text } from 'react-native-paper'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function Home() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text variant="headlineSmall">Shop Home</Text>
        <Text variant="bodyMedium" style={styles.placeholder}>Products / Categories / Search - Coming soon</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  placeholder: { marginTop: 8, color: '#999' },
})
'@

Set-Content -Path "app\(tabs)\orders.tsx" -Value @'
import { View, StyleSheet } from 'react-native'
import { Text } from 'react-native-paper'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function Orders() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text variant="headlineSmall">Order History</Text>
        <Text variant="bodyMedium" style={styles.placeholder}>Order list / detail - Coming soon</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  placeholder: { marginTop: 8, color: '#999' },
})
'@

Set-Content -Path "app\(tabs)\settings.tsx" -Value @'
import { View, StyleSheet } from 'react-native'
import { Text } from 'react-native-paper'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function Settings() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text variant="headlineSmall">Settings</Text>
        <Text variant="bodyMedium" style={styles.placeholder}>User info / Logout - Coming soon</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  placeholder: { marginTop: 8, color: '#999' },
})
'@
```

> **注意**: `Text` 组件从 `react-native-paper` 导入（支持 `variant` 属性），不从 `react-native` 导入。

---

## Step 10：创建共享层占位符

### 10.1 SecureStorage

```powershell
Set-Content -Path src\shared\storage\secure.ts -Value @'
import * as SecureStore from "expo-secure-store"

const KEYS = {
  ACCESS_TOKEN: "hbweb_access_token",
  REFRESH_TOKEN: "hbweb_refresh_token",
  USER: "hbweb_user",
} as const

export const SecureStorage = {
  async setToken(token: string) { await SecureStore.setItemAsync(KEYS.ACCESS_TOKEN, token) },
  async getToken() { return SecureStore.getItemAsync(KEYS.ACCESS_TOKEN) },
  async removeToken() { await SecureStore.deleteItemAsync(KEYS.ACCESS_TOKEN) },
  async setRefreshToken(token: string) { await SecureStore.setItemAsync(KEYS.REFRESH_TOKEN, token) },
  async getRefreshToken() { return SecureStore.getItemAsync(KEYS.REFRESH_TOKEN) },
  async removeRefreshToken() { await SecureStore.deleteItemAsync(KEYS.REFRESH_TOKEN) },
  async setUser(user: object) { await SecureStore.setItemAsync(KEYS.USER, JSON.stringify(user)) },
  async getUser<T = unknown>() { const d = await SecureStore.getItemAsync(KEYS.USER); return d ? JSON.parse(d) as T : null },
  async clearAll() { await Promise.all([SecureStore.deleteItemAsync(KEYS.ACCESS_TOKEN), SecureStore.deleteItemAsync(KEYS.REFRESH_TOKEN), SecureStore.deleteItemAsync(KEYS.USER)]) },
}
'@
```

### 10.2 AsyncStorage 封装

```powershell
Set-Content -Path src\shared\storage\async-storage.ts -Value @'
import AsyncStorage from "@react-native-async-storage/async-storage"

export const AppAsyncStorage = {
  async getString(key: string) { return AsyncStorage.getItem(key) },
  async setString(key: string, value: string) { await AsyncStorage.setItem(key, value) },
  async removeObject(key: string) { await AsyncStorage.removeItem(key) },
  async getObject<T = unknown>(key: string) { const d = await AsyncStorage.getItem(key); return d ? JSON.parse(d) as T : null },
  async setObject(key: string, value: unknown) { await AsyncStorage.setItem(key, JSON.stringify(value)) },
}
'@
```

### 10.3 API Client（含信封解包 + Token 刷新）

```powershell
Set-Content -Path src\shared\api\client.ts -Value @'
import axios, { AxiosError, InternalAxiosRequestConfig } from "axios"
import { router } from "expo-router"
import { SecureStorage } from "@/shared/storage/secure"

const BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL || "http://localhost:5000/api"

function unwrapEnvelope<T>(payload: unknown): T {
  let current = payload
  for (let depth = 0; depth < 3; depth++) {
    if (typeof current !== "object" || current === null || !("data" in current)) break
    const keys = Object.keys(current)
    const isEnvelope = keys.includes("data") && (keys.includes("success") || keys.includes("isSuccess") || keys.includes("message"))
    if (!isEnvelope) break
    current = (current as Record<string, unknown>).data
  }
  return current as T
}

export const apiClient = axios.create({ baseURL: BASE_URL, timeout: 15000, headers: { "Content-Type": "application/json" } })

let isRefreshing = false
let refreshQueue: Array<{ resolve: (t: string) => void; reject: (e: Error) => void }> = []

apiClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  const token = await SecureStorage.getToken()
  if (token && config.headers) config.headers.Authorization = `Bearer ${token}`
  return config
}, (error) => Promise.reject(error))

apiClient.interceptors.response.use(
  (response) => { response.data = unwrapEnvelope(response.data); return response },
  async (error: AxiosError) => {
    const original = error.config as (InternalAxiosRequestConfig & { _retry?: boolean })
    if (error.response?.status === 401 && !original?._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => { refreshQueue.push({ resolve: (t) => { original.headers.Authorization = `Bearer ${t}`; resolve(apiClient(original)) }, reject }) })
      }
      original._retry = true
      isRefreshing = true
      try {
        const rt = await SecureStorage.getRefreshToken()
        if (!rt) throw new Error("No refresh token")
        const res = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken: rt })
        const { accessToken, refreshToken: newRt } = res.data.data ?? res.data
        await SecureStorage.setToken(accessToken)
        await SecureStorage.setRefreshToken(newRt)
        refreshQueue.forEach((cb) => cb.resolve(accessToken))
        refreshQueue = []
        original.headers.Authorization = `Bearer ${accessToken}`
        return apiClient(original)
      } catch (refreshErr) {
        refreshQueue.forEach((cb) => cb.reject(refreshErr as Error))
        refreshQueue = []
        await SecureStorage.clearAll()
        router.replace("/(auth)/login")
        return Promise.reject(refreshErr)
      } finally { isRefreshing = false }
    }
    return Promise.reject(error)
  }
)
'@
```

### 10.4 密码哈希

```powershell
Set-Content -Path src\shared\utils\password.ts -Value @'
import { sha256 } from "js-sha256"

export function hashPassword(password: string): string {
  return sha256(password)
}
'@
```

### 10.5 其他占位符

```powershell
Set-Content -Path src\shared\types\index.ts -Value "export interface ApiResponse<T = unknown> { success?: boolean; isSuccess?: boolean; message?: string; data?: T; code?: string }"
Set-Content -Path src\shared\constants\api.ts -Value "export const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL || 'http://localhost:5000/api'; export const API_TIMEOUT = 15000;"
```

---

## Step 11：创建占位符资源文件

```powershell
# 创建 1x1 占位 PNG（使用 PowerShell 的字节写入）
$pngBytes = [System.Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")
[System.IO.File]::WriteAllBytes("assets\images\icon.png", $pngBytes)
[System.IO.File]::WriteAllBytes("assets\images\splash.png", $pngBytes)
[System.IO.File]::WriteAllBytes("assets\images\adaptive-icon.png", $pngBytes)
```

---

## Step 12：Git 初始化与首次提交

```powershell
cd D:\DevRepos\HbwebExpo\HbwebExpoApp
git init
git add .
git commit -m "feat: init Expo project with core deps, router, auth placeholder, secure storage"
```

---

## Step 13：平台验证

### 13.1 Android 验证

```powershell
npx expo run:android
```

### 13.2 iOS 验证（Mac + Xcode）

```powershell
npx expo run:ios
```

---

## 验证清单

- [ ] `npx expo --version` 能输出版本
- [ ] `npx tsc --noEmit` 无类型错误
- [ ] iOS/Android 能正常启动并显示登录页
- [ ] Tab 导航能切换 Home / Orders / Settings
- [ ] `Text` 组件从 `react-native-paper` 导入（支持 `variant`）
- [ ] `js-sha256` 安装成功
- [ ] `SecureStorage` / `apiClient` 占位符编译通过
- [ ] `git log` 显示首次提交记录

---

## 常见问题排查

### Q1: `create-expo-app` 网络错误

```powershell
npm config set registry https://registry.npmmirror.com
npx create-expo-app@latest HbwebExpoApp --template blank-typescript
```

### Q2: `expo-camera` iOS 构建报错

```powershell
npx expo install --fix
```

### Q3: TypeScript 路径别名不生效

```powershell
npx expo start --clear
```

### Q4: `js-sha256` 输出与 `crypto-js` 不一致

两者都是标准 SHA-256 实现，输出一致。如果有问题，检查是否对密码做了额外处理（trim / toLowerCase）。

### Q5: `Set-Content` 编码问题

如果文件出现 BOM 或编码异常，添加 `-Encoding UTF8`：

```powershell
Set-Content -Path file.ts -Value "..." -Encoding UTF8
```
