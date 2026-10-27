-- =====================================================================
-- 00_数据摸底.sql  —— "铁人三项"研究 第0步：数据可行性检查（v4，2026-10-27，导出语句去掉 uid）
-- 平台：智慧足迹 DaaS（Spark/Hive SQL），北京 city='V0110000'
-- 月份分区：date = yyyymm01，例如 20250901 表示 2025 年 9 月
--
-- 【合规规则，本文件逐条遵守】
--  R1 凡是出现 uid 的语句（select uid / count(distinct uid) / 按 uid 关联），一律写成
--     CREATE TABLE wl_xxx AS ...，只在系统内落表，不导出。
--  R2 凡是要导出的 SELECT（标【导出】）：语句里完全不出现 uid（count(distinct uid) 也不行，
--     平台会报"对uid进行非法操作"）；只读 wl_ 中间表。
--  R3 每个【导出】结果都注明预计行数，均远小于 1 万行。
--  R4 平台屏蔽 drop/delete/alter：中间表不能删，重跑时把表名末尾的 _v1 改成 _v2。
--  R5 结果中单格少于 15 人会被平台显示为"≤15"，属正常。
--
-- 运行顺序：A1 → A2 → A3 → A4 → A5 → A6。每段相互独立，报错只影响本段。
-- 若平台不支持某个函数（如 nvl/coalesce），把报错截图发回即可。
-- =====================================================================


-- ---------------------------------------------------------------------
-- A1 有哪些月份：各表在北京有哪些 date 分区
--    目的：确认 2019—2026 年 3/6/9/12 月中，哪些月份几张表都有
-- ---------------------------------------------------------------------
create table wl_tri_a1_part_v1 as
select * from (
    select 'user_app' as tb, date, count(1) as n_row, count(distinct uid) as n_user
    from user_app where city = 'V0110000' group by date
    union all
    select 'user_attribute' as tb, date, count(1) as n_row, count(distinct uid) as n_user
    from user_attribute where city = 'V0110000' group by date
    union all
    select 'stay_poi' as tb, date, count(1) as n_row, count(distinct uid) as n_user
    from stay_poi where city = 'V0110000' group by date
    union all
    select 'move_month' as tb, date, count(1) as n_row, count(distinct uid) as n_user
    from move_month where city = 'V0110000' group by date
) t;

-- 【导出 A1】预计 4 张表 × 约 30 个月份 ≈ 120 行
select tb, date, n_row, n_user from wl_tri_a1_part_v1;
-- 若 move_month 是日分区（date 为具体日期），这一段会有几百行，仍在 1 万行内。


-- ---------------------------------------------------------------------
-- A2 用户编号能否跨期追踪（决定能不能做"从哪来、干多久、往哪去"）
--    永恒已确认：uid 不随换手机改变，5 年可追踪率约 50%。本段仍要跑：
--    用来量化每个季度、每年的自然流失率（换运营商、停号），作为"X 不在库"的基线
--    看两两月份共同出现的人数；正常应有七八成以上重合；
--    若接近 0，说明 uid 每期重新加密，只能做截面研究。
--    date in (...) 里换成 A1 中实际存在的月份；建议包含：
--    相邻季度（20240301、20240601、20240901、20241201）、跨年（20250301）、远年份（20190301 或 20210301）
-- ---------------------------------------------------------------------
create table wl_tri_a2_uid_v1 as
select date, uid
from user_attribute
where city = 'V0110000' and is_core = 'Y'
  and date in (20190301, 20210301, 20240301, 20240601, 20240901, 20241201, 20250301)
group by date, uid;

create table wl_tri_a2_pair_v1 as
select a.date as d1, b.date as d2, count(1) as n_both
from wl_tri_a2_uid_v1 a
join wl_tri_a2_uid_v1 b
  on a.uid = b.uid and a.date < b.date
group by a.date, b.date;

-- 【导出 A2-1】两两重合人数，7 个月份最多 21 行
select d1, d2, n_both from wl_tri_a2_pair_v1;

-- 【导出 A2-2】各期核心用户总数（算重合率的分母），最多 7 行
select date, count(1) as n_core from wl_tri_a2_uid_v1 group by date;


