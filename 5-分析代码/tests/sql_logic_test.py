"""用模拟数据在本地 DuckDB 中跑通 02_截面汇总（A、B 部分）和 03_转移汇总，
并与 Python 独立计算的结果对照，检查 SQL 逻辑是否正确；
另检查所有 SQL 文件符合平台规则：导出语句不出现 uid（否则报"对uid进行非法操作"），
全文不出现星号字符（否则报"出现非法字符"）。

用法：python3 sql_logic_test.py <2-SQL 目录>
说明：01_状态表 依赖平台专有函数（to_date、unix_timestamp），不在本测试范围。
"""
import glob
import random
import re
import sys

import duckdb
import pandas as pd

SQLDIR = sys.argv[1]
STATES = ['G1外卖即配', 'G2网约车', 'G3快递', 'G4货运代驾', 'F固定工作', 'N无固定工作']
WAVES = [y * 100 + m for y in range(2019, 2026) for m in (3, 6, 9, 12)]
COLS = ("uid, wave, state, is_multi, n_gig_type, gender, age_g, origin, arpu_g, is_local, weight, "
        "home_fnid, home_county, work_fnid, work_county, h_food, h_ride, h_exp, h_frt, h_job, "
        "job_blue, job_general, job_white, parttime, other_gig")


def run_sql(con, path, start=None, stop=None, token=None):
    s = open(path, encoding='utf-8').read()
    if start:
        s = s[s.index(start):]
    if stop:
        s = s[:s.index(stop)]
    s = re.sub(r'--[^\n]*', '', s)
    out = []
    for st in [x.strip() for x in s.split(';') if x.strip()]:
        st = st.replace(' / 100 as int)', ' // 100 as int)').replace('(wave % 100) / 3', '(wave % 100) // 3')
        try:
            r = con.execute(st)
            if not st.lower().startswith('create'):
                out.append(len(r.fetchall()))
        except Exception as e:  # noqa: BLE001
            print('ERROR:', ' '.join(st.split())[:120], '\n   ', str(e)[:200])
            out.append(-1)
    return out


def test_platform_rules():
    bad = []
    for path in sorted(glob.glob(f'{SQLDIR}/*.sql')):
        raw = open(path, encoding='utf-8').read()
        bad += [f"{path}:{i}: '*' {line.strip()[:80]}" for i, line in enumerate(raw.splitlines(), 1) if '*' in line]
        s = re.sub(r'--[^\n]*', '', raw)
        for st in [x.strip() for x in s.split(';') if x.strip()]:
            if not st.lower().startswith('create') and re.search(r'\buid\b', st, re.I):
                bad.append(f"{path}: uid in export: {' '.join(st.split())[:100]}")
    assert not bad, 'platform rule violations:\n' + '\n'.join(bad)
    print("OK platform rules: no uid in exports, no '*'")


