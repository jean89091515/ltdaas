<!-- ppt-master-schema: design-spec/v1 -->
# yongheng_meeting - Design Spec

## I. Project Information

| Item | Value |
| --- | --- |
| Project Name | 与永恒对接：北京"铁人三项"从业者研究 |
| Canvas Format | PPT 16:9 (1280 × 720) |
| Page Count | 13 |
| Primary Language | zh-CN |
| Target Audience | 冯永恒：联通智慧足迹数据人员、北大在职博士，熟悉 DaaS 表结构、平台合规规则，公司做过用流量和时长识别平台从业者的专利；关心研究是否可行、是否合规、能否对他的博士研究有帮助 |
| Communication Intent | 先用几页讲清背景和研究设想（北京"铁人三项"从业者：边跑单边找工作的有多少、从哪来、干多久、往哪去，平台工作是跳板、缓冲垫还是陷阱）；再逐条请教数据口径和识别方法；最后对齐合作分工与下一步时间表 |
| Desired Audience Outcome | 永恒认可研究价值并愿意一起做；会上逐条回答或认领数据问题（uid 能否跨期追踪、新版 APP 名录、蜂窝/Wi-Fi 口径、能否上传对照表、发表许可、专利方法）；约定他提供新版 APP 名录，我们本周在 DaaS 上跑数据摸底 SQL |
| Core Message / Ask / Action | 用联通 APP 使用加位置数据追踪同一批"铁人三项"从业者，能回答国内外都没解决的"跳板还是陷阱"问题；分析 SQL 已按平台合规规则写好并用模拟数据验证，眼下卡点是 uid 能否跨期追踪和新版 APP 名录 |
| Delivery Context | 主要为线上会议共享屏幕，王良主讲，两人边看边讨论，约 30—45 分钟；次要为会后发给永恒作为对接备忘 |
| Artifact Afterlife | 会后作为合作对接备忘和问题清单留存；部分页面后续可复用于向张所汇报 |
| Reading Mode | balanced |
| Content Strategy | balanced default（未指定改编程度：在保留全部事实的前提下按结论先行重组） |
| Design Style | 研究简报·结论先行（custom mode + custom visual style） |
| AI Image Acquisition Path | not applicable |
| Generation Mode | continuous |
| Spec Refinement | disabled |
| Speaker Notes | enabled — final Stage-2 proactive policy |
| Custom Animations | disabled — final Stage-2 proactive policy |
| Narration Audio | disabled — final Stage-2 proactive policy |
| Created Date | 2026-10-15 |

## II. Canvas Specification

| Property | Value |
| --- | --- |
| Format | PPT 16:9 |
| Dimensions | 1280 × 720 |
| viewBox | `0 0 1280 720` |
| Margins | left/right 64 px, top 48 px, bottom 40 px |
| Content Area | x 64–1216, y 48–680 |

## III. Visual Theme

### Theme Style

- **Mode**: custom
- **Mode References**: pyramid
- **Mode Behavior**: 以 pyramid 为基底：开头两三页交代背景、已有研究的空白和要回答的问题（情境—冲突—问题），研究设想、数据、方法和流程各页以判断句为标题、证据在下；"想请你确认的问题"和"下一步"转为逐条编号的讨论清单，便于会上逐项确认、会后对照。
- **Visual style**: custom
- **Visual Style References**: swiss-minimal, data-journalism
- **Visual Style Behavior**: 由 swiss-minimal 提供模块网格、直角、大留白和左对齐的严谨版式；由 data-journalism 提供细线分隔、页脚来源行、放大的关键数字和紧凑表格；一条深蓝竖向色带划分章节，琥珀色只标注卡点与待确认项，整体平面无阴影。
- **Theme**: 规划研究简报——深蓝网格结构、细线、放大的关键数字，琥珀色只给卡点
- **Tone**: 冷静、专业、坦诚，同行之间的技术对接

### Color Scheme