-- ---------------------------------------------------------------------
-- A3a APP 用户数与时长：按 APP识别字典 的确切名称统计（含"待定"名称，用来决定是否纳入）
--    分别对 20250901 和最早可用的 9 月各跑一次（把本段的 20250901 全部换掉即可，表名随之改变）
-- ---------------------------------------------------------------------
create table wl_tri_a3a_20250901_v1 as
select lcode,
       count(distinct uid)          as n_user,
       round(sum(ltime) / 3600000)  as total_hour,
       round(sum(lflux) / 1048576)  as total_mb
from user_app
where city = 'V0110000' and date = 20250901
  and lcode in ('美团骑手', '美团众包', '蜂鸟众包', '达达骑士版', '秒送骑士',
                '顺丰骑士', '闪送员', '点我达骑手', 'UU跑腿跑男端', '曹操送骑手',
                '滴滴车主', '滴滴司机', '美团打车司机端', '花小猪司机端', 'T3车主',
                '享道出行司机', '如祺司机端', '首汽约车司机端', '首约司机', '曹操司机',
                '曹操加盟司机', '阳光出行车主端', '万顺车主', '妥妥E行司机端', '易到车主端',
                '神州优驾司机端', '飞嘀司机-网约车', '叮功司机', '云滴司机', '365司机助手',
                '365约车-车主', '大方车主端', '呼我司机', '搭顺出行司机端', '叫了个车司机端',
                '小叫车司机', '小拉出行司机版', '美团出租司机', '嘀嗒出租司机', '亿的出行出租车司机端',
                '快递员', '快递员助手', '快递100收件端', '百世汇通小件员App', '丰巢管家',
                '货拉拉司机版', '货车帮司机', '运满满司机', '货运宝司机端', '搬运帮司机端',
                '满易运司机', '运的易司机版', '解放行司机版', '好运全程司机', '捎点宝司机',
                '顺道司机', '浩德慧运司机', '滴滴代驾司机', '阿姨一点通', '万师傅',
                '安师傅', '58找工作', '斗米招聘', '店长直聘', '百城求职宝',
                '58建筑英才网', 'BOSS直聘', '智联招聘', '前程无忧51Job', '智通人才',
                '拉勾招聘', '拉勾网', '猎聘', '猎聘同道', '猎聘网',
                '脉脉', 'LinkedIN领英', '兼客兼职', '兼职猫', '口袋兼职',
                '大学生兼职', '天天兼职', '掌上兼职', '淘兼职', '青团社兼职',
                '365跑腿网', '飞毛腿跑腿', '乐拼车主', '拼车到家司机端', '帮邦行司机',
                '聚的出租', '优途快达司机', '菜鸟先飞', '司机宝经纪人', '微代驾')
group by lcode;

-- 【导出 A3a】最多 95 行
select lcode, n_user, total_hour, total_mb from wl_tri_a3a_20250901_v1;


-- ---------------------------------------------------------------------
-- A3b 旧名称核对（模糊检索）：只对最早可用年份跑，查早年 APP 是否改过名
--    （如"达达秒送骑士""京东达达"等旧称）；把本段的 20190901 全部换成 A1 中最早的 9 月
-- ---------------------------------------------------------------------
create table wl_tri_a3b_20190901_v1 as
select lcode,
       count(distinct uid)          as n_user,
       round(sum(ltime) / 3600000)  as total_hour,
       round(sum(lflux) / 1048576)  as total_mb
from user_app
where city = 'V0110000' and date = 20190901
  and (   lcode like '%骑手%' or lcode like '%骑士%' or lcode like '%众包%'
       or lcode like '%配送%' or lcode like '%跑腿%' or lcode like '%闪送%'
       or lcode like '%秒送%' or lcode like '%达达%' or lcode like '%蜂鸟%'
       or lcode like '%快递%' or lcode like '%小哥%' or lcode like '%掌中通%'
       or lcode like '%行者%' or lcode like '%巴枪%' or lcode like '%极兔%'
       or lcode like '%司机%' or lcode like '%车主%' or lcode like '%代驾%'
       or lcode like '%货拉拉%' or lcode like '%快狗%' or lcode like '%运满满%'
       or lcode like '%招聘%' or lcode like '%直聘%' or lcode like '%找工作%'
       or lcode like '%兼职%' or lcode like '%零工%' or lcode like '%鱼泡%'
       or lcode like '%猎聘%' or lcode like '%拉勾%' or lcode like '%脉脉%'
       or lcode like '%领英%' or lcode like '%LinkedIn%' or lcode like '%智联%'
       or lcode like '%前程%' or lcode like '%58%'  or lcode like '%赶集%'
       or lcode like '%斗米%' or lcode like '%猪八戒%' or lcode like '%威客%'
       or lcode like '%程序员%' or lcode like '%码市%' or lcode like '%电鸭%'
       or lcode like '%站酷%' or lcode like '%阿姨%' or lcode like '%家政%')
