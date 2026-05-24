# HB App 应用图标设计说明

## 目标

为 `HbwebExpoApp` 设计一套新的应用图标资产，基于 `HB` 字母标识，并参考现有 `HOT BARGAIN variety store` 横版 Logo 的红蓝霓虹、星芒和零售招牌气质。图标需要适配 iOS/Android 启动器、Android adaptive icon、启动页和网页 favicon。

## 已确认方向

最终方向为“方案 B 去 Logo 红环版”：

- 主视觉采用红蓝科技光感：深蓝为主背景，红色只作为背景能量光效。
- 中心只保留粗体白色 `HB`，确保手机桌面小尺寸仍然清晰。
- 从旧 Logo 中提炼灰白星芒线，但降低透明度，作为轻装饰而不是主元素。
- 保留一条很轻的圆角扫描线，表达扫码、设备连接、移动业务系统。
- 取消 Logo 红环，避免图标看起来像旧招牌贴纸，保持正式 App 图标的简洁度。

## 资产范围

需要产出并替换以下 Expo 当前引用的资源：

- `HbwebExpoApp/assets/icon.png`：1024x1024 主应用图标。
- `HbwebExpoApp/assets/adaptive-icon.png`：1024x1024 Android adaptive icon 前景图。
- `HbwebExpoApp/assets/splash-icon.png`：1024x1024 启动页图标。
- `HbwebExpoApp/assets/favicon.png`：48x48 网页 favicon。

`HbwebExpoApp/app.json` 当前已引用这些路径，不需要改配置。

## 生成约束

- 不把横版 Logo 原图直接塞进 App 图标，避免小尺寸不可读。
- 不使用 `HOT BARGAIN variety store` 全文字样，只保留 `HB`。
- 红色只能作为光效或局部强调，不能形成外环。
- 星芒线和扫描线都应低对比度，不能抢过 `HB` 主标。
- 图标边缘应保留足够安全区，避免 iOS 圆角和 Android adaptive icon 裁切损失主体。

## 验证标准

- 1024 图标视觉完整，无明显模糊、锯齿、文字变形或水印。
- 缩小到约 48px 时仍能识别 `HB`。
- Android adaptive icon 裁切后主体仍居中。
- `app.json` 中引用的四个资产文件存在且尺寸符合当前约定。
- 项目类型检查或资产尺寸检查通过。
