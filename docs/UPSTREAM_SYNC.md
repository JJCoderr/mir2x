# 上游同步说明（etorth/mir2x）

本仓库参考自 [etorth/mir2x](https://github.com/etorth/mir2x)（公开仓库，C++ / MMORPG 客户端+服务端）。
本文件记录两边的对应关系、分叉规模与同步方式，供后续维护使用。

## 1. Remote 约定

| remote | 地址 | 用途 |
|---|---|---|
| `origin` | `https://github.com/<本账号>/mir2x.git` | 自己的仓库 |
| `upstream` | `https://github.com/etorth/mir2x.git` | 上游参考源 |

另外 `origin` 上保留只读镜像分支 `upstream-main`，内容就是上游 `main`（`f7072661`，2026-11-13），
便于在 GitHub 网页上直接浏览上游代码，不受上游网络访问情况影响：

```bash
git push origin refs/remotes/upstream/main:refs/heads/upstream-main   # 更新镜像
git push origin --delete upstream-main                                # 不需要时删除
```

## 2. 参考基线

| 项 | 值 |
|---|---|
| 基线提交（上游） | `a1e65e5` `fix pointer type`（2026-07-10，etorth） |
| 基线提交（本仓库） | `v0.1` 标签指向的提交，树 `2feb38b8`，与上游 `a1e65e5` 内容完全一致 |
| 第一个自有提交 | `af49d355` `build: add imgui/glfw3/miniaudio/tinyfiledialogs deps`（2026-07-24） |
| 当前上游 HEAD | `f7072661`（2026-11-13，`main`=`dev`=`release`） |

## 3. 分叉规模（相对基线实测）

| 指标 | 本仓库 (`main`) | 上游 (`upstream/main`) |
|---|---|---|
| 基线后提交数 | 136 | 781 |
| 变更文件数 | 508 | 751 |
| 新增行 / 删除行 | +24287 / −59072 | +79210 / −13507 |
| 新增文件 | 78 | 213 |
| 删除文件 | 325 | 19 |

双方的改动文件有 **201 个重叠**，这才是同步时真正的冲突面：

| 目录 | 重叠文件数 |
|---|---|
| `client/src` 等 client 层 | 147 |
| `server` | 28 |
| `common` | 8 |
| `tools` | 8 |
| 其余（根级配置、cmake、ports） | 10 |

## 4. 为什么不能直接 merge

1. 本仓库在 client 层是**重写**而非增量修改：相对基线删除了 325 个上游文件、新增 78 个自己的文件，
   client 的控件、渲染、UI 组织方式已与上游不同。
2. `client/CMakeLists.txt` 使用 `file(GLOB_RECURSE CLIENT_SRCS src/*.hpp src/*.cpp)`，
   一旦把上游新增的 client 文件与旧文件一起放进 `client/src`，就会全部参与编译，
   而它们依赖的是上游新版的控件/渲染 API —— 结果必然是编译失败。
3. 上游同期把 client 层整体重构（控件 `InitArgs`、布局与渲染尺寸、stall/摊位、gold 64 位等），
   自动合并后的语义仍需逐处人工确认。

实测一次 `git merge upstream/main`：275 个冲突，其中 168 个是"我方已删除、上游仍在修改"的文件，
另有 `client/src` 146 个文件双向改动。机械合并产出的树不可编译，因此没有提交到 `main`。

## 5. 可选的三条同步路线

**路线 A：只跟进服务端/公共层修复（成本最低）**
```bash
git fetch upstream
git log --oneline upstream/main -- server common | head -50       # 挑选需要的修复
git cherry-pick <commit>                                          # 逐条摘取
```
`server` 27 个、`common` 7 个重叠文件，冲突可控。

**路线 B：按模块移植（中等成本，适合跟进 client 重构）**
上游 client 的关键变化先读 diff，再在本仓库等价实现，而不是整块 merge：
```bash
git diff 'v0.1^{}' upstream/main -- client/src/gldevice.cpp client/src/gldevice.hpp
```

**路线 C：以上游为新基线重新维护自有功能（成本最高，一次性）**
把 136 个自有提交作为补丁集保存（见第 6 节），在 `upstream/main` 上重放并逐个解决冲突，
然后把 `main` 切到新基线上。适合决定长期跟随上游时执行。

## 6. 自有提交补丁集

本机的 `G:\Mir3\mir2x-patches\` 保存了自基线以来的 134 个补丁（`git format-patch` 导出），
可用于在任意上游版本上重放自有改动：

```bash
git switch -c port/onto-upstream upstream/main
git am G:/Mir3/mir2x-patches/*.patch          # 有冲突时 git am --continue / --skip
```

## 7. 冲突面文件清单（201 个）

> 这些文件两边都改过，同步时需要人工判断。

```text
.github/workflows/build.yml
.gitignore
build.py
client/CMakeLists.txt
client/src/acbutton.cpp
client/src/alphaonbutton.cpp
client/src/ascendstr.cpp
client/src/attachmagic.cpp
client/src/baseframeboard.cpp
client/src/bgmusicdb.hpp
client/src/button.cpp
client/src/buttonbase.hpp
client/src/checkbox.cpp
client/src/checklabel.cpp
client/src/checklabel.hpp
client/src/client.cpp
client/src/client.hpp
client/src/clientcreature.cpp
client/src/clientcreature.hpp
client/src/clientmonster.cpp
client/src/clientmonster.hpp
client/src/clientnpc.cpp
client/src/CMakeLists.txt
client/src/emojidb.cpp
client/src/emojidb.hpp
client/src/fixedlocmagic.cpp
client/src/followuidmagic.cpp
client/src/gfxdebugboard.cpp
client/src/gui/acutionboard/acutionboard.cpp
client/src/gui/acutionboard/acutionboard.hpp
client/src/gui/controlboard/cbface.cpp
client/src/gui/controlboard/cbleft.cpp
client/src/gui/controlboard/cbmiddle.cpp
client/src/gui/controlboard/cbmiddle.hpp
client/src/gui/controlboard/cbmiddleexpand.cpp
client/src/gui/controlboard/cbmiddleexpand.hpp
client/src/gui/controlboard/cbright.cpp
client/src/gui/controlboard/cbtitle.cpp
client/src/gui/controlboard/cbtitle.hpp
client/src/gui/controlboard/controlboard.cpp
client/src/gui/controlboard/controlboard.hpp
client/src/gui/friendchatboard/chatinputcontainer.cpp
client/src/gui/friendchatboard/chatitem.cpp
client/src/gui/friendchatboard/chatitemcontainer.cpp
client/src/gui/friendchatboard/chatpreviewitem.cpp
client/src/gui/friendchatboard/friendchatboard.cpp
client/src/gui/friendchatboard/friendchatboard.hpp
client/src/gui/friendchatboard/frienditem.cpp
client/src/gui/friendchatboard/friendlistpage.cpp
client/src/gui/friendchatboard/searchautocompletionitem.cpp
client/src/gui/friendchatboard/searchinputline.cpp
client/src/gui/friendchatboard/searchpage.cpp
client/src/gui/npcchatboard/npcchatboard.cpp
client/src/gui/npcchatboard/npcchatorigframe.cpp
client/src/gui/purchaseboard/purchaseboard.cpp
client/src/gui/quickaccessboard/quickaccessboard.cpp
client/src/gui/quickaccessboard/quickaccessgrid.cpp
client/src/gui/runtimeconfigboard/runtimeconfigboard.cpp
client/src/gui/runtimeconfigboard/runtimeconfigboard.hpp
client/src/gui/skillboard/magiciconbutton.cpp
client/src/gui/skillboard/skillboard.cpp
client/src/gui/skillboard/skillboardconfig.cpp
client/src/gui/skillboard/skillboardconfig.hpp
client/src/gui/skillboard/skillpage.cpp
client/src/guildboard.cpp
client/src/guimanager.cpp
client/src/guimanager.hpp
client/src/hero.cpp
client/src/horseboard.cpp
client/src/imeboard.cpp
client/src/initview.cpp
client/src/inputline.cpp
client/src/inputline.hpp
client/src/inputstringboard.cpp
client/src/inputstringboard.hpp
client/src/integerselector.hpp
client/src/inventoryboard.cpp
client/src/inventoryboard.hpp
client/src/invpack.cpp
client/src/itemlistboard.cpp
client/src/itemlistboard.hpp
client/src/labelboard.cpp
client/src/labelboard.hpp
client/src/layoutboard.cpp
client/src/layoutboard.hpp
client/src/main.cpp
client/src/menu.cpp
client/src/messagestackboard.cpp
client/src/minimapboard.cpp
client/src/minimapboard.hpp
client/src/modalstringboard.cpp
client/src/motioneffect.cpp
client/src/myhero.cpp
client/src/passwordbox.hpp
client/src/pngtexdb.hpp
client/src/pngtexoffdb.cpp
client/src/pngtexoffdb.hpp
client/src/process.hpp
client/src/processchangepassword.cpp
client/src/processchangepassword.hpp
client/src/processcreateaccount.cpp
client/src/processcreateaccount.hpp
client/src/processcreatechar.cpp
client/src/processcreatechar.hpp
client/src/processlogin.cpp
client/src/processlogin.hpp
client/src/processlogo.cpp
client/src/processrun.cpp
client/src/processrun.hpp
client/src/processrunnet.cpp
client/src/processselectchar.cpp
client/src/processselectchar.hpp
client/src/processselectcharnet.cpp
client/src/processsync.cpp
client/src/pullmenu.cpp
client/src/pullmenu.hpp
client/src/queststateboard.cpp
client/src/radioselector.cpp
client/src/sdldevice.cpp
client/src/sdldevice.hpp
client/src/secureditemlistboard.cpp
client/src/sliderbase.cpp
client/src/sliderbase.hpp
client/src/soundeffectdb.hpp
client/src/teamstateboard.cpp
client/src/teamstateboard.hpp
client/src/texaniboard.cpp
client/src/texaniboard.hpp
client/src/texinputbackground.cpp
client/src/texslider.cpp
client/src/texsliderbar.cpp
client/src/textboard.hpp
client/src/textinput.cpp
client/src/textinput.hpp
client/src/token.hpp
client/src/trigfxbutton.cpp
client/src/tritexbutton.cpp
client/src/tritexbutton.hpp
client/src/valueselector.cpp
client/src/valueselector.hpp
client/src/widget.cpp
client/src/widget.hpp
client/src/widget.implement.hpp
client/src/widget.offset2d.hpp
client/src/widget.roi.hpp
client/src/widget.size2d.hpp
client/src/widget.varstr.hpp
client/src/wmdaniboard.hpp
client/src/xmlparagraphleaf.cpp
client/src/xmlparagraphleaf.hpp
cmake/Mir2xResPath.cmake
CMakeLists.txt
common/CMakeLists.txt
common/src/colorf.hpp
common/src/jobf.hpp
common/src/luamodule.cpp
common/src/magicrecord.hpp
common/src/maprecord.hpp
common/src/monsterrecord.hpp
common/src/sdruntimeconfig.hpp
ports/sdl3-gfx/portfile.cmake
ports/sdl3-gfx/vcpkg.json
README.md
server/CMakeLists.txt
server/src/actorpod.cpp
server/src/actorpod.hpp
server/src/actorpool.cpp
server/src/battleobject.cpp
server/src/battleobject.hpp
server/src/buffacttrigger.cpp
server/src/bufflist.cpp
server/src/charobject.cpp
server/src/CMakeLists.txt
server/src/dropitemconfig.cpp
server/src/enableaddco.cpp
server/src/main.cpp
server/src/monster.cpp
server/src/netdriver.cpp
server/src/npchar.cpp
server/src/peercore.cpp
server/src/player.cpp
server/src/quest.cpp
server/src/server.cpp
server/src/serverluacoroutinerunner.cpp
server/src/serverluacoroutinerunner.hpp
server/src/serverluamodule.cpp
server/src/servermap.cpp
server/src/serverobject.cpp
server/src/servertaodog.cpp
server/src/servicecore.cpp
server/src/servicecorenet.cpp
tools/followuidmagiceditor/src/aboutwindow.fl
tools/followuidmagiceditor/src/CMakeLists.txt
tools/followuidmagiceditor/src/magicdrawarea.cpp
tools/followuidmagiceditor/src/magicdrawarea.hpp
tools/followuidmagiceditor/src/magicframedb.cpp
tools/followuidmagiceditor/src/magicframedb.hpp
tools/followuidmagiceditor/src/main.cpp
tools/followuidmagiceditor/src/mainwindow.fl
vcpkg.json
vcpkg-configuration.json
```

## 8. 常用命令

```bash
git fetch upstream --prune
git log --oneline upstream/main -30                 # 上游最近提交
git log --oneline main ^upstream/main | head -30    # 本仓库独有提交
git diff --stat main upstream/main                  # 双方整体差异
git diff --stat 'v0.1^{}' upstream/main             # 上游自基线以来的改动
powershell -NoProfile -File ./scripts/sync_upstream.ps1   # 一键：抓取 + 报告（可加 -Mirror 更新镜像分支）
```

## 9. 可优先摘取的上游提交（server / common / ports / 构建配置）

基线以来这类提交共 **404** 条，冲突面小，适合用 git cherry-pick 逐条摘取。最近 40 条：

```text
0a2225c7 2026-11-12 Widen gold to 64-bit and use parserf for price, level and count input
7578f744 2026-11-12 Add parserf for strict parsing and range checks of price, level and counts
6af9b0a5 2026-11-11 Check stall selling in each net_CM_* handler with its own error type
9c91ed55 2026-11-11 Check mir2x_assets version when installing resources
161fd4cc 2026-11-11 Merge playerstall.cpp into player.cpp, playernet.cpp and playerop.cpp
54c97882 2026-11-10 Add basic 自动打怪 for players, started from 散财童子 and kept running when hosted
ea1efde8 2026-11-10 Guard char deletion and stall ops against hosted actors and pending trades
5eb200e0 2026-11-09 Add offline hosting (离线挂机) and drop snapshot-based offline stalls
389ba798 2026-11-07 Rename stall open action and errors to start/selling
97f33ff9 2026-11-07 Rename stall "open" state to "selling"
68ded536 2026-11-07 Widget skill: document member initialization order
e32f24a0 2026-11-07 Add initial stall-sell (摆摊) system, replacing the exchange button
201b19d3 2026-11-04 SYS_DEFRPS
4ffd8452 2026-11-03 client: add 平滑移动 option and lay out 常用 page in 3 columns
89a525cf 2026-11-03 add RTCFG_刷新率 and 刷新率 pull menu in RuntimeConfigBoard
2ab0ef9b 2026-11-03 Team: SDTeamReq/SDTeamJobReq with jobf gfx-index job order
03b3c3b4 2026-11-03 Team: offline handling, exp share, follow toggle, job column
ed0753b9 2026-11-03 support transferring team leader
92037041 2026-11-03 query nearby team info for TeamStateBoard nearby page
73b71f77 2026-11-03 check team requirement on server when applying and joining team
ed92ae0d 2026-11-03 add CM_CREATETEAM/CM_SETTEAMREQUIREMENT and wire team requirement pages
3fb5f4e3 2026-11-03 move team requirement to common SDTeamRequirement
060c9a3c 2026-11-02 zsdbmaker: add --comp-level and --comp-ratio-threshold, install_res uses max/0.99
a9f6ddda 2026-11-02 boardcast team leader token
a360c2e8 2026-11-02 build: switch to mir2x_assets, rename --res-path to --assets-path
5c924db5 2026-10-31 client: load magic gfx from APNGs with MagicDB
f05d2151 2026-10-26 fix emoji indexing
4303a189 2026-10-26 client: load emoji from APNG with per-frame delays
0fa7e563 2026-10-25 fix UB in innDB::dtor
d8ca8a55 2026-10-25 f
f67a7055 2026-10-20 fix revive relocation without flushing death motions
9a1c56db 2026-10-20 add minimize button for revive and logout to character select
4ceb8657 2026-10-19 fix belt consume
a3664af4 2026-10-19 fix Windows hres_tstamp overflow causing negative profiler totals
a6984136 2026-10-19 HPBar fix
68985c4e 2026-10-18 fit numeric HP bars to text and update attached GUI
17833477 2026-10-18 small tweak
2a9f4ebc 2026-10-17 show player monster and NPC names through runtime configuration
052be84a 2026-10-17   send CO net packages to map observers instead of own in-view list
bbbe0721 2026-10-17 use ZSTD default compression level in zstdEncode
```

## 10. 2026-11-16 历史结构变更（重要）

远端仓库重新 fork 上游后，本地重写了分支拓扑，当前约定：

| 引用 | 含义 |
|---|---|
| `main`（`97e5b2c0`） | 主线：直接继承上游真实历史（242 个提交 SHA 与 etorth/mir2x 一致），在 `a1e65e5` 之后接本仓库 138 个提交 |
| `legacy/main`（`4a4ddb51`） | 旧主线备份：上游历史被重放（SHA 不同）的版本，仅作对比/回退用 |
| `upstream-main` | 上游 `main` 镜像（`f7072661`，2026-11-13），便于在 GitHub 网页查看上游 |
| `v0.1` | 指向上游提交 `a1e65e5`（= 分叉基线，内容树 `2feb38b8`） |
| `base/upstream-2026-07-10` | 同上，基线提交的别名 |

变动方式：不改动任何提交内容，仅把自有提交的父指针从"重放链"（`10c35be`）改挂到上游真实提交 `a1e65e5` 并重算 SHA，
因此 `git diff legacy/main main` 为空（1254 个文件完全相同），分支树逐一核对一致。

之后与上游交互：

```bash
git fetch upstream --prune
git merge-base main upstream/main       # 输出 a1e65e5，即分叉点
git rev-list main --not upstream/main --count   # 本仓库独有提交数
git cherry-pick <upstream-sha>          # 摘取需要的上游修复
```