| Role | HEX | Purpose |
| --- | --- | --- |
| Background | #FFFFFF | 页面底色 |
| Secondary background | #F3F5F8 | 面板、表头、讨论清单底色 |
| Primary | #1B3A5C | 章节色带、标题、关键数字、主要框线 |
| Accent | #E3A21A | 只用于卡点与待确认项（uid 跨期、新版 APP 名录等） |
| Secondary accent | #3E7CB1 | 第二层级强调、流程连接线、标签 |
| Body text | #1E2633 | 正文 |
| Secondary text | #5B6675 | 说明、注释、页脚来源行 |
| Divider | #D5DBE3 | 细线分隔、表格行线 |
| Grid | #E6EAF0 | 比分隔线更浅的辅助网格线 |

## IV. Typography System

### Font Plan

| Role | Character (Reference) | Primary | English if non-English | Fallback tail |
| --- | --- | --- | --- | --- |
| Title | 无衬线、粗体、紧凑 | Microsoft YaHei | Arial | sans-serif |
| Body | 无衬线、常规 | Microsoft YaHei | Arial | sans-serif |
| Code | 等宽，用于表名、字段、SQL 文件名 | Consolas | Consolas | monospace |

- **Title stack**: "Microsoft YaHei", Arial, sans-serif
- **Body stack**: "Microsoft YaHei", Arial, sans-serif
- **Code stack**: Consolas, "Microsoft YaHei", monospace
- **Role rationale**: 表名、字段、SQL 步骤在第 7、8、10、12 页反复出现，用等宽字体与正文区分，便于对方对照系统里的实际名称。

### Font Size Hierarchy

| Purpose | Anchor Size (px) |
| --- | ---: |
| Body | 24 |
| Title | 42 |
| Subtitle | 32 |
| Annotation | 18 |
| Hero number | 48 |
| Code | 18 |
| Footnote | 14 |

## V. Layout Principles

### Deck-wide Direction

- **Hierarchy direction**: 左上判断句标题 → 一行要点 → 下方证据（表格、编号清单、流程、关键数字）→ 页脚来源行
- **Composition tendency**: 模块网格、左对齐、直角；章节用左侧深蓝竖向色带标识；关键数字放大成为视觉锚点；表格与清单用细线而非卡片阴影
- **Cross-page continuity**: 左侧深蓝细色带与章节标签、页脚来源行和页码在内容页重复；琥珀色圆点或细条只出现在待确认/卡点位置
- **Spacing posture**: 内容页偏紧凑但网格清晰；封面、议程、成果页留白更多
- **Spacing anchors**: page margin 64 px · block gap 24 px · column gutter 32 px · corner radius 0 px · body leading 36 px

## VI. Icon Usage Specification

- **Primary bundled library**: tabler-outline
- **Stroke Width**: 2

| Icon Path | Suitable Scenarios |
| --- | --- |
| icons/tabler-outline/database.svg | |
| icons/tabler-outline/map-pin.svg | |
| icons/tabler-outline/device-mobile.svg | |
| icons/tabler-outline/briefcase.svg | |
| icons/tabler-outline/search.svg | |
| icons/tabler-outline/clock.svg | |
| icons/tabler-outline/alert-triangle.svg | |
| icons/tabler-outline/check.svg | |
| icons/tabler-outline/users.svg | |
| icons/tabler-outline/file-text.svg | |
| icons/tabler-outline/route.svg | |
| icons/tabler-outline/motorbike.svg | |
| icons/tabler-outline/truck-delivery.svg | |
| icons/tabler-outline/car.svg | |
| icons/tabler-outline/package.svg | |
| icons/tabler-outline/id.svg | |
| icons/tabler-outline/wifi.svg | |
| icons/tabler-outline/lock.svg | |
| icons/tabler-outline/table.svg | |
| icons/tabler-outline/code.svg | |
| icons/tabler-outline/calendar.svg | |
| icons/tabler-outline/flag.svg | |
| icons/tabler-outline/help-circle.svg | |
| icons/tabler-outline/arrow-right.svg | |
| icons/tabler-outline/building-factory-2.svg | |
| icons/tabler-outline/building-skyscraper.svg | |
| icons/tabler-outline/home.svg | |
| icons/tabler-outline/user-search.svg | |
| icons/tabler-outline/target.svg | |
| icons/tabler-outline/circle-check.svg | |
| icons/tabler-outline/list-check.svg | |

## VII. Visualization Reference List

