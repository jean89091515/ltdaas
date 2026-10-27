-- =====================================================================
-- 03_转移汇总.sql —— "铁人三项"研究 第3步：转移、持续与轨迹（v1，2026-10-15）
-- 平台：智慧足迹 DaaS（Spark/Hive SQL），北京
-- 前提：02_截面汇总.sql 的 B 部分已跑完，系统里已有
--       wl_tri_panel_v1（含 uid 的全期面板）和 wl_tri_waves_v1（期次表）
--
-- 【适用情景】本文件按"情景 A：uid 跨期、跨年都稳定"编写。
--   若 00 摸底 A2 显示 uid 只在同一年内稳定（情景 B）：
--     · T1 照常运行，导出时只用 cross_year = 0 的行；
--     · T2—T4 需要改为"年内"版本，请把 A2 结果发回，我再给出改好的版本。
--
-- 【回答的问题】
--   T1 相邻两期之间：谁从哪种状态转到哪种状态（含"铁人三项"之间互转）；
--      跑单时用求职 APP 的人，下一期是否更多回到固定工作（一步转移版的跳板检验）
--   T2 平台从业段：连续几期在做平台工作（任一类 G 连续出现算同一段）；
--      进入前是什么状态，退出后去了哪里；段内是否换过平台类型；段内是否找过工作
--   T3 人期表：生存分析和离散时间风险模型的输入（第 d 期退出的概率，随求职行为变化）
--   T4 事件时间轨迹：进入平台前后、退出平台前后各 4 期的状态与求职 APP 使用（看"转变过程"）
--   T5（可选，需上传 wl_tri_fnid_attr_v1）：从固定工作进入、又回到固定工作的人，
--      前后工作地的用地类型是否相同（"是否回到原类型岗位"）
--
-- 【合规规则】（同 00—02）
--  R1 含 uid 明细的语句一律 CREATE TABLE，不导出
--  R2 【导出】语句结果列无 uid，uid 不出现，不按 uid 关联；导出只读不含 uid 的派生表
--  R3 每个【导出】注明预计最大行数，均 < 1 万行
--  R4 不能 drop：重跑时把 _v1 改成 _v2
--
-- 【状态代码】G1外卖即配 / G2网约车 / G3快递 / G4货运代驾 / F固定工作 / N无固定工作
--   X不在库：该期北京核心用户中没有此人（离京、换号、销户，无法区分）
--   L左删失：从业段始于第 1 期，不知道之前的状态
--   R右删失：从业段持续到最后一期，不知道之后的状态
-- =====================================================================


-- ---------------------------------------------------------------------
-- T0 辅助小表（不含 uid）
-- ---------------------------------------------------------------------
-- 最后一期的序号
create table wl_tri_rankmax_v1 as
select 1 as j, max(wave_rank) as max_rank
from wl_tri_waves_v1;

-- 事件时间 k = -4 … +4（借期次表生成 9 个整数；要求现有期数 ≥ 9）
create table wl_tri_k_v1 as
select 1 as j, wave_rank - 5 as k
from wl_tri_waves_v1
where wave_rank <= 9;


-- #####################################################################
-- T1 相邻两期状态转移
-- #####################################################################
-- 在系统内配对相邻两期，结果表不含 uid
create table wl_tri_t1_pair_v1 as
select a.wave as wave0, w1.wave as wave1, a.year as year0,
       case when w1.year <> a.year then 1 else 0 end as cross_year,
       a.state as s0,
       coalesce(b.state, 'X不在库') as s1,
       a.is_multi, a.age_g, a.origin, a.gender, a.is_local, a.arpu_g, a.weight,
       a.job_blue, a.job_general, a.job_white, a.parttime,
       case when a.job_blue + a.job_general + a.job_white > 0 then 1 else 0 end as job_any,
       case when a.h_job = 0 then 'a 0' when a.h_job < 1 then 'b <1h'
            when a.h_job < 5 then 'c 1-5h' else 'd 5h+' end as job_h_bin,
       case when a.work_county is not null and b.work_county = a.work_county then 1 else 0 end as same_work_county
from wl_tri_panel_v1 a
inner join wl_tri_waves_v1 w1 on w1.wave_rank = a.wave_rank + 1
left join wl_tri_panel_v1 b on b.uid = a.uid and b.wave_rank = a.wave_rank + 1;

