-- =====================================================================
-- 01_状态表.sql —— "铁人三项"研究 第1步：逐期、逐人的状态表（v1，2026-10-15）
-- 平台：智慧足迹 DaaS（Spark/Hive SQL），北京 city='V0110000'
--
-- 【做什么】
--   对某一期（例如 2025 年 9 月），给每个核心用户算出：
--     · 人口属性：性别、年龄段、户籍来源、通讯费档、是否本地、扩样权重
--     · 平台工作：外卖即配、网约车、快递、货运代驾 四类工作端 APP 当月使用小时数
--     · 求职与兼职：蓝领、综合、白领三类求职 APP，兼职 APP，家政维修等其他零工端是否使用及时长
--     · 停留与出行：停留点个数、是否有工作地、工作地工作日白天停留小时、出行次数和时长
--     · 居住地、工作地所在 250 米网格 fnid 和区县
--     · 状态：G1 外卖即配 / G2 网约车 / G3 快递 / G4 货运代驾 / F 固定工作 / N 无固定工作
--   结果表 wl_tri_state_202509_v1 只留在系统里，供 02 截面汇总、03 转移汇总使用。
--
-- 【合规规则】（同 00_数据摸底.sql）
--  R1 含 uid 明细的语句一律 CREATE TABLE，不导出。
--  R2 【导出】语句结果列无 uid，语句中不出现 uid（count(distinct uid) 也不行），不按 uid 关联。
--  R3 每个【导出】注明预计行数，均 < 1 万行。
--  R4 不能 drop：重跑时把 _v1 改成 _v2。
--  R5 不能出现星号字符（select 星号、p.星号、乘号都会报"非法字符"），列名一律写全。
--
-- 【怎么用于其他月份】
--   用编辑器"全部替换"三个字符串即可：
--     202509   → 目标月份，例如 202406（表名后缀和 wave 字段）
--     20250901 → 目标月份的分区，例如 20240601
--     20250930 → 目标月份最后一天，例如 20240630（仅 S4 出行表用）
--   S0 全项目只跑一次，换月份时跳过 S0。
--
-- 【参数】（00 摸底的 A4、A5 结果出来后再定，现在先用默认值）
--   T = 50   工作端 APP 当月使用 ≥ 50 小时，判为该类平台从业者（搜索 "-- 【T】" 可找到所有位置）
--   H = 40   固定工作地的工作日白天停留 ≥ 40 小时/月，判为有固定工作（搜索 "-- 【H】"）
--   状态表同时保存各类小时数，以后做阈值敏感性分析不用重跑本文件。
--
-- 【APP 清单】（v2，2026-10-19）
--   依据智慧足迹提供的 DaaS 北京活跃 APP 名录（2026 年 1、5、8 月），见 1-研究设计/APP识别字典.xlsx。
--   只纳入工作端（骑手端、司机端、快递员端）；消费端、招聘方、顺风车一律不纳入。
--   较早年份的 APP 名称可能不同，请先用 00 摸底 A3b 核对。
-- =====================================================================


-- ---------------------------------------------------------------------
-- S0 网格参数表（全项目只建一次；沿用以前"规划一张图"脚本的做法）
-- ---------------------------------------------------------------------
create table wl_tri_grid_para_v1 as
select city_code,
       min(ext_min_x) as lon_min,
       min(ext_min_y) as lat_min,
       max(ext_max_x) as lon_max,
       max(ext_max_y) as lat_max,
       avg(ext_max_x - ext_min_x) as dx,
       avg(ext_max_y - ext_min_y) as dy
from ss_city_grid
where city_code = 'V0110000'
group by city_code;