group by lcode;

-- 【导出 A3b】预计几十到两三百行
select lcode, n_user, total_hour, total_mb from wl_tri_a3b_20190901_v1
where n_user >= 15;

-- A3c 北京当月全部 APP 的用户数与时长（判断能否一次导出全量名录）
create table wl_tri_a3c_20250901_v1 as
select lcode,
       count(distinct uid)          as n_user,
       round(sum(ltime) / 3600000)  as total_hour
from user_app
where city = 'V0110000' and date = 20250901
group by lcode;

-- 【导出 A3c】北京当月 APP 总数，1 行
select count(1) as n_app from wl_tri_a3c_20250901_v1 where n_user >= 15;

-- 【导出 A3d（可选）】若 A3c 的 n_app < 1 万，再跑这条，导出全量 APP 名录
select lcode, n_user, total_hour from wl_tri_a3c_20250901_v1 where n_user >= 15;


-- ---------------------------------------------------------------------
-- A4 识别阈值：工作端 APP 当月使用时长分布
--    骑手、司机一个月实际在线常在 100 小时以上，普通人基本不装这类 APP
--    看分布是否明显分成两堆，以此定"活跃从业者"阈值
--    名单来自 APP识别字典（G1—G4 主口径，共 58 个）
-- ---------------------------------------------------------------------
create table wl_tri_a4_hour_v1 as
select lcode, uid,
       sum(ltime) / 3600000 as hour_m,
       case when sum(ltime) / 3600000 < 1   then 'a <1h'
            when sum(ltime) / 3600000 < 5   then 'b 1-5h'
            when sum(ltime) / 3600000 < 20  then 'c 5-20h'
            when sum(ltime) / 3600000 < 50  then 'd 20-50h'
            when sum(ltime) / 3600000 < 100 then 'e 50-100h'
            when sum(ltime) / 3600000 < 200 then 'f 100-200h'
            else 'g >=200h' end as hour_bin
from user_app
where city = 'V0110000' and date = 20250901
  and lcode in ('美团骑手', '美团众包', '蜂鸟众包', '达达骑士版', '秒送骑士',
                '顺丰骑士', '闪送员', '点我达骑手', 'UU跑腿跑男端', '曹操送骑手',
                '滴滴车主', '滴滴司机', '美团打车司机端', '花小猪司机端', 'T3车主',
                '享道出行司机', '如祺司机端', '首汽约车司机端', '首约司机', '曹操司机',
                '曹操加盟司机', '阳光出行车主端', '万顺车主', '妥妥E行司机端', '易到车主端',
                '神州优驾司机端', '飞嘀司机-网约车', '叮功司机', '云滴司机', '365司机助手',
                '365约车-车主', '大方车主端', '呼我司机', '搭顺出行司机端', '叫了个车司机端',
                '小叫车司机', '小拉出行司机版', '美团出租司机', '嘀嗒出租司机', '亿的出行出租车司机端',
                '快递员', '快递员助手', '快递100收件端', '百世汇通小件员App', '丰巢管家',
                '货拉拉司机版', '货车帮司机', '运满满司机', '货运宝司机端', '搬运帮司机端',
                '满易运司机', '运的易司机版', '解放行司机版', '好运全程司机', '捎点宝司机',
                '顺道司机', '浩德慧运司机', '滴滴代驾司机')
group by lcode, uid;

-- 【导出 A4】58 个工作端 APP × 7 档，最多 406 行
select lcode, hour_bin, count(1) as n_user
from wl_tri_a4_hour_v1
group by lcode, hour_bin;


-- ---------------------------------------------------------------------
-- A5 行为校验：重度使用工作端 APP 的人，停留特征是否像"在路上干活"
--    预期：停留点多、没有固定工作地，或工作地的工作日白天停留短
--    weekday_day_time 单位按字典示例推断为秒（月合计），若不是请告知
-- ---------------------------------------------------------------------
-- 重度工作端 APP 用户（多个工作端 APP 合计 ≥ 50 小时）
create table wl_tri_a5_gig_v1 as
select uid
from wl_tri_a4_hour_v1
group by uid
having sum(hour_m) >= 50;

