# HbPrinterModule 原生模块代码位置

## 说明

`HbwebExpo` 项目里，位图打印相关的 Android 原生模块名是 `HbPrinterModule`。  
如果需要修改 Java/Kotlin 原生打印逻辑，主要查看下面这几个文件。

## 1. 原生模块实现文件

- `HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/HbPrinterModule.kt`

绝对路径：

- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/HbPrinterModule.kt`

这个文件是核心实现位置，包含：

- 蓝牙连接
- 打印机扫描
- 打印状态获取
- 位图/标签打印相关原生逻辑

模块类定义示例：

```kotlin
class HbPrinterModule(
  reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {
  override fun getName(): String = "HbPrinterModule"
}
```

## 2. React Native Package 注册文件

- `HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/HbPrinterPackage.kt`

绝对路径：

- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/HbPrinterPackage.kt`

这个文件负责把 `HbPrinterModule` 注册成 React Native 可用的原生模块：

```kotlin
class HbPrinterPackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(HbPrinterModule(reactContext))
  }
}
```

## 3. App 启动时挂载入口

- `HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/MainApplication.kt`

绝对路径：

- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/MainApplication.kt`

这里会把 `HbPrinterPackage` 加入应用的 `packages` 列表：

```kotlin
PackageList(this).packages.apply {
  add(HbPrinterPackage())
}
```

## 4. JS/TS 调用入口

- `HbwebExpoApp/src/modules/printer/native.ts`

绝对路径：

- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/src/modules/printer/native.ts`

前端通过这里调用原生模块：

```ts
const nativeModule = NativeModules.HbPrinterModule as NativePrinterModule | undefined;
```

## 结论

如果你的目标是修改“位图打印”的 Android 原生实现，优先改这个文件：

- `/Users/sean/DEV/HbwebExpo/HbwebExpoApp/android/app/src/main/java/com/hbweb/expo/HbPrinterModule.kt`

如果改完代码后发现前端调用不到，再检查：

1. `HbPrinterPackage.kt` 是否正确注册
2. `MainApplication.kt` 是否正确挂载
3. `native.ts` 的模块名是否仍然是 `HbPrinterModule`