-- ---------------------------------------------------------------------
-- S1 基础人群：本期北京核心用户及其属性（一人一行）
--    年龄编码沿用旧脚本：04 16-18，05 19-24，06/07 25-34，08/09 35-44，
--    10/11 45-54，12/13 55-64，14/15 65+，01—03 0-15，16 未知
--    户籍来源：身份证前 2 位（省级代码）
-- ---------------------------------------------------------------------
create table wl_tri_s1_base_202509_v1 as
select uid,
       max(gender) as gender,
       max(case when age in ('04', '05')       then 'a16-24'
                when age in ('06', '07')       then 'b25-34'
                when age in ('08', '09')       then 'c35-44'
                when age in ('10', '11')       then 'd45-54'
                when age in ('12', '13')       then 'e55-64'
                when age in ('14', '15')       then 'f65+'
                when age in ('01', '02', '03') then 'g0-15'
                else 'z未知' end) as age_g,
       max(case when substr(id_area, 1, 2) = '11'               then 'a北京'
                when substr(id_area, 1, 2) in ('12', '13')      then 'b津冀'
                when substr(id_area, 1, 2) = '41'               then 'c河南'
                when substr(id_area, 1, 2) = '37'               then 'd山东'
                when substr(id_area, 1, 2) in ('14', '15')      then 'e晋蒙'
                when substr(id_area, 1, 2) in ('21', '22', '23') then 'f东北'
                when substr(id_area, 1, 2) in ('34', '36', '42', '43') then 'g皖赣鄂湘'
                when id_area is null or id_area = ''            then 'z未知'
                else 'h其他' end) as origin,
       max(case when arpu is null then 'z未知'
                when arpu <= 50  then 'a<=50'
                when arpu <= 100 then 'b50-100'
                when arpu <= 200 then 'c100-200'
                else 'd>200' end) as arpu_g,
       max(is_local) as is_local,
       max(weight)   as weight
from user_attribute
where city = 'V0110000' and date = 20250901 and is_core = 'Y'
group by uid;


-- ---------------------------------------------------------------------
-- S2 APP 使用：四类工作端、三类求职、兼职、其他零工（一人一行）
--    ltime 单位为毫秒，/3600000 换算成小时
-- ---------------------------------------------------------------------
create table wl_tri_s2_app_202509_v1 as
select uid,
       -- G1 外卖、即配、跑腿（骑手端）
       sum(case when lcode in ('美团骑手', '美团众包', '蜂鸟众包', '达达骑士版', '秒送骑士',
                               '顺丰骑士', '闪送员', '点我达骑手', 'UU跑腿跑男端', '曹操送骑手')
                then ltime else 0 end) / 3600000 as h_food,
       -- G2 网约车、出租（司机端；巡游出租车司机端也在内）
       sum(case when lcode in ('滴滴车主', '滴滴司机', '美团打车司机端', '花小猪司机端', 'T3车主',
                               '享道出行司机', '如祺司机端', '首汽约车司机端', '首约司机', '曹操司机',
                               '曹操加盟司机', '阳光出行车主端', '万顺车主', '妥妥E行司机端', '易到车主端',
                               '神州优驾司机端', '飞嘀司机-网约车', '叮功司机', '云滴司机', '365司机助手',
                               '365约车-车主', '大方车主端', '呼我司机', '搭顺出行司机端', '叫了个车司机端',
                               '小叫车司机', '小拉出行司机版', '美团出租司机', '嘀嗒出租司机', '亿的出行出租车司机端')
                then ltime else 0 end) / 3600000 as h_ride,
       -- G3 快递（快递员端；三通一达、京东、顺丰公司内部作业 APP 不在库）
       sum(case when lcode in ('快递员', '快递员助手', '快递100收件端', '百世汇通小件员App', '丰巢管家')
                then ltime else 0 end) / 3600000 as h_exp,
       -- G4 货运、代驾（司机端）
       sum(case when lcode in ('货拉拉司机版', '货车帮司机', '运满满司机', '货运宝司机端', '搬运帮司机端',
                               '满易运司机', '运的易司机版', '解放行司机版', '好运全程司机', '捎点宝司机',
                               '顺道司机', '浩德慧运司机', '滴滴代驾司机')
                then ltime else 0 end) / 3600000 as h_frt,
       -- 求职：蓝领渠道
       max(case when lcode in ('58找工作', '斗米招聘', '店长直聘', '百城求职宝', '58建筑英才网')
                then 1 else 0 end) as job_blue,
       -- 求职：综合渠道
       max(case when lcode in ('BOSS直聘', '智联招聘', '前程无忧51Job', '智通人才')
                then 1 else 0 end) as job_general,
       -- 求职：白领、专业渠道
       max(case when lcode in ('拉勾招聘', '拉勾网', '猎聘', '猎聘同道', '猎聘网',
                               '脉脉', 'LinkedIN领英')
                then 1 else 0 end) as job_white,
       -- 求职 APP 合计时长（小时）
       sum(case when lcode in ('58找工作', '斗米招聘', '店长直聘', '百城求职宝', '58建筑英才网',
                               'BOSS直聘', '智联招聘', '前程无忧51Job', '智通人才', '拉勾招聘',
                               '拉勾网', '猎聘', '猎聘同道', '猎聘网', '脉脉',
                               'LinkedIN领英')
                then ltime else 0 end) / 3600000 as h_job,
       -- 兼职 APP
       max(case when lcode in ('兼客兼职', '兼职猫', '口袋兼职', '大学生兼职', '天天兼职',
                               '掌上兼职', '淘兼职', '青团社兼职')
                then 1 else 0 end) as parttime,
       -- 其他零工：家政、维修师傅端（不进入"铁人三项"状态，单独标记）
       max(case when lcode in ('阿姨一点通', '万师傅', '安师傅')
                then 1 else 0 end) as other_gig