| Page | Family | Template | Usage |
| --- | --- | --- | --- |
| P07 | table | record_table | 联通 DaaS 各表的用途与关键字段 |
| P11 | table | record_table | 三篇论文的内容、数据、目标期刊与时间 |

## VIII. Image Resource List

| Filename | Dimensions | Ratio | Purpose | Type | Layout pattern | Crop Policy | Acquire Via | Status | Reference | text_policy | page_role |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

## IX. Content Outline

### Part 1: 开场

#### Slide 01 - 封面

- **Audience move**: 刚进会议 → 一眼知道今天讨论的核心问题和对接对象
- **Relationships**: none
- **Layout**: 左侧大号问句作为视觉中心，深蓝竖向色块划出一侧；下方一行副标题与会议信息
- **Title**: 跳板，还是陷阱？
- **Core message**: 用联通 APP 加位置数据追踪北京"铁人三项"从业者，回答平台工作是跳板还是陷阱
- **Content**: 主标题"跳板，还是陷阱？" · 副标题"用联通 APP + 位置数据追踪北京'铁人三项'从业者" · 与智慧足迹对接讨论 · 王良｜北京市城市规划设计研究院 · 2026-10-15 线上会议
- **Cover impact**: 钩子是"跳板，还是陷阱？"这个尚无答案的问题（binding）；构图为大字问句加一侧深蓝色块，三种骑手、快递、网约车图标作为小标记（Reference）

#### Slide 02 - 今天想达成什么

- **Audience move**: 不清楚会议要多久、要他做什么 → 知道四段议程和需要他给出的三项回应
- **Relationships**: order（四段议程依次进行）；membership（三项期望归属于会议目标）
- **Layout**: 左侧四段议程时间线，右侧三项"希望会后达成"
- **Title**: 今天想达成三件事：认可思路、厘清数据口径、约定下一步
- **Content**: 议程：背景与研究问题（约 8 分钟）/ 数据与识别方法（约 10 分钟）/ 想请你确认的问题（约 15 分钟）/ 分工与下一步（约 7 分钟）· 期望：你看研究值不值得一起做 · 逐条回答或认领数据问题 · 约定新版 APP 名录与本周摸底

### Part 2: 背景与研究问题

#### Slide 03 - 已经做了什么

- **Audience move**: 不了解我们的前期基础 → 知道全国底数已完成，北京个体动态是自然的下一步
- **Relationships**: order（全国数据集 → 分析论文 → 灵活就业测算 → 北京个体动态）
- **Layout**: 三个已完成成果并列，各配一个关键数字；右侧箭头指向"下一步：北京个体动态"
- **Title**: 全国底数已经做完，下一步从县域静态走到北京个体动态
- **Content**: 起因：张所关心灵活就业，领导要求做就业数据系列研究 · CMEP-2020 全国多尺度就业人口数据集：2989 个县级单元、20 个行业 7 个职业；官方口径 7.51 亿就业人员；已投《中国科学数据》· 《规模与等级》就业职能标度论文：2189 个城镇单元；已投《地理学报》· 个体经营型灵活就业测算：约 1.71 亿人，占非农就业 29.8%；在写 · 下一步：用联通 DaaS 从个体角度识别平台从业者
- **Visualization**: 三个关键数字（2989 个单元、7.51 亿、1.71 亿）

#### Slide 04 - 研究对象与问题

- **Audience move**: 只知道题目 → 清楚研究对象是哪三类人、要回答哪六个问题
- **Relationships**: membership（外卖即配、快递、网约车属于"铁人三项"，货运代驾为补充）；order（六个问题从规模到去向依次展开）
- **Layout**: 上方三类对象并列（图标 + 名称），下方六个编号问题两列
- **Title**: "铁人三项"是灵活就业的主力方向，但没人知道他们从哪来、往哪去
- **Content**: 对象：外卖骑手（含即时配送、跑腿）/ 快递员 / 网约车司机；货运、代驾为补充 · 问题：① 有多少、2019—2025 年怎么变、兼做两类以上的有多少 ② 是谁：年龄、性别、户籍来源、收入档、住在哪 ③ 有多少人边跑单边找工作，用蓝领、综合还是白领求职渠道 ④ 从哪来：进入前在工厂、写字楼、商业区上班，没有固定工作，还是刚来北京 ⑤ 干多久：能连续几个季度 ⑥ 往哪去：回到固定岗位、转做别的平台、无固定工作，还是离开北京

