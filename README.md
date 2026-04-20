# Publish Skill Repo

将 Skill 项目发布到 GitHub，并自动同步到 ClawHub 的脚本工具。

## 功能

- 初始化 Git 仓库（如需要）
- 创建 GitHub Actions workflow，实现打 tag 时自动发布到 ClawHub
- 创建 GitHub 仓库（如不存在）
- 配置 ClawHub Token 到仓库 Secrets
- 推送代码到 GitHub

## 前提条件

1. **ClawHub Token**

   在 ClawHub 上生成 Token 的步骤：

   1. 打开 https://clawhub.ai/
   2. 点击右上角 **"Login with GitHub"**，使用 GitHub 账号授权登录
   3. 登录成功后，点击右上角**用户名**，选择 **Settings**
   4. 在设置页面找到 **API tokens** 区域，点击 **"Create token"**
   5. 复制生成的 Token（格式类似：`clh_iVnxxxxxxxx...`）

   ⚠️ **注意**：Token 生成后立即保存，关闭页面后将无法再次查看！

   然后将 Token 保存到本机：

   ```bash
   mkdir -p ~/.clawhub
   echo "your-clawhub-token" > ~/.clawhub/secret_token
   ```

2. **GitHub CLI**

   必须安装 GitHub CLI (`gh`) 并登录：

   ```bash
   # macOS
   brew install gh

   # 登录 GitHub
   gh auth login
   ```

## 使用方法

```bash
./publish-skill-repo.sh <skill目录> [github-owner] [public|private]
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `skill目录` | Skill 项目的本地目录路径（必须包含 SKILL.md） | 必填 |
| `github-owner` | GitHub 用户名或组织名 | 当前登录用户 |
| `public\|private` | 仓库可见性 | public |

### 示例

```bash
# 使用默认参数（当前用户、公开仓库）
./publish-skill-repo.sh ~/skills/my-awesome-skill

# 指定所有参数
./publish-skill-repo.sh ~/skills/my-awesome-skill myorg private
```

## 发布流程

脚本执行完成后，通过打 tag 触发自动发布：

```bash
cd ~/skills/my-awesome-skill
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions 会自动：
1. 检出代码
2. 安装 ClawHub CLI
3. 登录 ClawHub
4. 发布 Skill 到 ClawHub

## 目录结构要求

Skill 目录必须包含 `SKILL.md` 文件：

```
my-skill/
├── SKILL.md      # 必须存在
└── ...其他文件
```

## 注意事项

- Token 文件路径：`~/.clawhub/secret_token`
- Tag 格式：`v*.*.*`（如 `v1.0.0`、`v1.2.3`）
- 脚本会自动创建 `.github/workflows/publish-to-clawhub.yml`