from user_app
where city = 'V0110000' and date = 20250901
group by uid;


-- ---------------------------------------------------------------------
-- S3 停留点特征（一人一行）
--    ptype：1 居住地，2 工作地，0 其他；旧脚本把 3 归为工作地（推测为职住同地），这里沿用
--    weekday_day_time 等停留时长按秒处理（若 A5 结果显示单位不同，再改）
-- ---------------------------------------------------------------------
create table wl_tri_s3_poi_202509_v1 as
select uid,
       count(1) as n_poi,
       max(case when ptype in (2, 3) then 1 else 0 end) as has_work,
       sum(case when ptype in (2, 3) then weekday_day_time else 0 end) / 3600 as work_wkday_h,
       sum(weekday_day_time) / 3600 as all_wkday_day_h
from stay_poi
where city = 'V0110000' and date = 20250901 and is_core = 'Y'
group by uid;

-- 主居住点：ptype 1 或 3 中，夜间停留最长的那个
create table wl_tri_s3_home_202509_v1 as
select uid, city, lon, lat
from (select uid, city,
             weighted_centroid_lon as lon,
             weighted_centroid_lat as lat,
             row_number() over (partition by uid
                                order by weekday_eve_time + weekend_eve_time desc) as rk
      from stay_poi
      where city = 'V0110000' and date = 20250901 and is_core = 'Y'
        and ptype in (1, 3)) t
where rk = 1;

-- 主工作点：ptype 2 或 3 中，工作日白天停留最长的那个
create table wl_tri_s3_work_202509_v1 as
select uid, city, lon, lat
from (select uid, city,
             weighted_centroid_lon as lon,
             weighted_centroid_lat as lat,
             row_number() over (partition by uid
                                order by weekday_day_time desc) as rk
      from stay_poi
      where city = 'V0110000' and date = 20250901 and is_core = 'Y'
        and ptype in (2, 3)) t
where rk = 1;

-- 落到 250 米网格（写法与旧脚本一致）
create table wl_tri_s3_homefn_202509_v1 as
select h.uid, b.fnid as home_fnid, b.county_code as home_county
from wl_tri_s3_home_202509_v1 h
inner join wl_tri_grid_para_v1 g on h.city = g.city_code
inner join ss_city_grid b on
      (ceil((h.lon - g.lon_min) / g.dx) = b.gcol_4326 and
       ceil((h.lat - g.lat_min) / g.dy) = b.grow_4326)
where h.lon between g.lon_min and g.lon_max
  and h.lat between g.lat_min and g.lat_max;

create table wl_tri_s3_workfn_202509_v1 as
select w.uid, b.fnid as work_fnid, b.county_code as work_county
from wl_tri_s3_work_202509_v1 w
inner join wl_tri_grid_para_v1 g on w.city = g.city_code
inner join ss_city_grid b on
      (ceil((w.lon - g.lon_min) / g.dx) = b.gcol_4326 and
       ceil((w.lat - g.lat_min) / g.dy) = b.grow_4326)
where w.lon between g.lon_min and g.lon_max
  and w.lat between g.lat_min and g.lat_max;


-- ---------------------------------------------------------------------
-- S4 出行特征（一人一行；用于校验"在路上干活"，可选）
--    move_month 按日分区；若整月太慢，可只取工作日或只取前两周
-- ---------------------------------------------------------------------
create table wl_tri_s4_move_202509_v1 as
select uid,
       count(1) as n_trip,
       count(distinct to_date(stime)) as n_day_move,
       sum(distance) / 1000 as dist_km,
       sum(unix_timestamp(etime) - unix_timestamp(stime)) / 3600 as move_h
from move_month
where city = 'V0110000' and date between 20250901 and 20250930
  and unix_timestamp(etime) > unix_timestamp(stime)
  and distance > 0
group by uid;


