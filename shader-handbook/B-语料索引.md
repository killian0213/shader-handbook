# 附录 B · 语料索引

> 按效果类型检索语料库中的高赞作品。点赞数来自 `analysis/buckets.md`；路径均相对于 `shaders/shaders/`。
>
> **只列已核实存在的文件夹。** 需要细拆步骤时跳到 [第 18 章](18-效果配方大全.md)。

---

## B.1 文件夹命名规则

```
000787-MdX3Rr-Elevated
│      │      │
│      │      └─ 标题（空格等变成下划线）
│      └─ Shadertoy ID（URL 里 view/ 后面那段）
└─ 点赞数，左边补零到 6 位
```

因此：

- 按文件夹名排序 ≈ 按人气排序（同赞再比 ID）。
- 浏览器打开：`https://www.shadertoy.com/view/<ID>`，例如 Elevated → `https://www.shadertoy.com/view/MdX3Rr`。
- 本地阅读：优先 `image.glsl`；多 Pass 再看 `buffer_a.glsl` / `common.glsl` / `meta.json`。

本手册引用格式：

> 📄 出自 `002224-Ms2SD1-Seascape/image.glsl`（TDM）

---

## B.2 分桶说明（来自 buckets.md）

| 桶 | 规模 | 本附录侧重 |
|---|--:|---|
| `A_2d_basics` | 485 | 雨窗、火、涟漪、霓虹、CRT、假流体入口 |
| `L_nature` | 400 | 海、地形、云、雨雪、火、森林 |
| `M_space` | 149 | 星空、银河、行星、黑洞 |
| `N_scenes` | 394 | 城市、隧道、洞穴、角色、游戏场景 |

同一作品可能出现在多个桶；下表按**效果**归类，不保证互斥。

---

## B.3 海洋 / 水面

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 2224 | `002224-Ms2SD1-Seascape` | TDM | 程序海标杆 |
| 680 | `000680-MdXyzX-Very_fast_procedural_ocean` | afl_ext | 更快近似 |
| 506 | `000506-MdlXz8-Tileable_Water_Caustic` | Dave_Hoskins | 焦散 |
| 485 | `000485-4tjGRh-Planet_Shadertoy` | reinder | 行星海 |
| 385 | `000385-4sXBRn-Luminescence` | BigWIngs | 水下 |
| 324 | `000324-4sXGRM-Oceanic` | frankenburgh | 海天一体 |
| 305 | `000305-lsXGzH-Spout` | P_Malin | 折射水柱 |
| 231 | `000231-NdS3zK-OCEAN_ELEMENTAL` | alro | SSS 海 |

---

## B.4 地形 / 山脉 / 峡谷

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 787 | `000787-MdX3Rr-Elevated` | iq | 高度场教科书（看 buffer） |
| 456 | `000456-llsGW7-_2TC_15_Mystery_Mountains` | Dave_Hoskins | 神秘山 |
| 435 | `000435-MdGfzh-Himalayas` | reinder | 山 + 体积大气 |
| 305 | `000305-MdBGzG-Canyon` | iq | 峡谷 |
| 305 | `000305-4slGD4-Mountains` | Dave_Hoskins | 山脉 |
| 292 | `000292-Xs33Df-Desert_Canyon` | Shane | 沙漠峡谷 |
| 249 | `000249-ttXGWH-Abstract_Terrain_Objects` | Shane | 抽象地形物 |
| 190 | `000190-7ljcRW-Terrain_Erosion_Noise` | Fewes | 侵蚀 |

---

## B.5 雨 / 玻璃 / 涟漪

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 1078 | `001078-ltffzl-Heartfelt` | BigWIngs | 雨打玻璃 |
| 789 | `000789-MdfBRX-The_Drive_Home` | BigWIngs | 雨夜车窗 |
| 293 | `000293-XlsGRs-jetstream` | srtuss | 雨云闪电 |
| 292 | `000292-ldfyzl-Rainier_mood` | Zavie | 涟漪 |
| 260 | `000260-Xtf3zn-Tokyo` | reinder | 雨城 |
| 220 | `000220-ltccRl-Outrun_The_Rain` | irwatts | 粒子雨 |
| 62 | `000062-ldSBWW-Rain_drops_on_screen` | — | 屏上雨滴 |

---

## B.6 雪 / 冰

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 229 | `000229-XltGRX-Frozen_Barrens` | knarkowicz | 冰原行星 |
| 224 | `000224-Xsd3zf-Miracle_Snowflakes` | foxes | 雪花 SDF |
| 152 | `000152-4s33zf-Over_the_Moon` | BigWIngs | 冬夜 2D |
| 140 | `000140-Mdt3Df-Snow_as_shown_in_sweden_` | — | 雪景 |
| 117 | `000117-4dl3R4-Snowy` | — | 雪 |
| 116 | `000116-ldsGDn-Just_snow` | — | 简雪 |
| 66 | `000066-MscXD7-Simple_snow_and_blizard` | — | 暴风雪入门 |

