# mini-game

一个独立的小游戏项目 —— 玩法待定，先把「网页游戏 + 手机安装包」的架子搭好。

## 规划

| 阶段 | 内容 |
| --- | --- |
| 1 | 游戏本体（纯前端 HTML/CSS/JS 或 canvas），放在 `web/` |
| 2 | 部署到 Cloudflare Pages，拿到网址 |
| 3 | 改 `android/url.txt` 指向游戏网址，push 触发 Actions 编译 APK |
| 4 | 下载 `apk/mimichong-game.apk` 安装到手机 |

## 目录

```
web/                  游戏本体（待写）
android/              Android WebView 壳子
  url.txt             壳子打开的网址（改这里就能换游戏）
  build.sh            编译脚本（在 GitHub Actions 里跑）
apk/                  编译产物（由 Actions 自动提交）
.github/workflows/    build-apk.yml 云端打包
```

## 怎么出安装包

1. 把游戏的线上地址写进 `android/url.txt`（一行，带 https://）
2. 提交并 push
3. 打开仓库的 Actions → Build APK，等约 2 分钟
4. 下载 `apk/mimichong-game.apk` 装到手机

> 手机安装时需要允许「未知来源应用」。

## 技术说明

- 壳子是最小 WebView：开 JS、开 localStorage、支持返回键、无第三方依赖
- 每次构建自动生成签名密钥（自签名，安装时 Android 会提示但可装）
- APK 约 1MB，不需要 Google 服务，国产 ROM 也能装

## License

MIT