-- ---------------------------------------------------------------------
-- S5 状态表（一人一行，本研究的核心中间表，不导出）
--    状态判定顺序：
--      1) 四类平台中有任一类 ≥ T 小时 → 取小时数最多的那一类（G1—G4）
--      2) 否则，有工作地且工作日白天停留 ≥ H 小时 → F 固定工作
--      3) 否则 → N 无固定工作（含失业、居家、退休、学生等，用年龄段区分）
--    is_multi：两类及以上平台都 ≥ T 小时（兼做）
-- ---------------------------------------------------------------------
create table wl_tri_state_202509_v1 as
select uid, wave, gender, age_g, origin, arpu_g, is_local, weight,
       home_fnid, home_county, work_fnid, work_county,
       h_food, h_ride, h_exp, h_frt, h_job,
       job_blue, job_general, job_white, parttime, other_gig,
       n_poi, has_work, work_wkday_h, all_wkday_day_h,
       n_trip, n_day_move, dist_km, move_h,
       (case when h_food >= 50 then 1 else 0 end      -- 【T】
      + case when h_ride >= 50 then 1 else 0 end      -- 【T】
      + case when h_exp  >= 50 then 1 else 0 end      -- 【T】
      + case when h_frt  >= 50 then 1 else 0 end)     -- 【T】
         as n_gig_type,
       case when (case when h_food >= 50 then 1 else 0 end      -- 【T】
                + case when h_ride >= 50 then 1 else 0 end      -- 【T】
                + case when h_exp  >= 50 then 1 else 0 end      -- 【T】
                + case when h_frt  >= 50 then 1 else 0 end) >= 2  -- 【T】
            then 1 else 0 end as is_multi,
       case when h_food >= 50 and h_food >= h_ride and h_food >= h_exp and h_food >= h_frt then 'G1外卖即配'  -- 【T】
            when h_ride >= 50 and h_ride >= h_exp and h_ride >= h_frt                     then 'G2网约车'    -- 【T】
            when h_exp  >= 50 and h_exp  >= h_frt                                         then 'G3快递'      -- 【T】
            when h_frt  >= 50                                                             then 'G4货运代驾'  -- 【T】
            when has_work = 1 and work_wkday_h >= 40                                      then 'F固定工作'   -- 【H】
            else 'N无固定工作' end as state
from (select b.uid,
             202509 as wave,
             b.gender, b.age_g, b.origin, b.arpu_g, b.is_local, b.weight,
             hf.home_fnid, hf.home_county, wf.work_fnid, wf.work_county,
             coalesce(a.h_food, 0)      as h_food,
             coalesce(a.h_ride, 0)      as h_ride,
             coalesce(a.h_exp, 0)       as h_exp,
             coalesce(a.h_frt, 0)       as h_frt,
             coalesce(a.h_job, 0)       as h_job,
             coalesce(a.job_blue, 0)    as job_blue,
             coalesce(a.job_general, 0) as job_general,
             coalesce(a.job_white, 0)   as job_white,
             coalesce(a.parttime, 0)    as parttime,
             coalesce(a.other_gig, 0)   as other_gig,
             coalesce(p.n_poi, 0)           as n_poi,
             coalesce(p.has_work, 0)        as has_work,
             coalesce(p.work_wkday_h, 0)    as work_wkday_h,
             coalesce(p.all_wkday_day_h, 0) as all_wkday_day_h,
             coalesce(m.n_trip, 0)      as n_trip,
             coalesce(m.n_day_move, 0)  as n_day_move,
             coalesce(m.dist_km, 0)     as dist_km,
             coalesce(m.move_h, 0)      as move_h
      from wl_tri_s1_base_202509_v1 b
      left join wl_tri_s2_app_202509_v1     a  on b.uid = a.uid
      left join wl_tri_s3_poi_202509_v1     p  on b.uid = p.uid
      left join wl_tri_s3_homefn_202509_v1  hf on b.uid = hf.uid
      left join wl_tri_s3_workfn_202509_v1  wf on b.uid = wf.uid
      left join wl_tri_s4_move_202509_v1    m  on b.uid = m.uid) t;
-- 若没有跑 S4，把上面 m 的 left join 删掉，并把 n_trip 等 4 个字段改成 0 as n_trip …


-- =====================================================================
-- 以下为本步骤的检查性导出（全部只读状态表，结果无 uid）
-- =====================================================================