（Elevated 的积雪逻辑在地形着色内，见 B.4。）

---

## B.7 火 / 岩浆 / 火花

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 729 | `000729-llK3Dy-Rhodium_liquid_carbon` | Virgill | 液态金属火感 |
| 468 | `000468-MlKSWm-Sparks_drifting` | Sjeiti | 火花粒子 |
| 392 | `000392-XsXSWS-Fires` | xbe | 2D 火焰 |
| 283 | `000283-Wtc3W2-Campfire_at_night` | Maurogik | 营火 |
| 236 | `000236-4tlSzl-Combustible_Voronoi` | Shane | Voronoi 燃烧 |
| 226 | `000226-lslXRS-Noise_animation_-_Lava` | nimitz | 岩浆噪声 |
| 226 | `000226-3XXSWS-3D_Fire_340_` | Xor | 3D 火高尔夫 |
| 195 | `000195-4ttGWM-301_s_Fire_Shader_-_Remix_3` | mu6k | 焰 |

---

## B.8 烟 / 雾尘 / 体积光

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 488 | `000488-4tGfDW-Chimera_s_Breath` | nimitz | 流体烟 |
| 477 | `000477-WlVyRV-Dry_ice_2` | xjorma | 干冰雾 |
| 452 | `000452-4ts3z2-Xyptonjtroz` | nimitz | 尘暴体积 |
| 418 | `000418-tdjBR1-Volumetric_lighting` | tmst | 体积光 |
| 192 | `000192-tflBDM-Chill_Smoke_Orb` | diatribes | 烟团 |
| 162 | `000162-cl23Wt-Curling_Smoke` | leon | curl 烟 |
| 148 | `000148-MdjGWc-smoke_columns` | — | 烟柱 |

---

## B.9 云 / 天空大气

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 769 | `000769-ldlcRf-Tribute_-_Journey_` | Shakemayster | 球形云 |
| 435 | `000435-MdGfzh-Himalayas` | reinder | 高山云海 |
| 433 | `000433-4dSBDt-Enscape_Cube` | ThomasSchander | 云海立方 |
| 295 | `000295-ldyXRw-Tiny_Planet_Clouds` | valentingalea | 行星云 |
| 230 | `000230-ttcSD8-Swiss_Alps` | piyushslayer | 阿尔卑斯 |
| 230 | `000230-ldS3Wm-doski_canady` | w23 | 环绕云 |
| 229 | `000229-tdSXzD-The_sun_the_sky_and_the_clouds` | stilltravelling | 日天空云 |

---

## B.10 闪电 / 电

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 631 | `000631-XXyGzh-Zippy_Zaps_394_Chars_` | SnoopethDuckDuck | 短码电弧 |
| 293 | `000293-XlsGRs-jetstream` | srtuss | 雷雨 |
| 163 | `000163-WscyWB-LIGHTNING` | alro | 风暴闪电 |
| 68 | `000068-dsXfDn-fbm_lightning` | — | fbm 电 |

---

## B.11 极光

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 724 | `000724-XtGGRt-Auroras` | nimitz | 极光标杆 |
| 229 | `000229-tdSXzD-The_sun_the_sky_and_the_clouds` | stilltravelling | 含 aurora 标签 |
| 180 | `000180-tl3GW2-Portal_1` | tmst | 门+极光 |
| 133 | `000133-M3dSzs-Aurora_399_chars_` | kishimisu | 短码 |
| 119 | `000119-4dtSzX-Aurora_Explorer_re_` | — | 探索向 |

---

## B.12 星空 / 银河 / 太空

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 1157 | `001157-XlfGRj-Star_Nest` | Kali | 体积星野 |
| 646 | `000646-lscczl-The_Universe_Within` | BigWIngs | 宇宙飞穿 |
| 490 | `000490-lstSRS-Gargantua_With_HDR_Bloom` | sonicether | 黑洞 |
| 477 | `000477-4dXGR4-Main_Sequence_Star` | flight404 | 恒星 |
| 437 | `000437-Xsl3zX-galaxy3` | FabriceNeyret2 | 银河错觉 |
| 383 | `000383-Xdl3D2-Interstellar` | TekF | 星野 |
| 361 | `000361-MdKXzc-Supernova_remnant` | Duke | 超新星遗迹 |
| 334 | `000334-DtdSz7-STELLAR_CLOUDS` | alro | 恒星云 |
| 294 | `000294-MdXSzS-Galaxy_of_Universes` | Dave_Hoskins | 多重宇宙 |
| 192 | `000192-stBcW1-Stars_and_galaxy` | mrange | 2D 星河 |