#### Slide 05 - 核心检验：跳板、缓冲垫还是陷阱

- **Audience move**: 把研究看作描述统计 → 理解它有一个可检验的核心命题，以及数据怎么区分三种答案
- **Relationships**: contrast（跳板、缓冲垫、陷阱三种假说各自对应不同的数据信号）
- **Layout**: 三个假说并列成三栏，每栏"含义"在上、"数据里会看到什么"在下；底部一句中年人分组
- **Title**: 核心问题可检验：平台工作是跳板、缓冲垫，还是陷阱
- **Content**: 跳板：边跑边找，之后回到正式岗位 —— 跑单期间用求职 APP 的人，下一期回到固定工作地的更多 · 缓冲垫：失业后的临时收入 —— 进入前固定工作地消失，短期跑单后退出 · 陷阱：跑得越久越回不去 —— 回到固定岗位的概率随平台工作持续期数下降 · 再看：35 岁、45 岁以上的中年人是否更难回去

#### Slide 06 - 已有研究做到哪一步

- **Audience move**: 以为这个题别人做过 → 知道国内外都看不到同一个人的完整轨迹，这正是联通数据的用武之地
- **Relationships**: contrast（国内问卷 vs 国外税务财务数据）；link（两类研究的共同短板指向本研究的空白）
- **Layout**: 左右两栏对比国内与国外，国内栏放大三个关键数字；底部一条横贯全页的"空白"结论带
- **Title**: 国内靠问卷、国外靠税务数据，都看不到同一个人的完整轨迹
- **Content**: 国内（问卷、回忆式、单一平台）：美团研究院——当骑手前 24.8% 在工厂打工 · 孙萍《过渡劳动》——北京外卖员仅 12.9% 愿意一直送，超八成打算两年内换工作 · 南开大学 4.1 万份调查——平均从业不足 12 个月 · 国外（税务、财务数据）：Koustas 2019——进入网约车前收入和资产先下滑 · Fos 等 2019——Uber 进城后被裁员工更少依赖失业金 · Huang 等 2020——失业率上升，线上零工参与增加 · 共同短板：看不到退出后去了哪里，看不到求职和跨平台 · 最接近的：Qiao 等 2023 用手机轨迹识别成都网约车司机居住地；波兰组用 APP 测规模（预印本）
- **Visualization**: 三个关键数字（24.8%、12.9%、<12 个月）

### Part 3: 数据与方法

#### Slide 07 - 数据基础

- **Audience move**: 不确定我们打算用哪些表 → 看到四张表各自承担的作用，可以直接指出口径问题
- **Relationships**: membership（各表共同组成识别所需信息：APP、属性、停留、出行、网格）
- **Layout**: 一张紧凑表格占主体，右侧或顶部一句"每年 3、6、9、12 月，北京"
- **Title**: 联通 DaaS 几张表就能拼出"用什么 APP、住哪、在哪干活、户籍从哪来"
- **Content**: 范围：北京，每年 3、6、9、12 月 · user_app：每人每月每个 APP 的时长、流量 → 识别平台工作、求职、兼职 · user_attribute：年龄段、性别、身份证前 6 位、通讯费、是否本地、核心用户、扩样权重 → 人群画像、户籍来源 · stay_poi：月度停留点及工作日白天、夜间停留时长 → 有无固定工作地、居住地 · move_month：出行次数、距离、时长 → 校验"在路上干活" · ss_city_grid：250 米网格 → 区县、街道
- **Visualization**: daas-tables（表 / 字段 / 用途 的记录表，table/record_table）
- **Native-ready**: daas-tables=yes

#### Slide 08 - 识别方法

