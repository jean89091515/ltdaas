-- =====================================================================
-- 02_截面汇总.sql —— "铁人三项"研究 第2步：截面汇总与跨期面板（v1，2026-10-15）
-- 平台：智慧足迹 DaaS（Spark/Hive SQL），北京
-- 前提：01_状态表.sql 已对相应月份跑完，系统里已有 wl_tri_state_yyyymm_v1
--
-- 【两部分】
--   A 逐期截面汇总：每期跑一次（全部替换 202509 为目标月份），供论文 1 的结构分析
--   B 跨期面板与趋势：所有期的状态表都建好后只跑一次；B 建的面板表也是 03 转移汇总的基础
--
-- 【合规规则】（同 00、01）
--  R1 含 uid 明细的语句一律 CREATE TABLE，不导出
--  R2 【导出】语句结果列无 uid，uid 不出现，不按 uid 关联
--  R3 每个【导出】注明预计最大行数，均 < 1 万行
--  R4 不能 drop：重跑时把 _v1 改成 _v2
--
-- 【参数】状态判定默认 T=50 小时（见 01）；A0 另外按 T=20、T=100 重新判定一次，用于敏感性分析
-- =====================================================================


-- #####################################################################
-- A 逐期截面汇总（每期一次；把 202509 全部替换为目标月份）
-- #####################################################################

-- ---------------------------------------------------------------------
-- A0 截面分析表：从状态表派生，不含 uid（导出都从这张表读）
-- ---------------------------------------------------------------------
create table wl_tri_c_202509_v1 as
select wave, state, is_multi, gender, age_g, origin, arpu_g, is_local, weight,
       home_county, work_county,
       job_blue, job_general, job_white, parttime, other_gig,
       case when h_job = 0 then 'a 0'
            when h_job < 1 then 'b <1h'
            when h_job < 5 then 'c 1-5h'
            when h_job < 20 then 'd 5-20h'
            else 'e 20h+' end as job_h_bin,
       case when state = 'G1外卖即配' then h_food
            when state = 'G2网约车'   then h_ride
            when state = 'G3快递'     then h_exp
            when state = 'G4货运代驾' then h_frt
            else 0 end as h_main,
       case when state not like 'G%' then 'z 非平台'
            when (case when state = 'G1外卖即配' then h_food when state = 'G2网约车' then h_ride
                       when state = 'G3快递' then h_exp else h_frt end) < 100 then 'a 50-100h'
            when (case when state = 'G1外卖即配' then h_food when state = 'G2网约车' then h_ride
                       when state = 'G3快递' then h_exp else h_frt end) < 200 then 'b 100-200h'
            when (case when state = 'G1外卖即配' then h_food when state = 'G2网约车' then h_ride
                       when state = 'G3快递' then h_exp else h_frt end) < 300 then 'c 200-300h'
            else 'd 300h+' end as h_main_bin,
       -- 敏感性：T = 20 小时
       case when h_food >= 20 and h_food >= h_ride and h_food >= h_exp and h_food >= h_frt then 'G1外卖即配'
            when h_ride >= 20 and h_ride >= h_exp and h_ride >= h_frt                     then 'G2网约车'
            when h_exp  >= 20 and h_exp  >= h_frt                                         then 'G3快递'
            when h_frt  >= 20                                                             then 'G4货运代驾'
            when state in ('F固定工作', 'N无固定工作') then state
            else 'F固定工作' end as state_t20,
       -- 敏感性：T = 100 小时（原为 G 但不足 100 小时的人，按固定工作地条件重新归入 F 或 N）
       case when h_food >= 100 and h_food >= h_ride and h_food >= h_exp and h_food >= h_frt then 'G1外卖即配'
            when h_ride >= 100 and h_ride >= h_exp and h_ride >= h_frt                     then 'G2网约车'
            when h_exp  >= 100 and h_exp  >= h_frt                                         then 'G3快递'
            when h_frt  >= 100                                                             then 'G4货运代驾'
            when has_work = 1 and work_wkday_h >= 40                                       then 'F固定工作'   -- 【H】
            else 'N无固定工作' end as state_t100
from wl_tri_state_202509_v1;
-- 说明：state_t20 中，原为 G（≥50h）的人一定仍是 G；原为 F/N 的人若某类达到 20h 则改判为 G；
--       "else 'F固定工作'" 分支实际不会出现，仅为语法完整。