-- 【导出 T1-E1】逐期转移矩阵：起始期 × 下一期 × s0 × s1
--   最大 30 × 6 × 7 = 1260 行
select wave0, wave1, s0, s1,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
group by wave0, wave1, s0, s1;

-- 【导出 T1-E2】转移 × 年龄（按年合并）
--   最大 7 × 2 × 6 × 7 × 8 = 4704 行
select year0, cross_year, s0, s1, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
group by year0, cross_year, s0, s1, age_g;

-- 【导出 T1-E3】转移 × 户籍来源（按年合并）
--   最大 7 × 2 × 6 × 7 × 9 = 5292 行
select year0, cross_year, s0, s1, origin,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
group by year0, cross_year, s0, s1, origin;

-- 【导出 T1-E4】一步跳板检验：本期为平台从业者，按三类求职渠道 × 年龄看下一期去向
--   最大 4 × 7 × 8 × 8 × 2 = 3584 行
select s0, s1, job_blue, job_general, job_white, age_g, cross_year,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
where s0 like 'G%'
group by s0, s1, job_blue, job_general, job_white, age_g, cross_year;

-- 【导出 T1-E5】求职强度 × 下一期去向（所有状态，可与固定工作者对照）
--   最大 6 × 7 × 4 × 8 × 2 = 2688 行
select s0, s1, job_h_bin, age_g, cross_year,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
group by s0, s1, job_h_bin, age_g, cross_year;

-- 【导出 T1-E6】兼做与否 × 下一期去向；固定工作者下一期是否仍在同一区县工作
--   最大 6 × 2 × 7 × 2 × 2 = 336 行
select s0, is_multi, s1, same_work_county, cross_year,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t1_pair_v1
group by s0, is_multi, s1, same_work_county, cross_year;


-- #####################################################################
-- T2 平台从业段（任一类 G 连续出现的若干期算一段）
-- #####################################################################
-- T2a 只取平台状态的记录，用"期序 - 行号"找出连续段（gaps and islands）
create table wl_tri_t2_isl_v1 as
select uid, wave_rank, state, job_blue, job_general, job_white, h_job,
       wave_rank - row_number() over (partition by uid order by wave_rank) as isl
from wl_tri_panel_v1
where state in ('G1外卖即配', 'G2网约车', 'G3快递', 'G4货运代驾');

-- T2b 每段的起止、长度、段内求职情况
create table wl_tri_t2_core_v1 as
select uid, isl,
       1 as j,
       min(wave_rank) as start_rank,
       max(wave_rank) as end_rank,
       count(1) as len,
       count(distinct state) as n_type,
       max(job_blue)    as job_blue_sp,
       max(job_general) as job_general_sp,
       max(job_white)   as job_white_sp,
       max(case when job_blue + job_general + job_white > 0 then 1 else 0 end) as job_any_sp,
       avg(h_job) as h_job_mean
from wl_tri_t2_isl_v1
group by uid, isl;

-- T2c 补上：起始期属性、进入前状态、退出后状态、前后工作地（含 uid，只留在系统内）
create table wl_tri_t2_spell_v1 as
select c.uid, c.j, c.start_rank, c.end_rank, c.len, c.n_type,
       c.job_blue_sp, c.job_general_sp, c.job_white_sp, c.job_any_sp, c.h_job_mean,
       ws.wave as start_wave, ws.year as start_year,
       st.state as type0, st.age_g, st.origin, st.gender, st.is_local, st.arpu_g, st.weight,
       case when c.start_rank = 1 then 'L左删失'
            else coalesce(pb.state, 'X不在库') end as entry_state,
       case when c.end_rank = m.max_rank then 'R右删失'
            else coalesce(pa.state, 'X不在库') end as exit_state,
       pb.work_fnid as pre_work_fnid,  pb.work_county as pre_work_county,
       pa.work_fnid as post_work_fnid, pa.work_county as post_work_county
