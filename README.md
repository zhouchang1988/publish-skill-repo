# Publish Skill Repo

将 Skill 项目一键发布到 GitHub，并自动同步到 ClawHub 的脚本工具。

## 功能

- ✅ 初始化 Git 仓库（如需要）
- ✅ 创建 MIT LICENSE（如不存在）
- ✅ 创建 GitHub Actions workflow，实现打 tag 时自动发布到 ClawHub
- ✅ 创建 GitHub 仓库（如不存在）
- ✅ 配置 ClawHub Token 到仓库 Secrets
- ✅ 推送代码到 GitHub
- ✅ **新仓库自动创建 v1.0.0 tag 并发布**

## 快速开始

```bash
# 一键发布 Skill
./publish-skill-repo.sh ~/skills/my-awesome-skill
```

脚本会自动完成所有配置，新仓库会立即发布 v1.0.0 到 ClawHub。

## 准备工作

### 1. ClawHub Token

在 ClawHub 上生成 Token：

1. 打开 https://clawhub.ai/
2. 点击 **"Login with GitHub"** 登录
3. 进入 **Settings** → **API tokens** → **"Create token"**
4. 复制生成的 Token（格式：`clh_iVnxxxxxxxx...`）

⚠️ **注意**：Token 仅显示一次，请立即保存！

保存到本机：

```bash
mkdir -p ~/.clawhub
echo "your-clawhub-token" > ~/.clawhub/secret_token
chmod 600 ~/.clawhub/secret_token
```

### 2. GitHub CLI

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

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `skill目录` | Skill 项目路径（需包含 SKILL.md） | 必填 |
| `github-owner` | GitHub 用户名或组织名 | 当前用户 |
| `public\|private` | 仓库可见性 | public |

### 示例

```bash
# 默认：当前用户、公开仓库
./publish-skill-repo.sh ~/skills/my-skill

# 指定组织和私有仓库
./publish-skill-repo.sh ~/skills/my-skill myorg private
```

## 工作流程

### 新仓库

脚本检测到新仓库时，会自动：
1. 初始化 Git
2. 创建 LICENSE 和 workflow
3. 创建 GitHub 仓库
4. 推送代码
5. **自动创建并推送 v1.0.0 tag**
6. GitHub Actions 自动发布到 ClawHub

### 已有仓库

对于已存在的仓库，发布新版本：

```bash
git tag v1.1.0
git push origin v1.1.0
```

## 目录要求

Skill 目录必须包含 `SKILL.md`：

```
my-skill/
├── SKILL.md      # 必须
└── ...其他文件
```

## 配置说明

| 配置项 | 路径/格式 |
|--------|----------|
| Token 文件 | `~/.clawhub/secret_token` |
| Tag 格式 | `v*.*.*`（如 v1.0.0） |
| Workflow | `.github/workflows/publish-to-clawhub.yml` |