---

## B.13 隧道 / 走廊

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 415 | `000415-MlXSWX-Abstract_Corridor` | Shane | 抽象走廊 |
| 333 | `000333-WfcGWj-Trailing_the_Twinkling_Tunnel_` | mrange | 闪烁隧道 |
| 269 | `000269-tdjfDR-Traced_Tunnel` | Shane | 追踪隧道 |
| 258 | `000258-XdBSzd-Tissue` | iq | 2D 有机隧道 |
| 201 | `000201-4lyGzR-Biomine` | Shane | 生物矿脉 |
| 201 | `000201-4slyRs-Alien_corridor` | zguerrero | 异形走廊 |
| 192 | `000192-MscSDB-Cellular_Tiled_Tunnel` | Shane | 细胞隧道 |
| 180 | `000180-4scXzn-Winding_Menger_Tunnel` | Shane | Menger 隧道 |

---

## B.14 城市 / 夜景

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 424 | `000424-XtsSWs-Skyline` | otaviogood | 天际线 |
| 294 | `000294-cdG3Wd-Dust_417_Chars_` | Xor | 尘中城市感 |
| 260 | `000260-Xtf3zn-Tokyo` | reinder | 东京雨夜 |
| 230 | `000230-wdfGW4-Descent_3D` | mhnewman | 霓虹下降 |
| 221 | `000221-fdSGWw-Reclaim_the_streets` | evvvvil | 等距街景 |
| 168 | `000168-MdXGW2-Venice` | reinder | 威尼斯 |
| 164 | `000164-MljXzz-Isometric_City_2.5D` | knarkowicz | 等距城 |
| 153 | `000153-4df3DS-Infinite_City` | — | 无限城 |

---

## B.15 洞穴 / 地下

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 175 | `000175-XdcfDf-Underground_Passageway` | Shane | 地下通道 |
| 140 | `000140-MsX3RH-The_Cave` | BoyC | 洞穴 |
| 131 | `000131-Xtt3Wn-Fractal_Cave` | iq | 分形洞 |
| 61 | `000061-Xsd3z7-Cave_Pillars` | — | 石柱 |
| 214 | `000214-ss3SD8-20210930_CLUB-CAVE-09` | 0b5vr | Club cave |

---

## B.16 森林 / 自然场景

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 1339 | `001339-4ttSWf-Rainforest` | iq | 雨林巨作 |
| 594 | `000594-fstyD4-Coastal_Landscape` | bitless | 2D 海岸 |
| 465 | `000465-Wt33Wf-Cyber_Fuji_2020` | kaiware007 | 合成波富士 |
| 378 | `000378-tdjyzz-Tree_in_the_wind` | Maurogik | 风中树 |
| 352 | `000352-fsXXzX-English_Lane` | blackjero | 林荫路 |
| 199 | `000199-Xsf3zX-Rolling_hills` | Dave_Hoskins | 丘陵草 |
| 176 | `000176-llcSz8-Kelp_Forest` | BigWIngs | 海底森林 |
| 115 | `000115-4dl3z7-Haunted_Forest` | frankenburgh | 鬼林 |

---

## B.17 角色 / 生物 / 器官

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 769 | `000769-ldlcRf-Tribute_-_Journey_` | Shakemayster | 旅人 |
| 238 | `000238-csB3zy-Sea_Creature` | iq | 海生生物 |
| 217 | `000217-MsKBDG-_SH18_The_Eye` | knarkowicz | 眼睛 |
| 253 | `000253-lsXcWn-Smiley_Tutorial` | BigWIngs | 表情教程 |
| 177 | `000177-4XsfDs-DULL_SKULL_-_Prologue` | Katur | 骷髅 |

---

## B.18 霓虹 / 辉光 / UI 感

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 329 | `000329-DtXfDr-Discoteq_2` | supah | 光带 |
| 324 | `000324-MsVfz1-Neon_Lit_Hexagons` | Shane | 霓虹六边 |
| 302 | `000302-4sGSDw-Sinuous` | nimitz | 霓虹假流体 |
| 256 | `000256-WdK3Dz-NEON_LOVE` | alro | 霓虹心 |
| 354 | `000354-4s2SRt-Oblivion_radar` | ndel | 雷达 UI |
| 229 | `000229-MlscDj-Neon_World` | zguerrero | 霓虹世界 |

---