def test_panel_and_transitions():
    random.seed(1)
    con = duckdb.connect()
    truth, rows = {}, []
    for u in range(1, 401):
        cur, hist, present = random.choice(STATES), {}, True
        for w in WAVES:
            if random.random() < 0.06:
                present = not present
            if present:
                if random.random() < 0.35:
                    cur = random.choice(STATES)
                hist[w] = cur
        truth[u] = hist
    for u, h in truth.items():
        for w, s in h.items():
            jb, jg, jw = (int(random.random() < p) for p in (0.2, 0.3, 0.1))
            rows.append((u, w, s, 0, int(s.startswith('G')), '01', 'b25-34', 'c河南', 'b50-100', 'N', 1.5,
                         1000 + u % 50, '110105', 2000 + u % 30 if s == 'F固定工作' else None,
                         '110108' if s == 'F固定工作' else None,
                         120.0 * (s == 'G1外卖即配'), 120.0 * (s == 'G2网约车'), 120.0 * (s == 'G3快递'),
                         120.0 * (s == 'G4货运代驾'), 3.0 * (jb + jg + jw), jb, jg, jw, 0, 0))
    df = pd.DataFrame(rows, columns=[c.strip() for c in COLS.split(',')])
    df['work_fnid'] = df['work_fnid'].astype('Int64')
    con.register('df_all', df)
    for w in WAVES:
        con.execute(f"create table wl_tri_state_{w}_v1 as select * from df_all where wave={w}")
    run_sql(con, f'{SQLDIR}/02_截面汇总.sql', start='-- B 跨期面板与趋势')
    res = run_sql(con, f'{SQLDIR}/03_转移汇总.sql', stop='-- T5（可选）')
    assert -1 not in res, '03 has SQL errors'

    rank = {w: i + 1 for i, w in enumerate(WAVES)}
    maxr = len(WAVES)
    exp = []
    for u, h in truth.items():
        byr = {rank[w]: s for w, s in h.items()}
        g = sorted(r for r, s in byr.items() if s.startswith('G'))
        k = 0
        while k < len(g):
            st = en = g[k]
            while k + 1 < len(g) and g[k + 1] == en + 1:
                k += 1
                en = g[k]
            entry = 'L左删失' if st == 1 else byr.get(st - 1, 'X不在库')
            exit_ = 'R右删失' if en == maxr else byr.get(en + 1, 'X不在库')
            exp.append((u, st, en, en - st + 1, byr[st], entry, exit_, len({byr[r] for r in range(st, en + 1)})))
            k += 1
    got = con.execute("select uid,start_rank,end_rank,len,type0,entry_state,exit_state,n_type "
                      "from wl_tri_t2_spell_v1 order by 1,2").fetchall()
    assert [tuple(x) for x in got] == sorted(exp), 'spell mismatch'
    pairs = con.execute("select count(*) from wl_tri_t1_pair_v1").fetchone()[0]
    assert pairs == sum(1 for h in truth.values() for w in h if rank[w] < maxr), 'pair count mismatch'
    xs = con.execute("select count(*) from wl_tri_t1_pair_v1 where s1='X不在库'").fetchone()[0]
    assert xs == sum(1 for h in truth.values() for w in h if rank[w] < maxr and WAVES[rank[w]] not in h)
    pp = con.execute("select count(*), sum(case when outcome<>'0继续' then 1 else 0 end) from wl_tri_t3_pp_v1").fetchone()
    assert pp[0] == sum(x[3] for x in exp) and pp[1] == len(exp), 'person-period mismatch'
    assert con.execute("select count(*) from wl_tri_t4_entry_v1 where k=-1 and state_k<>entry_state").fetchone()[0] == 0
    assert con.execute("select count(*) from wl_tri_t4_exit_v1 where k=1 and state_k<>exit_state").fetchone()[0] == 0
    print(f'OK 02B+03: {len(exp)} spells, {pairs} pairs, {xs} X-transitions, {pp[0]} person-periods')


def test_cross_section():
    random.seed(2)
    con = duckdb.connect()
    rows = []
    for u in range(1, 3001):
        h = [random.choice([0, 0, 0, 10, 30, 60, 150, 250]) for _ in range(4)]
        hw = random.random() < 0.6
        wk = random.choice([0, 20, 60, 150]) if hw else 0

        def st(t):
            best = max(range(4), key=lambda i: (h[i], -i))
            if h[best] >= t:
                return STATES[best]
            return 'F固定工作' if hw and wk >= 40 else 'N无固定工作'
        rows.append(dict(uid=u, wave=202509, state=st(50), is_multi=int(sum(x >= 50 for x in h) >= 2),
                         gender='01', age_g='b25-34', origin='c河南', arpu_g='b50-100', is_local='N', weight=1.2,
                         home_county='110105', work_county='110108', home_fnid=1000 + u % 40, work_fnid=2000 + u % 40,
                         h_food=h[0], h_ride=h[1], h_exp=h[2], h_frt=h[3], h_job=random.choice([0, 0.5, 3, 8, 30]),
                         job_blue=0, job_general=1, job_white=0, parttime=0, other_gig=0,
                         has_work=int(hw), work_wkday_h=wk, _t20=st(20), _t100=st(100)))
    df = pd.DataFrame(rows)
    con.register('d', df)
    con.execute("create table wl_tri_state_202509_v1 as select * exclude(_t20,_t100) from d")
    res = run_sql(con, f'{SQLDIR}/02_截面汇总.sql', stop='-- A-属性表')
    assert -1 not in res, '02 A has SQL errors'
    got = sorted(con.execute("select state,state_t20,state_t100 from wl_tri_c_202509_v1").fetchall())
    assert got == sorted((r['state'], r['_t20'], r['_t100']) for r in rows), 'threshold sensitivity mismatch'
    print(f'OK 02A: {len(res)} exports, T=20/50/100 states match')


if __name__ == '__main__':
    test_platform_rules()
    test_panel_and_transitions()
    test_cross_section()
