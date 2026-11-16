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