-- 【导出 C1】基本构成：状态 × 兼做 × 年龄 × 性别 × 户籍来源
--   最大 6 × 2 × 8 × 3 × 9 = 2592 行
select wave, state, is_multi, age_g, gender, origin,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, is_multi, age_g, gender, origin;

-- 【导出 C2】求职、兼职、其他零工 APP × 年龄
--   最大 6 × 8 × 2^5 = 1536 行
select wave, state, age_g, job_blue, job_general, job_white, parttime, other_gig,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, age_g, job_blue, job_general, job_white, parttime, other_gig;

-- 【导出 C3】求职 APP × 户籍来源
--   最大 6 × 9 × 2^4 = 864 行
select wave, state, origin, job_blue, job_general, job_white, parttime,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, origin, job_blue, job_general, job_white, parttime;

-- 【导出 C4】求职强度（求职 APP 月使用时长）× 年龄
--   最大 6 × 5 × 8 = 240 行
select wave, state, job_h_bin, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, job_h_bin, age_g;

-- 【导出 C5】通讯费档（收入代理）× 年龄
--   最大 6 × 5 × 8 = 240 行
select wave, state, arpu_g, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, arpu_g, age_g;

-- 【导出 C6】是否本地用户 × 年龄
--   最大 6 × 3 × 8 = 144 行
select wave, state, is_local, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, is_local, age_g;

-- 【导出 C7】平台工作强度：主类 APP 月使用时长档 × 兼做
--   最大 6 × 2 × 5 = 60 行
select wave, state, is_multi, h_main_bin,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state, is_multi, h_main_bin;

-- 【导出 C8】居住地区县 × 状态 × 年龄
--   最大 17 × 6 × 8 = 816 行
select wave, home_county, state, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, home_county, state, age_g;

-- 【导出 C9】工作地区县 × 状态
--   最大 17 × 6 = 102 行
select wave, work_county, state,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, work_county, state;

-- 【导出 C10】阈值敏感性：T=20、T=50（主口径）、T=100 三种判定的交叉
--   最大 6 × 6 × 6 = 216 行
select wave, state_t20, state, state_t100,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_c_202509_v1
group by wave, state_t20, state, state_t100;


-- ---------------------------------------------------------------------
-- A-网格（可选）：平台从业者居住地 250 米网格分布（画地图用）
--   先跑计数；若行数 < 1 万再导出；否则改用街道级（见 A-属性表）
-- ---------------------------------------------------------------------
create table wl_tri_cg_202509_v1 as
select wave, home_fnid, state
from wl_tri_state_202509_v1
where state like 'G%' and home_fnid is not null;

-- 【导出 CG0】先看有多少个网格满足 ≥15 人，1 行
select count(1) as n_grid
from (select home_fnid from wl_tri_cg_202509_v1
      group by home_fnid having count(1) >= 15) t;

-- 【导出 CG1】（CG0 < 1 万时再跑）平台从业者合计，按居住网格
select wave, home_fnid, count(1) as n_user
from wl_tri_cg_202509_v1
group by wave, home_fnid
having count(1) >= 15;


-- ---------------------------------------------------------------------
-- A-属性表（可选，需先上传 wl_tri_fnid_attr_v1）
--   wl_tri_fnid_attr_v1 字段：fnid, street_code（街道代码）, ring（环路圈层）,
--                             lu_class（主导用地类型）, is_village（是否城中村集中片区，0/1）
--   这张表由我们在本地根据 250 米网格、街道、环路、地块数据生成后上传（类似以前的 wl_code）
-- ---------------------------------------------------------------------
create table wl_tri_ca_202509_v1 as
select s.wave, s.state, s.age_g, s.weight,
       ah.street_code as home_street, ah.ring as home_ring, ah.is_village as home_village,
       aw.ring as work_ring, aw.lu_class as work_lu
from wl_tri_state_202509_v1 s
left join wl_tri_fnid_attr_v1 ah on s.home_fnid = ah.fnid
left join wl_tri_fnid_attr_v1 aw on s.work_fnid = aw.fnid;

-- 【导出 CA1】居住地环路圈层、是否城中村 × 状态 × 年龄
--   最大 7 × 2 × 6 × 8 = 672 行
select wave, home_ring, home_village, state, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_ca_202509_v1
group by wave, home_ring, home_village, state, age_g;

-- 【导出 CA2】居住地街道 × 状态（约 340 个街道乡镇）
--   最大 341 × 6 ≈ 2050 行
select wave, home_street, state,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_ca_202509_v1
group by wave, home_street, state;

