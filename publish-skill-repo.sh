#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Publish Skill Repo - 将 Skill 项目发布到 GitHub 并同步到 ClawHub
# ============================================================================
#
# 运行前请确保已完成以下准备工作：
#
# 1. 获取 ClawHub Token 并保存到本地：
#    - 访问 https://clawhub.ai/ → Login with GitHub → Settings → API tokens → Create token
#    - 保存 Token：
#      mkdir -p ~/.clawhub
#      echo "your-clawhub-token" > ~/.clawhub/secret_token
#      chmod 600 ~/.clawhub/secret_token
#
# 2. 安装并登录 GitHub CLI：
#    - macOS: brew install gh
#    - 登录: gh auth login
#
# 用法:
#   ./publish-skill-repo.sh /path/to/your-skill [github-owner] [public|private]
# ============================================================================

SKILL_DIR="${1:-}"
OWNER="${2:-$(gh api user --jq .login)}"
VISIBILITY="${3:-public}"
TOKEN_FILE="${HOME}/.clawhub/secret_token"

if [[ -z "$SKILL_DIR" ]]; then
  echo "用法: $0 <skill目录> [github-owner] [public|private]"
  exit 1
fi

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "目录不存在: $SKILL_DIR"
  exit 1
fi

if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
  echo "缺少 SKILL.md: $SKILL_DIR/SKILL.md"
  exit 1
fi

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "未找到 token 文件: $TOKEN_FILE"
  exit 1
fi

CLAWHUB_TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"

if [[ -z "$CLAWHUB_TOKEN" ]]; then
  echo "token 文件为空: $TOKEN_FILE"
  exit 1
fi

REPO_NAME="$(basename "$SKILL_DIR")"
REPO_FULL="$OWNER/$REPO_NAME"

echo "==> 检查 gh 登录状态"
gh auth status >/dev/null

echo "==> 进入目录: $SKILL_DIR"
cd "$SKILL_DIR"

if [[ ! -d .git ]]; then
  echo "==> 初始化 git"
  git init
  git branch -M main
fi

if [[ ! -f LICENSE ]]; then
  echo "==> 创建 MIT LICENSE"
  YEAR=$(date +%Y)
  cat > LICENSE <<EOF
MIT License

Copyright (c) $YEAR $OWNER

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
fi

echo "==> 创建 workflow"
mkdir -p .github/workflows

cat > .github/workflows/publish-to-clawhub.yml <<'YAML'
name: Publish Skill to ClawHub

on:
  push:
    tags:
      - "v*.*.*"

jobs:
  publish:
    runs-on: ubuntu-latest

    permissions:
      contents: read

    env:
      CLAWHUB_TOKEN: ${{ secrets.CLAWHUB_TOKEN }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install ClawHub CLI
        run: npm install -g clawhub

      - name: Extract metadata
        id: meta
        shell: bash
        run: |
          TAG="${GITHUB_REF#refs/tags/}"
          VERSION="${TAG#v}"
          REPO_NAME="${GITHUB_REPOSITORY#*/}"

          echo "tag=$TAG" >> "$GITHUB_OUTPUT"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "slug=$REPO_NAME" >> "$GITHUB_OUTPUT"
          echo "name=$REPO_NAME" >> "$GITHUB_OUTPUT"

      - name: Validate required files
        shell: bash
        run: |
          test -f SKILL.md || (echo "SKILL.md not found" && exit 1)

      - name: Login to ClawHub
        run: clawhub login --token "$CLAWHUB_TOKEN"

      - name: Publish to ClawHub
        shell: bash
        run: |
          clawhub publish . \
            --slug "${{ steps.meta.outputs.slug }}" \
            --name "${{ steps.meta.outputs.name }}" \
            --version "${{ steps.meta.outputs.version }}" \
            --tags "latest" \
            --changelog "Release ${{ steps.meta.outputs.tag }} from GitHub"

      - name: Success summary
        run: |
          echo "Published slug: ${{ steps.meta.outputs.slug }}"
          echo "Published version: ${{ steps.meta.outputs.version }}"
          echo "Source tag: ${{ steps.meta.outputs.tag }}"
YAML

if gh repo view "$REPO_FULL" >/dev/null 2>&1; then
  echo "==> GitHub 仓库已存在: $REPO_FULL"
else
  echo "==> 创建 GitHub 仓库: $REPO_FULL"
  gh repo create "$REPO_FULL" --"$VISIBILITY" --source=. --remote=origin --push=false
fi

echo "==> 设置仓库 Secret"
gh secret set CLAWHUB_TOKEN --repo "$REPO_FULL" --body "$CLAWHUB_TOKEN"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "==> 添加远程 origin"
  git remote add origin "https://github.com/$REPO_FULL.git"
fi

echo "==> 提交代码"
git add .
if git diff --cached --quiet; then
  echo "没有新的变更可提交"
else
  git commit -m "chore: init skill repo"
fi

echo "==> 推送 main"
git push -u origin main

echo ""
echo "完成:"
echo "  仓库: https://github.com/$REPO_FULL"
echo "  之后发布版本:"
echo "    git tag v1.0.0"
echo "    git push origin v1.0.0"