from wl_tri_t2_core_v1 c
inner join wl_tri_rankmax_v1 m  on m.j = c.j
inner join wl_tri_waves_v1   ws on ws.wave_rank = c.start_rank
inner join wl_tri_panel_v1   st on st.uid = c.uid and st.wave_rank = c.start_rank
left join  wl_tri_panel_v1   pb on pb.uid = c.uid and pb.wave_rank = c.start_rank - 1
left join  wl_tri_panel_v1   pa on pa.uid = c.uid and pa.wave_rank = c.end_rank + 1;

-- T2d 导出用派生表（不含 uid）
create table wl_tri_t2_out_v1 as
select start_year, type0, len,
       case when len = 1 then 'a 1期' when len = 2 then 'b 2期' when len <= 4 then 'c 3-4期'
            when len <= 8 then 'd 5-8期' else 'e 9期+' end as len_bin,
       entry_state, exit_state, n_type,
       job_blue_sp, job_general_sp, job_white_sp, job_any_sp,
       case when h_job_mean = 0 then 'a 0' when h_job_mean < 1 then 'b <1h'
            when h_job_mean < 5 then 'c 1-5h' else 'd 5h+' end as job_h_bin,
       age_g, origin, gender, arpu_g, weight,
       case when entry_state = 'F固定工作' and exit_state = 'F固定工作'
                 and pre_work_fnid = post_work_fnid then 1 else 0 end as back_same_grid,
       case when entry_state = 'F固定工作' and exit_state = 'F固定工作'
                 and pre_work_county = post_work_county then 1 else 0 end as back_same_county
from wl_tri_t2_spell_v1;

-- 【导出 T2-E1】段长分布（生命表）：起始年 × 类型 × 段长 × 是否左删失 × 是否右删失
--   （若再细分进入、退出状态会超过 1 万行，进入和退出去向见 T2-E2）
--   最大 7 × 4 × 30 × 2 × 2 = 3360 行
select start_year, type0, len,
       case when entry_state = 'L左删失' then 1 else 0 end as left_cens,
       case when exit_state  = 'R右删失' then 1 else 0 end as right_cens,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
group by start_year, type0, len,
         case when entry_state = 'L左删失' then 1 else 0 end,
         case when exit_state  = 'R右删失' then 1 else 0 end;

-- 【导出 T2-E2】从哪来、到哪去：进入前状态 × 退出后状态 × 类型 × 段长档 × 年龄
--   进入 5 种（F/N/X/L/其他）× 退出 4 种（F/N/X/R）× 4 × 5 × 8 = 3200 行
select entry_state, exit_state, type0, len_bin, age_g,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
group by entry_state, exit_state, type0, len_bin, age_g;

-- 【导出 T2-E3】"铁人三项"之间是否换过：段内平台类型数 × 起始类型 × 段长档
--   最大 4 × 4 × 5 = 80 行
select n_type, type0, len_bin,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
group by n_type, type0, len_bin;

-- 【导出 T2-E4】段内求职（任一渠道、白领渠道）× 退出去向 × 段长档 × 年龄
--   最大 2 × 2 × 4 × 5 × 8 = 640 行
select job_any_sp, job_white_sp, exit_state, len_bin, age_g,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
group by job_any_sp, job_white_sp, exit_state, len_bin, age_g;

-- 【导出 T2-E5】从固定工作来、又回到固定工作的人：是否回到原网格或原区县
--   最大 2 × 2 × 5 × 8 = 160 行
select back_same_grid, back_same_county, len_bin, age_g,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
where entry_state = 'F固定工作' and exit_state = 'F固定工作'
group by back_same_grid, back_same_county, len_bin, age_g;

-- 【导出 T2-E6】户籍来源 × 退出去向 × 段长档 × 类型
--   最大 9 × 4 × 5 × 4 = 720 行
select origin, exit_state, len_bin, type0,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t2_out_v1
group by origin, exit_state, len_bin, type0;


-- #####################################################################
-- T3 人期表（生存分析、离散时间风险模型的输入）
--   每个从业段的每一期一行：d = 段内第几期（12 期及以上合并为 12）；
--   outcome = 本期之后的结果：'0继续' 或 退出去向（F/N/X），最后一期若为右删失则为 'R右删失'
--   求职变量随时间变化（取该期本身的值）
-- #####################################################################
create table wl_tri_t3_pp_v1 as
select case when p.wave_rank - s.start_rank + 1 >= 12 then 12
            else p.wave_rank - s.start_rank + 1 end as d,
       case when p.wave_rank < s.end_rank then '0继续' else s.exit_state end as outcome,
       s.type0, s.age_g, s.origin, s.arpu_g, s.weight, s.entry_state, s.start_year,
       p.state as state_d,
       p.job_blue, p.job_general, p.job_white,
       case when p.job_blue + p.job_general + p.job_white > 0 then 1 else 0 end as job_any