-- 每个核心用户当月的停留点特征
create table wl_tri_a5_poi_v1 as
select uid,
       count(1) as n_poi,
       max(case when ptype = 2 then 1 else 0 end) as has_work,
       sum(case when ptype = 2 then weekday_day_time else 0 end) / 3600 as work_wkday_h
from stay_poi
where city = 'V0110000' and date = 20250901 and is_core = 'Y'
group by uid;

-- 在系统内关联并分档；新表不保留 uid
create table wl_tri_a5_feat_v1 as
select case when g.uid is not null then 'gig_heavy' else 'other' end as grp,
       case when p.n_poi < 5 then 'a <5' when p.n_poi < 10 then 'b 5-9'
            when p.n_poi < 20 then 'c 10-19' else 'd 20+' end as poi_bin,
       p.has_work,
       case when p.work_wkday_h < 20 then 'a <20h'
            when p.work_wkday_h < 80 then 'b 20-80h'
            else 'c 80h+' end as work_h_bin
from wl_tri_a5_poi_v1 p
left join wl_tri_a5_gig_v1 g on p.uid = g.uid;

-- 【导出 A5】2 组 × 4 × 2 × 3 = 最多 48 行
select grp, poi_bin, has_work, work_h_bin, count(1) as n_user
from wl_tri_a5_feat_v1
group by grp, poi_bin, has_work, work_h_bin;


-- ---------------------------------------------------------------------
-- A6 求职、兼职 APP 使用率：平台从业者与其他核心用户对比
--    名单按 A3 结果补全（名称必须与库里完全一致）
-- ---------------------------------------------------------------------
create table wl_tri_a6_job_v1 as
select uid,
       max(case when lcode in ('58找工作', '斗米招聘', '店长直聘', '百城求职宝', '58建筑英才网')
                then 1 else 0 end) as job_blue,
       max(case when lcode in ('BOSS直聘', '智联招聘', '前程无忧51Job', '智通人才')
                then 1 else 0 end) as job_general,
       max(case when lcode in ('拉勾招聘', '拉勾网', '猎聘', '猎聘同道', '猎聘网',
                           '脉脉', 'LinkedIN领英')
                then 1 else 0 end) as job_white,
       max(case when lcode in ('兼客兼职', '兼职猫', '口袋兼职', '大学生兼职', '天天兼职',
                           '掌上兼职', '淘兼职', '青团社兼职')
                then 1 else 0 end) as parttime
from user_app
where city = 'V0110000' and date = 20250901
group by uid;

-- 以当月有停留记录的核心用户为分母，在系统内关联；新表不保留 uid
create table wl_tri_a6_grp_v1 as
select case when g.uid is not null then 'gig_heavy' else 'other' end as grp,
       coalesce(j.job_blue, 0)    as job_blue,
       coalesce(j.job_general, 0) as job_general,
       coalesce(j.job_white, 0)   as job_white,
       coalesce(j.parttime, 0)    as parttime
from wl_tri_a5_poi_v1 p
left join wl_tri_a5_gig_v1 g on p.uid = g.uid
left join wl_tri_a6_job_v1 j on p.uid = j.uid;

-- 【导出 A6】2 组 × 2 × 2 × 2 × 2 = 最多 32 行（同时给出分母）
select grp, job_blue, job_general, job_white, parttime, count(1) as n_user
from wl_tri_a6_grp_v1
group by grp, job_blue, job_general, job_white, parttime;


-- =====================================================================
-- 自查清单（v4）
--  含 uid 的语句：A1 一条、A2 两条、A3 三条、A4 一条、A5 三条、A6 两条 —— 全部为 CREATE TABLE
--  【导出】语句：A1、A2-1、A2-2、A3a、A3b、A3c、A3d、A4、A5、A6 —— 只读 wl_ 中间表，
--               语句中不出现 uid
--  预计导出行数：A1 ≈120，A2 ≤21+7，A3a ≤95，A3b ≤300，A3c 1，A3d <1 万，A4 ≤406，A5 ≤48，A6 ≤32
-- =====================================================================