-- 【导出 E1】各状态 × 是否兼做 × 年龄段 的人数与扩样人数
--   6 × 2 × 8 ≈ 96 行
select wave, state, is_multi, age_g,
       count(1)           as n_user,
       round(sum(weight)) as n_weighted
from wl_tri_state_202509_v1
group by wave, state, is_multi, age_g;

-- 【导出 E2】各状态的求职、兼职、其他零工 APP 使用情况
--   6 × 2 × 2 × 2 × 2 × 2 = 192 行
select wave, state, job_blue, job_general, job_white, parttime, other_gig,
       count(1) as n_user
from wl_tri_state_202509_v1
group by wave, state, job_blue, job_general, job_white, parttime, other_gig;

-- 【导出 E3】行为校验：各状态的停留点数、出行时长分布
--   6 × 4 × 4 = 96 行
create table wl_tri_e3_202509_v1 as
select wave, state,
       case when n_poi < 5 then 'a <5' when n_poi < 10 then 'b 5-9'
            when n_poi < 20 then 'c 10-19' else 'd 20+' end as poi_bin,
       case when move_h < 20 then 'a <20h' when move_h < 60 then 'b 20-60h'
            when move_h < 120 then 'c 60-120h' else 'd 120h+' end as move_bin
from wl_tri_state_202509_v1;

select wave, state, poi_bin, move_bin, count(1) as n_user
from wl_tri_e3_202509_v1
group by wave, state, poi_bin, move_bin;

-- 【导出 E4】阈值敏感性：四类平台小时数分档 × 状态（看 T 取 20/50/100 时人数怎么变）
--   4 类 × 6 档 = 24 行
create table wl_tri_e4_202509_v1 as
select app_type, hour_bin from (
select 'h_food' as app_type,
       case when h_food = 0 then 'a 0' when h_food < 20 then 'b 0-20h' when h_food < 50 then 'c 20-50h'
            when h_food < 100 then 'd 50-100h' when h_food < 200 then 'e 100-200h' else 'f 200h+' end as hour_bin
from wl_tri_state_202509_v1
union all
select 'h_ride',
       case when h_ride = 0 then 'a 0' when h_ride < 20 then 'b 0-20h' when h_ride < 50 then 'c 20-50h'
            when h_ride < 100 then 'd 50-100h' when h_ride < 200 then 'e 100-200h' else 'f 200h+' end
from wl_tri_state_202509_v1
union all
select 'h_exp',
       case when h_exp = 0 then 'a 0' when h_exp < 20 then 'b 0-20h' when h_exp < 50 then 'c 20-50h'
            when h_exp < 100 then 'd 50-100h' when h_exp < 200 then 'e 100-200h' else 'f 200h+' end
from wl_tri_state_202509_v1
union all
select 'h_frt',
       case when h_frt = 0 then 'a 0' when h_frt < 20 then 'b 0-20h' when h_frt < 50 then 'c 20-50h'
            when h_frt < 100 then 'd 50-100h' when h_frt < 200 then 'e 100-200h' else 'f 200h+' end
from wl_tri_state_202509_v1
) u;

select app_type, hour_bin, count(1) as n_user
from wl_tri_e4_202509_v1
group by app_type, hour_bin;

-- 【导出 E5】平台从业者居住地、工作地所在区县（地图用）
--   状态 6 × 区县 16（含未落网格的空值）≈ 110 行；两段各一次
select wave, state, home_county, count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_state_202509_v1
group by wave, state, home_county;

select wave, state, work_county, count(1) as n_user, round(sum(weight)) as n_weighted
from wl_tri_state_202509_v1
group by wave, state, work_county;


-- =====================================================================
-- 自查清单（v1）
--  含 uid 明细的语句：S1、S2、S3（5 条）、S4、S5、E3 建表、E4 建表 —— 全部为 CREATE TABLE
--  S0、E3、E4 的建表不含 uid 列；状态表含 uid，只留在系统内
--  【导出】语句：E1、E2、E3、E4、E5（2 条）—— 只读状态表或其派生表，结果列无 uid，
--               不按 uid 关联，uid 不出现
--  预计导出行数：E1 ≈96，E2 ≤192，E3 ≤96，E4 ≤24，E5 各 ≈110 —— 均远小于 1 万行
--  每期产生的中间表：s1_base、s2_app、s3_poi、s3_home、s3_work、s3_homefn、s3_workfn、
--                    s4_move、state、e3、e4（共 11 张，名称均带 _202509_v1）
-- =====================================================================