from wl_tri_t2_spell_v1 s
inner join wl_tri_panel_v1 p on p.uid = s.uid
where p.wave_rank >= s.start_rank and p.wave_rank <= s.end_rank;

-- 【导出 T3-E1】d × 结果 × 类型 × 年龄 × 是否求职
--   最大 12 × 5 × 4 × 8 × 2 = 3840 行
select d, outcome, type0, age_g, job_any,
       count(1) as n_pp, round(sum(weight)) as n_weighted
from wl_tri_t3_pp_v1
group by d, outcome, type0, age_g, job_any;

-- 【导出 T3-E2】d × 结果 × 户籍来源 × 是否求职
--   最大 12 × 5 × 9 × 2 = 1080 行
select d, outcome, origin, job_any,
       count(1) as n_pp, round(sum(weight)) as n_weighted
from wl_tri_t3_pp_v1
group by d, outcome, origin, job_any;

-- 【导出 T3-E3】d × 结果 × 三类求职渠道 × 通讯费档
--   最大 12 × 5 × 8 × 5 = 2400 行
select d, outcome, job_blue, job_general, job_white, arpu_g,
       count(1) as n_pp, round(sum(weight)) as n_weighted
from wl_tri_t3_pp_v1
group by d, outcome, job_blue, job_general, job_white, arpu_g;

-- 【导出 T3-E4】d × 结果 × 进入前状态 × 起始年（看不同年份、不同来源的人留得久不久）
--   最大 12 × 5 × 5 × 7 = 2100 行
select d, outcome, entry_state, start_year,
       count(1) as n_pp, round(sum(weight)) as n_weighted
from wl_tri_t3_pp_v1
group by d, outcome, entry_state, start_year;


-- #####################################################################
-- T4 事件时间轨迹：进入前后、退出前后各 4 期
--   k = 0 为进入的那一期（或退出前最后一期）；k < 0 为之前，k > 0 为之后
-- #####################################################################
-- T4a 进入窗口：每个非左删失的从业段 × 9 个 k，先算出目标期序
create table wl_tri_t4_ek_v1 as
select s.uid, k.k, s.start_rank + k.k as tgt_rank, m.max_rank,
       s.type0, s.age_g, s.entry_state, s.weight
from wl_tri_t2_spell_v1 s
inner join wl_tri_k_v1       k on k.j = s.j
inner join wl_tri_rankmax_v1 m on m.j = s.j
where s.entry_state <> 'L左删失';

-- T4b 关联面板，取各 k 期的状态和求职情况；结果表不含 uid
create table wl_tri_t4_entry_v1 as
select e.k, e.type0, e.age_g, e.entry_state, e.weight,
       case when e.tgt_rank < 1 or e.tgt_rank > e.max_rank then 'W窗口外'
            else coalesce(p.state, 'X不在库') end as state_k,
       case when p.uid is null then 0
            when p.job_blue + p.job_general + p.job_white > 0 then 1 else 0 end as job_any_k,
       coalesce(p.job_white, 0) as job_white_k
from wl_tri_t4_ek_v1 e
left join wl_tri_panel_v1 p on p.uid = e.uid and p.wave_rank = e.tgt_rank;

-- 【导出 T4-E1】进入前后：k × 该期状态 × 是否求职 × 类型 × 年龄
--   最大 9 × 8 × 2 × 4 × 8 = 4608 行
select k, state_k, job_any_k, type0, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t4_entry_v1
group by k, state_k, job_any_k, type0, age_g;

-- 【导出 T4-E2】进入前后：k × 该期状态 × 是否用白领渠道 × 年龄
--   最大 9 × 8 × 2 × 8 = 1152 行
select k, state_k, job_white_k, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t4_entry_v1
group by k, state_k, job_white_k, age_g;

