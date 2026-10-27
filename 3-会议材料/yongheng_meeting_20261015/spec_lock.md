<!-- ppt-master-schema: spec-lock/v1 -->
# Execution Lock

## canvas
- viewBox: 0 0 1280 720
- format: PPT 16:9

## communication
- primary_language: zh-CN
- audience: 冯永恒（联通智慧足迹数据人员、北大在职博士，熟悉 DaaS 表结构与合规规则，公司有识别平台从业者的专利）
- objective: 讲清北京"铁人三项"研究设想并逐条请教数据口径与识别方法，使永恒认可并愿意合作、会上回答或认领数据问题，并约定他提供新版 APP 名录、我们本周跑数据摸底 SQL
- core_message: 用联通 APP 使用加位置数据追踪同一批"铁人三项"从业者，能回答"跳板还是陷阱"；SQL 已按合规规则写好并验证，卡点是 uid 能否跨期追踪和新版 APP 名录
- consumption_mode: balanced

## mode
- mode: custom
- mode_references: pyramid
- mode_behavior: 以 pyramid 为基底：开头两三页交代背景、已有研究的空白和要回答的问题，研究设想、数据、方法和流程各页以判断句为标题、证据在下；"想请你确认的问题"和"下一步"转为逐条编号的讨论清单，便于会上逐项确认、会后对照。

## visual_style
- visual_style: custom
- visual_style_references: swiss-minimal, data-journalism
- visual_style_behavior: 由 swiss-minimal 提供模块网格、直角、大留白和左对齐的严谨版式；由 data-journalism 提供细线分隔、页脚来源行、放大的关键数字和紧凑表格；一条深蓝竖向色带划分章节，琥珀色只标注卡点与待确认项，整体平面无阴影。

## colors
- background: #FFFFFF
- secondary_bg: #F3F5F8
- primary: #1B3A5C
- accent: #E3A21A
- secondary_accent: #3E7CB1
- body_text: #1E2633
- secondary_text: #5B6675
- divider: #D5DBE3
- grid: #E6EAF0

## typography
- font_family: "Microsoft YaHei", Arial, sans-serif
- title_family: "Microsoft YaHei", Arial, sans-serif
- body_family: "Microsoft YaHei", Arial, sans-serif
- code_family: Consolas, "Microsoft YaHei", monospace
- body: 24
- title: 42
- subtitle: 32
- annotation: 18
- hero_number: 48
- code: 18
- footnote: 14

## icons
- library: tabler-outline
- stroke_width: 2
- inventory: tabler-outline/database, tabler-outline/map-pin, tabler-outline/device-mobile, tabler-outline/briefcase, tabler-outline/search, tabler-outline/clock, tabler-outline/alert-triangle, tabler-outline/check, tabler-outline/users, tabler-outline/file-text, tabler-outline/route, tabler-outline/motorbike, tabler-outline/truck-delivery, tabler-outline/car, tabler-outline/package, tabler-outline/id, tabler-outline/wifi, tabler-outline/lock, tabler-outline/table, tabler-outline/code, tabler-outline/calendar, tabler-outline/flag, tabler-outline/help-circle, tabler-outline/arrow-right, tabler-outline/building-factory-2, tabler-outline/building-skyscraper, tabler-outline/home, tabler-outline/user-search, tabler-outline/target, tabler-outline/circle-check, tabler-outline/list-check

## page_rhythm
- P01: anchor
- P02: breathing
- P03: dense
- P04: dense
- P05: anchor
- P06: dense
- P07: dense
- P08: dense
- P09: dense
- P10: dense
- P11: breathing
- P12: dense
- P13: anchor

## page_visualizations
- P07: table/record_table
- P11: table/record_table

## pptx_structure
- mode: flat

## forbidden
- `mask`, `<style>`, `class`, external CSS, `<foreignObject>`, `textPath`, `@font-face`, `<animate*>`, `<set>`, `<script>` / event attributes, `<iframe>`
- HTML named entities in text; write typography as raw Unicode and escape XML reserved characters