- **Audience move**: 不知道怎么判定"是不是骑手" → 理解以 APP 时长为主、停留行为为辅的状态判定，并愿意分享专利经验
- **Relationships**: order（先看平台 APP 时长，再看固定工作地，最后归入其他）；membership（七种状态构成每期每人的分类）
- **Layout**: 左侧判定顺序（三步），右侧七种状态标签；底部琥珀色一行"想请教：专利里流量 + 时长的阈值经验"
- **Title**: 以工作端 APP 时长为主、停留行为为辅，判定每期每个人的状态
- **Content**: 第一步：某类工作端 APP 当月使用 ≥ 50 小时 → 平台从业者；几类都满足取时长最多的一类并记为兼做；敏感性 20、100 小时 · 第二步：有工作地且工作日白天停留 ≥ 40 小时/月 → 固定工作 · 第三步：其余 → 无固定工作 · 状态：G1 外卖即配 / G2 网约车 / G3 快递 / G4 货运代驾 / F 固定工作 / N 无固定工作 / X 本期不在库 · 求职渠道：蓝领（58 找工作、斗米）/ 综合（BOSS 直聘、智联、前程无忧）/ 白领（拉勾、猎聘、脉脉、LinkedIn）· 行为校验：重度工作端 APP 用户应停留点多、无固定工作地、出行时长长 · 想请教：你们专利里用流量 + 时长识别的思路和阈值

#### Slide 09 - APP 名录现状

- **Audience move**: 以为名录已经够用 → 看清旧名录已覆盖什么、还缺哪些新平台，明白为什么需要新版名录
- **Relationships**: membership（APP 按骑手端、司机端、货运、求职、兼职分组）；contrast（已找到 vs 待确认）
- **Layout**: 左侧五组"已找到"，右侧琥珀色"待确认"一栏
- **Title**: 旧名录已找到主要工作端和求职 APP，新平台和快递作业端还要确认
- **Content**: 旧名录约 2018—2020 年（还有摩拜、虾米音乐）· 骑手端：美团骑手、达达骑士版、顺丰骑士、闪送员、点我达骑手、UU 跑腿跑男端 · 司机端：滴滴车主、美团打车司机端、首约司机、曹操司机、花小猪司机端、嘀嗒出租司机 · 货运：货拉拉司机版、快狗打车车主、运满满司机 · 求职：BOSS 直聘、智联招聘、前程无忧、58 找工作、斗米、拉勾、猎聘、脉脉、LinkedIn · 兼职：兼职猫、口袋兼职、青团社 · 待确认：京东秒送骑手、美团众包、蜂鸟众包 / 快递公司作业 APP（中通、圆通、京东小哥等）/ 专业接单平台（猪八戒、程序员客栈）

#### Slide 10 - 分析流程与合规设计

- **Audience move**: 担心分析是否合规、能否在系统里跑 → 看到四步流程、每步导出什么，以及合规规则和验证结果
- **Relationships**: order（00 数据摸底 → 01 状态表 → 02 截面汇总 → 03 转移汇总）；parent（合规规则约束全部四步）
- **Layout**: 上方四步横向流程，每步下注明导出内容；下方左侧合规四条，右侧验证结果的关键数字
- **Title**: 四步 SQL 已写好并验证：uid 只在系统内建表，只导出汇总
- **Content**: 00 数据摸底：月份覆盖、uid 能否跨期、APP 名录、时长分布、行为校验 → 6 张小表 · 01 状态表：每期每人的属性、四类平台时长、求职渠道、停留出行、居住与工作网格、状态 → 5 张检查表 · 02 截面汇总：每期按状态 × 年龄 × 户籍 × 求职渠道 × 区县，拼成全期面板 → 每期 10 张、趋势 5 张 · 03 转移汇总：相邻期转移、从业段（从哪来、干多久、往哪去）、人期表、进入和退出前后各 4 期轨迹 → 约 20 张 · 合规：含 uid 的语句一律 CREATE TABLE；导出不含 uid，uid 只在 count() 里；每张 ≤ 1 万行（实际最大约 5300 行），少于 15 人显示"≤15"；不能 drop，表名带 _v1、_v2 · 验证：4 个文件 95 条语句全部合规、Hive/Spark 语法通过；模拟数据下 886 个从业段与独立计算完全一致

### Part 4: 成果与对接

#### Slide 11 - 预期成果