-- T4c 退出窗口：每个非右删失的从业段，以最后一期为 k = 0
create table wl_tri_t4_xk_v1 as
select s.uid, k.k, s.end_rank + k.k as tgt_rank, m.max_rank,
       s.type0, s.age_g, s.exit_state, s.weight
from wl_tri_t2_spell_v1 s
inner join wl_tri_k_v1       k on k.j = s.j
inner join wl_tri_rankmax_v1 m on m.j = s.j
where s.exit_state <> 'R右删失';

create table wl_tri_t4_exit_v1 as
select x.k, x.type0, x.age_g, x.exit_state, x.weight,
       case when x.tgt_rank < 1 or x.tgt_rank > x.max_rank then 'W窗口外'
            else coalesce(p.state, 'X不在库') end as state_k,
       case when p.uid is null then 0
            when p.job_blue + p.job_general + p.job_white > 0 then 1 else 0 end as job_any_k
from wl_tri_t4_xk_v1 x
left join wl_tri_panel_v1 p on p.uid = x.uid and p.wave_rank = x.tgt_rank;

-- 【导出 T4-E3】退出前后：k × 该期状态 × 是否求职 × 退出去向 × 年龄
--   最大 9 × 8 × 2 × 3 × 8 = 3456 行
select k, state_k, job_any_k, exit_state, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_t4_exit_v1
group by k, state_k, job_any_k, exit_state, age_g;


-- #####################################################################
-- T5（可选）是否回到原类型岗位：需先上传 wl_tri_fnid_attr_v1
--   （字段：fnid, street_code, ring, lu_class, is_village；见 02 的说明）
-- #####################################################################
create table wl_tri_t5_lu_v1 as
select s.type0, s.age_g, s.len, s.entry_state, s.exit_state, s.weight,
       case when s.len = 1 then 'a 1期' when s.len = 2 then 'b 2期' when s.len <= 4 then 'c 3-4期'
            when s.len <= 8 then 'd 5-8期' else 'e 9期+' end as len_bin,
       coalesce(la.lu_class, 'z无') as pre_lu,
       coalesce(lb.lu_class, 'z无') as post_lu,
       coalesce(la.ring, 'z无')     as pre_ring
from wl_tri_t2_spell_v1 s
left join wl_tri_fnid_attr_v1 la on la.fnid = s.pre_work_fnid
left join wl_tri_fnid_attr_v1 lb on lb.fnid = s.post_work_fnid
where s.entry_state = 'F固定工作';

-- 【导出 T5-E1】从固定工作进入平台的人：原工作地用地类型 × 平台类型 × 年龄
--   最大 7 × 4 × 8 = 224 行
select pre_lu, type0, age_g,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t5_lu_v1
group by pre_lu, type0, age_g;

-- 【导出 T5-E2】从固定工作来、又回到固定工作：前后用地类型 × 段长档 × 年龄
--   最大 7 × 7 × 5 × 8 = 1960 行
select pre_lu, post_lu, len_bin, age_g,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t5_lu_v1
where exit_state = 'F固定工作'
group by pre_lu, post_lu, len_bin, age_g;

-- 【导出 T5-E3】原工作地用地类型 × 退出去向 × 段长档（来自哪类岗位的人更难回去）
--   最大 7 × 4 × 5 = 140 行
select pre_lu, exit_state, len_bin,
       count(1) as n_spell, round(sum(weight)) as n_weighted
from wl_tri_t5_lu_v1
group by pre_lu, exit_state, len_bin;


-- =====================================================================
-- 自查清单（v1）
--  含 uid 明细的语句：T1 配对、T2a、T2b、T2c、T3、T4a、T4b、T4c、T4 退出表、T5 —— 全部为 CREATE TABLE
--  其中 T1 配对表、T2d、T3、T4b、T4 退出表、T5 的结果表不含 uid 列；T2a—T2c、T4a、T4c 含 uid，只留在系统内
--  【导出】语句：T1-E1—E6、T2-E1、T2-E2—E6、T3-E1—E4、T4-E1—E3、T5-E1—E3
--              —— 只读不含 uid 的派生表，结果列无 uid，uid 不出现
--  预计最大导出行数：均 ≤ 5292（T1-E3）
--  性能提示：T2c、T3、T4b 会多次关联全期面板，若运行过慢，可先只用最近 3 年的面板
-- =====================================================================
