# iOS 免费安装指南

> 使用 Apple ID 免费签名安装，每 7 天需重新签名一次

---

## 📋 准备工作

### 必需物品

| 物品 | 说明 |
|------|------|
| iPhone 设备 | iOS 15.0 及以上系统 |
| 数据线 | 原装或 MFi 认证线 |
| Windows/Mac 电脑 | 用于运行签名工具 |
| Apple ID | 免费 Apple ID 即可，不需要付费开发者账号 |
| GitHub 账号 | 用于云端编译生成 IPA |

### 软件下载

1. **Sideloadly** - https://sideloadly.io/
   - Windows 版本下载后直接安装
   - Mac 版本拖入 Applications 文件夹

2. **iTunes** (Windows)
   - 下载地址：https://www.apple.com/itunes/download/
   - ⚠️ 注意：下载苹果官网版本，不要用 Microsoft Store 版本

3. **iCloud** (Windows，可选)
   - 下载地址：https://support.apple.com/en-us/HT204283

---

## 🚀 第一步：编译生成 IPA 文件

### 方法 A：GitHub Actions 云端编译（推荐）

#### 1. 创建 GitHub 仓库

```bash
# 在项目目录打开命令行
cd D:\PycharmProjects\music_app

# 初始化 Git 仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: MusicPlayer iOS App"

# 添加远程仓库（替换成你的用户名）
git remote add origin https://github.com/你的用户名/MusicPlayer.git

# 推送到 GitHub
git push -u origin main
```

#### 2. 启用 GitHub Actions

1. 打开 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 如果提示启用 Workflows，点击 **I understand my workflows, go ahead and enable them**
4. 等待自动编译完成

#### 3. 下载 IPA 文件

编译完成后有两种下载方式：

**方式一：从 Artifacts 下载**
1. 点击已完成的 Workflow 运行记录
2. 在页面底部 **Artifacts** 区域找到 `MusicPlayer-IPA`
3. 点击下载（ZIP 压缩包，解压后得到 IPA）

**方式二：从 Releases 下载**
1. 点击仓库右侧 **Releases**
2. 找到最新版本
3. 下载 `MusicPlayer.ipa` 文件

---

### 方法 B：找有 Mac 的朋友帮忙

如果 GitHub Actions 编译失败，可以：

1. 把整个 `MusicPlayer` 文件夹发给有 Mac 的朋友
2. 让对方用 Xcode 打开项目
3. 选择 **Product → Archive**
4. 导出 IPA 文件发给你

---

## 📱 第二步：使用 Sideloadly 安装

### 1. 安装 Sideloadly

1. 访问 https://sideloadly.io/
2. 下载 Windows 版本（Sideloading-v0.x.x-Setup.exe）
3. 双击安装，一路下一步

### 2. 连接 iPhone

1. 用数据线连接 iPhone 到电脑
2. 在 iPhone 上点击 **"信任此电脑"**
3. 输入 iPhone 锁屏密码确认信任

### 3. 签名安装

1. **打开 Sideloadly**

2. **添加 IPA 文件**
   - 将下载的 `MusicPlayer.ipa` 拖入 Sideloadly 窗口
   - 或点击 IPA 图标选择文件

3. **输入 Apple ID**
   - 在 "Apple ID" 输入框填入你的 Apple ID（邮箱）
   - 建议使用常用 Apple ID

4. **开始安装**
   - 点击 **Start** 按钮
   - 首次使用会提示输入密码
   - 如果开启了双重认证，需要在 iPhone 上允许登录

5. **等待完成**
   - 看到 "Done" 提示表示安装成功
   - 整个过程约 1-3 分钟

---

## 🔓 第三步：信任开发者证书

安装完成后，需要信任开发者才能运行：

1. 在 iPhone 上打开 **设置**
2. 进入 **通用 → VPN与设备管理**
3. 在 "开发者App" 区域找到你的 Apple ID
4. 点击进入，选择 **信任 "[你的Apple ID]"**
5. 弹窗确认点击 **信任**

现在可以返回主屏幕，打开应用了！

---

## ⚠️ 重要提示

### 7 天签名有效期

免费 Apple ID 签名的应用**7天后会失效**，届时：
- 应用无法打开
- 需要重新用 Sideloadly 签名安装

### 如何续期

重复 **第二步** 和 **第三步** 即可：
1. 连接 iPhone 到电脑
2. 用 Sideloadly 重新签名安装
3. 信任开发者证书

### 免费签名的限制

| 限制项 | 说明 |
|--------|------|
| 有效期 | 7 天 |
| 应用数量 | 最多 3 个 |
| 推送通知 | 不支持 |
| iCloud | 不支持 |
| 应用内购买 | 不支持 |

---

## ❓ 常见问题

### Q1: Sideloadly 提示错误怎么办？

**错误：AnisetteData.dll 缺失**
- 解决：关闭 Sideloadly，以管理员身份重新运行

**错误：Your session has expired**
- 解决：在 iPhone 上打开设置 → Apple ID → 重新登录

**错误：Failed to request certificate**
- 解决：确保 Apple ID 没有开启双重认证，或使用应用专用密码

### Q2: 首次安装提示"未受信任的企业级开发者"？

这是正常的，按 **第三步** 操作信任即可。

### Q3: 忘了续期，应用过期了，数据会丢失吗？

重新签名安装后，数据会保留，但为了安全起见，建议定期备份重要数据。

### Q4: 能用别人的 Apple ID 签名吗？

可以，但不推荐。对方可以看到你的设备和部分信息。

### Q5: 如何生成应用专用密码？

1. 访问 https://appleid.apple.com/
2. 登录你的 Apple ID
3. 进入 "安全" → "App 专用密码"
4. 点击生成，复制密码
5. 在 Sideloadly 中输入这个专用密码而非 Apple ID 密码

---

## 📅 续期提醒

建议设置一个每周提醒，比如：

- 每周日固定检查应用是否需要续期
- 或者在手机日历中设置每周重复提醒

---

## 🔗 相关链接

- Sideloadly 官网：https://sideloadly.io/
- GitHub Actions 文档：https://docs.github.com/cn/actions
- Apple ID 管理：https://appleid.apple.com/

---

## 💰 如果不想每 7 天续期

可以考虑购买 Apple Developer Program：

- 费用：¥688/年（约 ¥1.9/天）
- 有效期：1 年
- 额外福利：可上架 App Store、支持推送通知等

购买地址：https://developer.apple.com/programs/

---

*最后更新：2024年*