- **Audience move**: 不清楚做完能出什么 → 看到三篇论文的定位和时间，以及对他博士研究的价值
- **Relationships**: order（论文 1 → 论文 2 → 论文 3 按时间推进）
- **Layout**: 一张三行记录表占主体；右下一句"对你：共同署名，可服务博士研究"
- **Title**: 两篇主稿一条时间线：中文核心 2027 年 2 月，SCI 2027 年 7 月
- **Content**: 论文 1（中文核心）：北京平台劳动者的规模、构成与求职行为（2019—2025）；《人口研究》《人口与经济》《地理研究》《城市规划学刊》；2027-02 投稿 · 论文 2（SCI）：季度追踪，跳板、缓冲垫还是陷阱；Urban Studies、EPA、China Economic Review、Cities；2027-07 投稿 · 论文 3（可选）：2025 年外卖大战冲击下的进入与切换；2027 下半年 · 对你：共同署名，可服务博士研究
- **Visualization**: papers（论文 / 内容 / 期刊 / 时间 的记录表，table/record_table）
- **Native-ready**: papers=yes

#### Slide 12 - 想请你确认的问题

- **Audience move**: 不知道我们卡在哪 → 逐条看到十个问题，先回答两个最关键的
- **Relationships**: membership（十个问题分属数据口径、识别方法、系统规则、发表合作）；contrast（两个关键卡点 vs 其余问题）
- **Layout**: 十个编号问题两列排开，第 1、3 条用琥珀色标为关键卡点
- **Title**: 十个问题里，新版 APP 名录和 uid 能否跨期追踪最关键
- **Content**: ① 新版 APP 名录与上网标签码表（近两年北京，名称、标签、≥15 人的用户数）【关键】 ② user_app 历年 3、6、9、12 月是否都有，ltime、lflux 口径是否变过，是否只统计蜂窝流量 ③ uid 能否跨月、跨年对上【关键】 ④ is_core、weight 的定义，一人多卡怎么处理 ⑤ 整天流动的骑手、司机会不会被判出 ptype=2 工作地；30 分钟驻留规则的影响；ptype=3 是什么 ⑥ 快递公司作业 APP、京东秒送、美团众包能否识别 ⑦ 能否上传自己的对照表（fnid → 街道、环路、用地类型、城中村），像以前的 wl_code ⑧ 系统是否支持 coalesce、窗口函数，单次运行有无时长或资源限制 ⑨ 用聚合结果发表论文需要什么流程，是否要公司书面同意 ⑩ 你们识别平台从业者的专利号和方法要点，论文里引用

#### Slide 13 - 合作方式与下一步

- **Audience move**: 讨论结束前 → 明确分工，带走本周就要做的两件事
- **Relationships**: order（本周 → 10 月底 → 11 月 → 12—1 月 → 2—6 月）；membership（分工分属永恒与王良）
- **Layout**: 上方左右两栏分工，下方横向时间线；最显眼处是"本周"两件事
- **Title**: 建议分工：你把关口径与方法，我们负责 SQL、分析与写作
- **Content**: 永恒：数据口径与识别方法把关（结合专利经验）、平台运行规则把关、参与论文写作，共同署名 · 王良：研究设计、SQL、分析、出图、论文起草 · 节奏：每两周线上碰一次 · 本周：你提供新版 APP 名录；我们在 DaaS 上跑 00 数据摸底 · 10 月底：定稿 APP 清单和阈值，确认 uid 追踪情景 · 11 月：跑 01 状态表、02 截面汇总，与公开数据校验 · 12 月—2027 年 1 月：论文 1 分析写作，2 月投稿 · 2027 年 2—6 月：03 转移汇总与论文 2，7 月投稿
- **Closing impact**: 带走的结论是"本周：新版 APP 名录 + 00 数据摸底"（binding）；时间线收束全页（Reference）

## X. Speaker Notes Requirements

- **Generation**: enabled
- **Filename**: match each SVG filename under `notes/`
- **Content**: 依据 `sources/与永恒对接_会议素材.md`，每页补充讲解要点与过渡语；问题页给出提问顺序建议；不引入素材以外的事实
- **Total duration**: 约 40 分钟（30—45 分钟）
- **Notes style**: conversational（同行间的技术对接，口语化、直接）
- **Presentation purpose**: 先讲清背景和研究设想，再逐条请教数据口径和识别方法，最后对齐合作分工与下一步
