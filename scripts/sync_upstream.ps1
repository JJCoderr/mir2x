# 上游 etorth/mir2x 同步助手
#
# 用法：
#   pwsh ./scripts/sync_upstream.ps1                # 抓取上游并输出报告
#   pwsh ./scripts/sync_upstream.ps1 -Count 50      # 只看最近 50 条
#   pwsh ./scripts/sync_upstream.ps1 -Mirror        # 额外把上游 main 推到 origin/upstream-main
#
# 说明见 docs/UPSTREAM_SYNC.md

param(
    [int]$Count = 20,
    [string]$Base = 'v0.1^{}',
    [switch]$Mirror
)

$ErrorActionPreference = 'Stop'
$env:GIT_TERMINAL_PROMPT = '0'

function RunGit { & git.exe @args }
function Section($t) { "`n===== $t =====" }

Section '抓取上游'
RunGit fetch upstream --prune --tags 2>&1 | Select-Object -Last 3
"上游 main: " + (RunGit log -1 --format='%h %ad %s' --date=short upstream/main)

Section "上游最近 $Count 条提交"
RunGit log upstream/main -n $Count --format='%h %ad %an | %s' --date=short

Section '分叉规模（相对参考基线）'
"基线: $Base"
"本仓库提交数(基线后): " + (RunGit rev-list main "^$Base" --count)
"上游提交数(基线后):   " + (RunGit rev-list upstream/main "^$Base" --count)
"本仓库独有提交:       " + (RunGit rev-list main --not upstream/main --count)
"上游有而本地没有:     " + (RunGit rev-list upstream/main --not main --count)
RunGit diff --shortstat $Base main
RunGit diff --shortstat $Base upstream/main

Section '双方改动重叠文件（需人工判断的部分）'
$own = RunGit diff --name-only $Base main
$up = RunGit diff --name-only $Base upstream/main
$inter = @($own | Where-Object { $up -contains $_ })
"重叠文件数: $($inter.Count)"
$inter | ForEach-Object { ($_ -split '/')[0] } | Group-Object |
    Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize

Section '整体差异（本仓库 main → 上游 main）'
RunGit diff --stat main upstream/main | Select-Object -Last 1

if ($Mirror) {
    Section '更新镜像分支 origin/upstream-main'
    RunGit push origin refs/remotes/upstream/main:refs/heads/upstream-main 2>&1 | Select-Object -Last 3
}

Section '提示'
@'
- 只想要上游的服务端/公共层修复：git log upstream/main -- server common 后 git cherry-pick
- 想对比某个文件：git diff 'v0.1^{}' upstream/main -- <path>
- 在 GitHub 网页看上游：分支 upstream-main（本仓库镜像），或 https://github.com/etorth/mir2x
- 详细路线见 docs/UPSTREAM_SYNC.md
'@