-- 【导出 CA3】固定工作者的工作地用地类型（对照组画像）
--   最大 7 × 8 × 6 = 336 行
select wave, work_lu, work_ring, state,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_ca_202509_v1
group by wave, work_lu, work_ring, state;


-- #####################################################################
-- B 跨期面板与趋势（所有期的 01 状态表都建好后，只跑一次）
-- #####################################################################

-- ---------------------------------------------------------------------
-- B0 原始面板：把各期状态表上下拼接
--   【请删除不存在的月份那几行】（连同其上一行的 union all），否则会报"表不存在"
--   若有 2026 年的数据，去掉末尾注释符号即可加入
-- ---------------------------------------------------------------------
create table wl_tri_panel0_v1 as
select * from (
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_201903_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_201906_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_201909_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_201912_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202003_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202006_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202009_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202012_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202103_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202106_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202109_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202112_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202203_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202206_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202209_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202212_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202303_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202306_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202309_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202312_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202403_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202406_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202409_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202412_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202503_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202506_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202509_v1
    union all
    select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202512_v1
    -- union all
    -- select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202603_v1
    -- union all
    -- select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202606_v1
    -- union all
    -- select uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, job_blue, job_general, job_white, parttime, other_gig from wl_tri_state_202609_v1
) u;

-- ---------------------------------------------------------------------
-- B1 期次表：每个月份的年份、季度序号、在现有月份中的排序（wave_rank），不含 uid
--   wave_rank 是"现有月份中的第几期"：相邻两个现有月份的 wave_rank 相差 1
--   （若中间缺某一期，转移间隔会变成 6 个月，03 的导出里保留了起止月份，可以识别）
-- ---------------------------------------------------------------------
create table wl_tri_waves_v1 as
select wave, year, wave_seq,
       row_number() over (order by wave) as wave_rank
from (select wave,
             cast(wave / 100 as int) as year,
             (cast(wave / 100 as int) - 2019) * 4 + cast((wave % 100) / 3 as int) as wave_seq
      from wl_tri_panel0_v1
      group by wave) t;

-- ---------------------------------------------------------------------
-- B2 正式面板：原始面板加上期次信息（含 uid，只留在系统内，03 使用）
-- ---------------------------------------------------------------------
create table wl_tri_panel_v1 as
select p.*, w.year, w.wave_seq, w.wave_rank
from wl_tri_panel0_v1 p
inner join wl_tri_waves_v1 w on p.wave = w.wave;

-- 【导出 B-E0】期次清单与各期人数，最多约 31 行
select w.wave, w.year, w.wave_seq, w.wave_rank, count(1) as n_user
from wl_tri_panel_v1 w
group by w.wave, w.year, w.wave_seq, w.wave_rank;

-- 【导出 B-E1】趋势：各期 × 状态 × 兼做 × 年龄
--   最大 31 × 6 × 2 × 8 = 2976 行
select wave, state, is_multi, age_g,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_panel_v1
group by wave, state, is_multi, age_g;

-- 【导出 B-E2】趋势：各期 × 状态 × 三类求职渠道
--   最大 31 × 6 × 8 = 1488 行
select wave, state, job_blue, job_general, job_white,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_panel_v1
group by wave, state, job_blue, job_general, job_white;

-- 【导出 B-E3】趋势：各期 × 状态 × 户籍来源
--   最大 31 × 6 × 9 = 1674 行
select wave, state, origin,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_panel_v1
group by wave, state, origin;

-- 【导出 B-E4】趋势：各期 × 状态 × 居住地区县
--   最大 31 × 6 × 17 = 3162 行
select wave, state, home_county,
       count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_panel_v1
group by wave, state, home_county;


-- =====================================================================
-- 自查清单（v1）
--  含 uid 明细的语句：A-网格建表（cg，实际不含 uid 列）、A-属性表建表（ca，不含 uid 列）、
--                    B0 面板、B2 面板 —— 全部为 CREATE TABLE
--  A0、cg、ca、B1 派生表均不含 uid 列；B0、B2 含 uid，只留在系统内
--  【导出】语句：C1—C10、CG0、CG1、CA1—CA3、B-E0—B-E4 —— 结果列无 uid，uid 不出现
--  预计最大导出行数：C1 2592，其余均 ≤ 3162；CG1 视 CG0 而定（< 1 万才跑）
-- =====================================================================