## B.19 流体（真 / 假）

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 697 | `000697-tsKXR3-Multiscale_MIP_Fluid` | cornusammonis | MIP 流体 |
| 626 | `000626-MsGSRd-spilled` | flockaroo | 倾洒 |
| 488 | `000488-4tGfDW-Chimera_s_Breath` | nimitz | 烟尘流体 |
| 469 | `000469-WdVXWy-molten_bismuth` | flockaroo | 熔融 |
| 365 | `000365-XddSRX-Suture_Fluid` | cornusammonis | 粘性指进 |
| 302 | `000302-4sGSDw-Sinuous` | nimitz | **假流体**心法 |
| 133 | `000133-mlsSWH-Visualizing_Curl_Noise` | Shane | curl 可视化 |

---

## B.20 传送门 / Droste / Escher

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 180 | `000180-tl3GW2-Portal_1` | tmst | 传送门 |
| 158 | `000158-Mdf3zM-Escher_s_prentententoonstelling` | reinder | Escher Droste |
| 182 | `000182-XlBXWw-Quasi_Infinite_Zoom_Voronoi_` | — | 准无限缩放 |
| 106 | `000106-lfGczc-Droste_3D` | — | 3D Droste |
| 101 | `000101-wf3BWM-_Arcane_Portal_` | — | 奥术门 |
| 94 | `000094-MsySD3-SquarePortals` | — | 方门 |
| 84 | `000084-lcdcRM-Droste_Cyclic_Expansion_Spiral` | — | 螺旋 Droste |
| 65 | `000065-lcfyDj-BlackHole_swirl_portal_` | — | 漩涡门 |

---

## B.21 CRT / 复古 / 像素

| 赞 | 文件夹 | 作者 | 备注 |
|--:|---|---|---|
| 537 | `000537-XtlSD7-_SIG15_Mario_World_1-1` | knarkowicz | 马里奥 |
| 400 | `000400-4dlyWX-Meta_CRT` | P_Malin | Meta CRT |
| 272 | `000272-XdtfzX-vt220_coding_at_night_edition` | sprash3 | VT220 |
| 210 | `000210-XsjSzR-FixingPixelArt` | TimothyLottes | 像素修复 |
| 189 | `000189-XltGDr-_SH16C_Contra` | knarkowicz | 魂斗罗 |
| 127 | `000127-DtscRf-GM_Shaders_CRT` | — | CRT |

---

## B.22 2D 基本功高赞（A_2d_basics 精选）

学基础时优先这一组（完整列表见 `analysis/buckets.md` 的 `A_2d_basics`）：

| 赞 | 文件夹 | 看点 |
|--:|---|---|
| 1078 | `001078-ltffzl-Heartfelt` | 雨窗综合技 |
| 594 | `000594-fstyD4-Coastal_Landscape` | 2D 风景分层 |
| 581 | `000581-ll2GD3-Palettes` | 余弦调色板 |
| 579 | `000579-lsl3RH-Warping_-_procedural_2` | 域扭曲 |
| 537 | `000537-XtlSD7-_SIG15_Mario_World_1-1` | 精灵场景 |
| 445 | `000445-ldl3W8-Voronoi_-_distances` | Voronoi |
| 440 | `000440-4dfXDn-2d_signed_distance_functions` | 2D SDF 库 |
| 392 | `000392-XsXSWS-Fires` | 火 |
| 302 | `000302-4sGSDw-Sinuous` | 假流体 |
| 292 | `000292-ldfyzl-Rainier_mood` | 涟漪 |
| 256 | `000256-WdK3Dz-NEON_LOVE` | 霓虹 SDF |

---

## B.23 自然桶头名（L_nature Top）

直接从 buckets 头部抄的「必刷清单」：

1. `002224-Ms2SD1-Seascape`
2. `001078-ltffzl-Heartfelt`
3. `000789-MdfBRX-The_Drive_Home`
4. `000787-MdX3Rr-Elevated`
5. `000769-ldlcRf-Tribute_-_Journey_`
6. `000729-llK3Dy-Rhodium_liquid_carbon`
7. `000697-tsKXR3-Multiscale_MIP_Fluid`
8. `000680-MdXyzX-Very_fast_procedural_ocean`
9. `000631-XXyGzh-Zippy_Zaps_394_Chars_`
10. `000594-fstyD4-Coastal_Landscape`
11. `000435-MdGfzh-Himalayas`
12. `000392-XsXSWS-Fires`

---

## B.24 怎么继续挖

1. 打开 `analysis/buckets.md`，按桶浏览标签列（`water`/`clouds`/`city`…）。
2. 用系统搜索文件夹名关键词：`*Rain*`、`*Cloud*`、`*Neon*`。
3. 读代码用第 0 章「逆向阅读法」：先看 `mainImage` 末尾，再认 `map`/`trace` 骨架。
4. 效果步骤回查 [第 18 章](18-效果配方大全.md)；函数复制用 [附录 A](A-函数速查表.md)。
