# DV Coverage — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_PROF.md](DV_PROF.md), [DV_ERROR.md](DV_ERROR.md),
[DV_CROSS.md](DV_CROSS.md), [DV_FORMAL.md](DV_FORMAL.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

Generated on `2026-04-29` from ordered isolated UCDB JSON under `tb/REPORT/coverage/`.
Zero-delta cases are retained when they close functional, cross, or no-restart frame intent.

---

## Legend

✅ pass / closed &middot; ⚠️ partial / below target / known limitation &middot; ❌ failed / missing evidence &middot; ❓ pending &middot; ℹ️ informational

---

## 1. Per-bucket Tables

### 1.1 BASIC

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| B001 | d | stmt=54.51, branch=32.41, cond=10.95, expr=30.00, toggle=15.55, total=28.68 | 0 | delta_total=28.68; merged_total=28.68; adds_code |
| B002 | d | stmt=54.51, branch=33.79, cond=10.95, expr=30.00, toggle=15.55, total=28.96 | 0 | delta_total=0.28; merged_total=28.96; adds_code |
| B003 | d | stmt=55.12, branch=35.86, cond=10.95, expr=30.00, toggle=15.70, total=29.52 | 0 | delta_total=0.74; merged_total=29.70; adds_code |
| B004 | d | stmt=55.42, branch=36.55, cond=10.95, expr=30.00, toggle=15.79, total=29.74 | 0 | delta_total=0.22; merged_total=29.92; adds_code |
| B005 | d | stmt=55.42, branch=36.55, cond=10.95, expr=30.00, toggle=15.64, total=29.71 | 0 | delta_total=0.21; merged_total=30.13; adds_code |
| B006 | d | stmt=55.42, branch=36.55, cond=10.95, expr=30.00, toggle=15.66, total=29.71 | 0 | delta_total=0.20; merged_total=30.33; adds_code |
| B007 | d | stmt=55.12, branch=36.55, cond=12.32, expr=30.00, toggle=15.70, total=29.94 | 0 | delta_total=0.41; merged_total=30.74; adds_code |
| B008 | d | stmt=54.81, branch=33.10, cond=10.95, expr=30.00, toggle=15.74, total=28.92 | 0 | delta_total=0.21; merged_total=30.95; adds_code |
| B009 | d | stmt=54.81, branch=33.10, cond=10.95, expr=30.00, toggle=15.66, total=28.90 | 0 | delta_total=0.21; merged_total=31.16; adds_code |
| B010 | d | stmt=58.43, branch=37.93, cond=15.06, expr=50.00, toggle=16.99, total=35.68 | 0 | delta_total=6.64; merged_total=37.80; adds_code |
| B011 | d | stmt=54.81, branch=33.10, cond=10.95, expr=30.00, toggle=15.81, total=28.94 | 0 | delta_total=0.22; merged_total=38.02; adds_code |
| B012 | d | stmt=57.53, branch=35.86, cond=10.95, expr=30.00, toggle=15.74, total=30.01 | 0 | delta_total=1.16; merged_total=39.18; adds_code |
| B013 | d | stmt=57.53, branch=35.86, cond=10.95, expr=30.00, toggle=16.36, total=30.14 | 0 | delta_total=0.13; merged_total=39.31; adds_code |
| B014 | d | stmt=55.42, branch=35.17, cond=12.32, expr=30.00, toggle=15.74, total=29.73 | 0 | delta_total=0.28; merged_total=39.59; adds_code |
| B015 | d | stmt=62.04, branch=44.13, cond=12.32, expr=30.00, toggle=15.79, total=32.86 | 0 | delta_total=3.21; merged_total=42.80; adds_code |
| B016 | d | stmt=57.53, branch=40.00, cond=10.95, expr=30.00, toggle=15.68, total=30.83 | 0 | delta_total=0.40; merged_total=43.20; adds_code |
| B017 | d | stmt=71.68, branch=54.48, cond=23.28, expr=30.00, toggle=20.32, total=39.95 | 0 | delta_total=9.12; merged_total=52.32; adds_code |
| B018 | d | stmt=75.00, branch=57.93, cond=30.13, expr=50.00, toggle=20.47, total=46.70 | 0 | delta_total=1.24; merged_total=53.56; adds_code |
| B019 | d | stmt=56.02, branch=36.55, cond=10.95, expr=30.00, toggle=16.36, total=29.98 | 0 | delta_total=1.09; merged_total=54.65; adds_code |
| B020 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.78, total=29.66 | 0 | delta_total=0.89; merged_total=55.54; adds_code |
| B021 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.18 | 0 | delta_total=0.75; merged_total=56.29; adds_code |
| B022 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.18 | 0 | delta_total=0.00; merged_total=56.29; zero_delta |
| B023 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.18 | 0 | delta_total=0.00; merged_total=56.29; zero_delta |
| B024 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.18 | 0 | delta_total=0.00; merged_total=56.29; zero_delta |
| B025 | d | stmt=56.02, branch=31.03, cond=12.32, expr=40.00, toggle=15.30, total=30.93 | 0 | delta_total=3.64; merged_total=59.93; adds_code |
| B026 | d | stmt=53.01, branch=28.96, cond=6.84, expr=30.00, toggle=15.28, total=26.82 | 0 | delta_total=0.00; merged_total=59.93; zero_delta |
| B027 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=59.93; zero_delta |
| B028 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.18 | 0 | delta_total=0.00; merged_total=59.93; zero_delta |
| B029 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.26; merged_total=60.19; adds_code |
| B030 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.14; merged_total=60.33; adds_code |
| B031 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.14; merged_total=60.47; adds_code |
| B032 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=19.17, total=33.97 | 0 | delta_total=0.00; merged_total=60.47; zero_delta |
| B033 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.00; merged_total=60.47; zero_delta |
| B034 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=60.47; zero_delta |
| B035 | d | stmt=56.32, branch=33.10, cond=10.95, expr=50.00, toggle=16.44, total=33.36 | 0 | delta_total=0.13; merged_total=60.60; adds_code |
| B036 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=19.17, total=33.97 | 0 | delta_total=0.00; merged_total=60.60; zero_delta |
| B037 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.00; merged_total=60.60; zero_delta |
| B038 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.00; merged_total=60.60; zero_delta |
| B039 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.00; merged_total=60.60; zero_delta |
| B040 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=60.60; zero_delta |
| B041 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=20.69, total=42.12 | 0 | delta_total=1.44; merged_total=62.04; adds_code |
| B042 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=19.95, total=41.97 | 0 | delta_total=0.01; merged_total=62.05; adds_code |
| B043 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=20.67, total=42.11 | 0 | delta_total=0.00; merged_total=62.05; adds_code |
| B044 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=20.65, total=42.11 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B045 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=21.30, total=42.24 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B046 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=20.60, total=42.10 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B047 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=20.62, total=42.10 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B048 | d | stmt=57.53, branch=35.86, cond=12.32, expr=50.00, toggle=18.05, total=34.75 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B049 | d | stmt=71.08, branch=48.27, cond=20.54, expr=50.00, toggle=19.95, total=41.97 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B050 | d | stmt=72.28, branch=51.72, cond=30.13, expr=50.00, toggle=21.29, total=45.08 | 0 | delta_total=0.00; merged_total=62.05; zero_delta |
| B051 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.68, total=29.64 | 0 | delta_total=0.01; merged_total=62.06; adds_code |
| B052 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.68, total=29.64 | 0 | delta_total=0.00; merged_total=62.06; zero_delta |
| B053 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.70, total=29.64 | 0 | delta_total=0.00; merged_total=62.06; adds_code |
| B054 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.70, total=29.64 | 0 | delta_total=0.48; merged_total=62.54; adds_code |
| B055 | d | stmt=58.73, branch=38.62, cond=13.69, expr=50.00, toggle=15.72, total=35.35 | 0 | delta_total=0.00; merged_total=62.54; zero_delta |
| B056 | d | stmt=59.33, branch=40.00, cond=13.69, expr=50.00, toggle=15.89, total=35.78 | 0 | delta_total=0.61; merged_total=63.15; adds_code |
| B057 | d | stmt=58.73, branch=38.62, cond=15.06, expr=50.00, toggle=15.66, total=35.61 | 0 | delta_total=0.00; merged_total=63.15; zero_delta |
| B058 | d | stmt=58.13, branch=37.24, cond=10.95, expr=50.00, toggle=19.53, total=35.17 | 0 | delta_total=0.00; merged_total=63.15; zero_delta |
| B059 | d | stmt=58.13, branch=37.24, cond=15.06, expr=40.00, toggle=15.57, total=33.20 | 0 | delta_total=4.83; merged_total=67.98; adds_code |
| B060 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B061 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B062 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B063 | d | stmt=60.84, branch=41.37, cond=12.32, expr=30.00, toggle=15.68, total=32.04 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B064 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.66, total=29.64 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B065 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B066 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B067 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B068 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.55, total=29.61 | 0 | delta_total=0.00; merged_total=67.98; zero_delta |
| B071 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.20; merged_total=68.18; adds_code |
| B072 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B073 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B074 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B075 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B076 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B077 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B078 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B079 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |
| B080 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=17.37, total=35.22 | 0 | delta_total=0.00; merged_total=68.18; zero_delta |

BASIC ordered isolated merged total: `stmt=94.87, branch=87.58, cond=50.68, expr=80.00, toggle=27.76, total=68.18`

### 1.2 EDGE

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| E001 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.81, total=35.50 | 0 | delta_total=0.47; merged_total=68.65; adds_code |
| E002 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.13, total=35.36 | 0 | delta_total=0.00; merged_total=68.65; zero_delta |
| E003 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.81, total=35.50 | 0 | delta_total=0.00; merged_total=68.65; zero_delta |
| E004 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.93, total=35.52 | 0 | delta_total=0.02; merged_total=68.67; adds_code |
| E005 | d | stmt=57.83, branch=36.55, cond=12.32, expr=50.00, toggle=19.48, total=35.23 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E006 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.81, total=35.50 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E007 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.81, total=35.50 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E008 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.13, total=35.36 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E009 | d | stmt=58.43, branch=37.93, cond=12.32, expr=50.00, toggle=18.13, total=35.36 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E010 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.62, total=29.63 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E011 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.00; merged_total=68.67; zero_delta |
| E012 | d | stmt=57.53, branch=36.55, cond=12.32, expr=50.00, toggle=18.79, total=35.04 | 0 | delta_total=0.14; merged_total=68.81; adds_code |
| E013 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=17.81, total=33.70 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E014 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E015 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E016 | d | stmt=59.33, branch=34.48, cond=15.06, expr=60.00, toggle=18.49, total=37.47 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E017 | d | stmt=56.62, branch=33.10, cond=10.95, expr=50.00, toggle=18.49, total=33.83 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E018 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.61, total=34.20 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E019 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.91, total=34.26 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E020 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=17.12, total=34.50 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E021 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=17.12, total=34.50 | 0 | delta_total=0.00; merged_total=68.81; zero_delta |
| E022 | d | stmt=79.51, branch=60.00, cond=23.28, expr=50.00, toggle=17.45, total=46.05 | 0 | delta_total=1.78; merged_total=70.59; adds_code |
| E023 | d | stmt=76.50, branch=55.17, cond=21.91, expr=50.00, toggle=17.39, total=44.19 | 0 | delta_total=0.54; merged_total=71.13; adds_code |
| E024 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=71.13; zero_delta |
| E025 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=71.13; zero_delta |
| E026 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.70, total=34.89 | 0 | delta_total=0.00; merged_total=71.13; zero_delta |
| E027 | d | stmt=58.13, branch=37.93, cond=15.06, expr=50.00, toggle=15.79, total=35.38 | 0 | delta_total=0.00; merged_total=71.13; zero_delta |
| E028 | d | stmt=74.39, branch=55.86, cond=39.72, expr=50.00, toggle=20.49, total=48.09 | 0 | delta_total=0.99; merged_total=72.12; adds_code |
| E029 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.57, total=29.62 | 0 | delta_total=0.00; merged_total=72.12; zero_delta |
| E030 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.62, total=29.63 | 0 | delta_total=0.00; merged_total=72.12; zero_delta |
| E031 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.12; zero_delta |
| E032 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.12; zero_delta |
| E033 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.61, total=29.23 | 0 | delta_total=0.00; merged_total=72.12; zero_delta |
| E034 | d | stmt=54.51, branch=32.41, cond=10.95, expr=30.00, toggle=15.55, total=28.68 | 0 | delta_total=0.27; merged_total=72.39; adds_code |
| E035 | d | stmt=54.51, branch=33.79, cond=10.95, expr=30.00, toggle=15.55, total=28.96 | 0 | delta_total=0.28; merged_total=72.67; adds_code |
| E036 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E037 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E038 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E039 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E040 | d | stmt=54.51, branch=33.79, cond=10.95, expr=30.00, toggle=15.55, total=28.96 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E041 | d | stmt=57.22, branch=34.48, cond=15.06, expr=50.00, toggle=15.45, total=34.44 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E042 | d | stmt=57.22, branch=34.48, cond=15.06, expr=50.00, toggle=15.45, total=34.44 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E043 | d | stmt=57.22, branch=34.48, cond=15.06, expr=50.00, toggle=15.45, total=34.44 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E044 | d | stmt=57.22, branch=34.48, cond=15.06, expr=50.00, toggle=15.45, total=34.44 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E045 | d | stmt=57.22, branch=34.48, cond=15.06, expr=50.00, toggle=15.45, total=34.44 | 0 | delta_total=0.00; merged_total=72.67; zero_delta |
| E046 | d | stmt=58.13, branch=37.93, cond=15.06, expr=50.00, toggle=16.90, total=35.60 | 0 | delta_total=0.13; merged_total=72.80; adds_code |
| E047 | d | stmt=58.73, branch=40.00, cond=16.43, expr=50.00, toggle=19.80, total=36.99 | 0 | delta_total=0.72; merged_total=73.52; adds_code |
| E048 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=73.52; zero_delta |
| E049 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=73.52; zero_delta |
| E050 | d | stmt=54.81, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.16 | 0 | delta_total=0.14; merged_total=73.66; adds_code |

EDGE ordered isolated merged total: `stmt=96.68, branch=93.79, cond=68.49, expr=80.00, toggle=29.36, total=73.66`

### 1.3 PROF

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| P001 | d | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.90, total=35.40 | 0 | delta_total=0.47; merged_total=74.13; adds_code |
| P002 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.90, total=35.40 | 4 | delta_total=0.00; merged_total=74.13; zero_delta |
| P003 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.12, total=35.45 | 4 | delta_total=0.00; merged_total=74.13; zero_delta |
| P004 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.50, total=35.52 | 1 | delta_total=0.00; merged_total=74.13; zero_delta |
| P005 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.65, total=35.55 | 1 | delta_total=0.00; merged_total=74.13; zero_delta |
| P006 | d | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=15.98, total=35.22 | 0 | delta_total=0.00; merged_total=74.13; zero_delta |
| P007 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.21, total=35.26 | 4 | delta_total=0.00; merged_total=74.13; zero_delta |
| P008 | d | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.06, total=35.23 | 0 | delta_total=0.00; merged_total=74.13; zero_delta |
| P009 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.74, total=35.37 | 2 | delta_total=0.00; merged_total=74.13; zero_delta |
| P010 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.20, total=35.46 | 2 | delta_total=0.00; merged_total=74.13; zero_delta |
| P011 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=74.13; zero_delta |
| P012 | r | stmt=54.21, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.12 | 4 | delta_total=0.69; merged_total=74.82; adds_code |
| P013 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=74.82; zero_delta |
| P014 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=74.82; zero_delta |
| P015 | r | stmt=54.21, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.12 | 4 | delta_total=0.00; merged_total=74.82; zero_delta |
| P016 | r | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 2 | delta_total=0.00; merged_total=74.82; zero_delta |
| P017 | r | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 2 | delta_total=0.00; merged_total=74.82; zero_delta |
| P018 | r | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 2 | delta_total=0.00; merged_total=74.82; zero_delta |
| P019 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=74.82; zero_delta |
| P020 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=74.82; zero_delta |
| P021 | d | stmt=64.45, branch=51.72, cond=19.17, expr=50.00, toggle=16.84, total=40.44 | 0 | delta_total=0.98; merged_total=75.80; adds_code |
| P022 | d | stmt=65.06, branch=53.10, cond=20.54, expr=50.00, toggle=17.07, total=41.15 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P023 | d | stmt=64.45, branch=51.72, cond=19.17, expr=50.00, toggle=20.56, total=41.18 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P024 | d | stmt=61.44, branch=48.96, cond=15.06, expr=30.00, toggle=16.69, total=34.43 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P025 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P026 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P027 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P028 | d | stmt=55.72, branch=35.86, cond=10.95, expr=30.00, toggle=15.89, total=29.68 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P029 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P030 | d | stmt=56.92, branch=33.10, cond=15.06, expr=40.00, toggle=15.30, total=32.08 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| P031 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.44, total=35.31 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P032 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.97, total=35.42 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P033 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.59, total=35.34 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P034 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.82, total=35.39 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P035 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.52, total=35.33 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P036 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.12, total=35.45 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P037 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=16.67, total=35.36 | 18 | delta_total=0.00; merged_total=75.80; zero_delta |
| P038 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.05, total=35.43 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P039 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=17.35, total=35.49 | 10000 | delta_total=0.00; merged_total=75.80; zero_delta |
| P040 | r | stmt=57.83, branch=35.86, cond=16.43, expr=50.00, toggle=18.03, total=35.63 | 1 | delta_total=0.00; merged_total=75.80; zero_delta |

PROF ordered isolated merged total: `stmt=97.59, branch=96.55, cond=75.34, expr=80.00, toggle=29.55, total=75.80`

### 1.4 ERROR

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| X001 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| X002 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| X003 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| X004 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=75.80; zero_delta |
| X005 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=16.82, total=31.28 | 0 | delta_total=0.21; merged_total=76.01; adds_code |
| X006 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X007 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X008 | d | stmt=59.33, branch=37.93, cond=12.32, expr=30.00, toggle=15.64, total=31.04 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X009 | d | stmt=57.83, branch=35.86, cond=15.06, expr=50.00, toggle=15.68, total=34.88 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X010 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.45, total=34.17 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X011 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.51, total=34.18 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X012 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X013 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X014 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X015 | d | stmt=71.38, branch=49.65, cond=28.76, expr=40.00, toggle=20.17, total=41.99 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X016 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=76.01; zero_delta |
| X017 | d | stmt=71.08, branch=48.96, cond=26.02, expr=40.00, toggle=20.17, total=41.25 | 0 | delta_total=2.27; merged_total=78.28; adds_code |
| X018 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X019 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X020 | d | stmt=56.02, branch=31.03, cond=12.32, expr=40.00, toggle=15.30, total=30.93 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X021 | d | stmt=56.62, branch=33.10, cond=15.06, expr=40.00, toggle=15.30, total=32.02 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X022 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X023 | d | stmt=57.22, branch=34.48, cond=13.69, expr=50.00, toggle=15.57, total=34.19 | 0 | delta_total=0.00; merged_total=78.28; zero_delta |
| X024 | d | stmt=54.51, branch=32.41, cond=13.69, expr=30.00, toggle=15.32, total=29.19 | 0 | delta_total=0.75; merged_total=79.03; adds_code |
| X025 | d | stmt=55.12, branch=34.48, cond=10.95, expr=30.00, toggle=15.55, total=29.22 | 0 | delta_total=0.00; merged_total=79.03; zero_delta |
| X026 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=79.03; zero_delta |
| X027 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=79.03; zero_delta |
| X028 | d | stmt=54.51, branch=33.79, cond=10.95, expr=30.00, toggle=15.55, total=28.96 | 0 | delta_total=0.00; merged_total=79.03; zero_delta |
| X029 | d | stmt=54.81, branch=33.79, cond=10.95, expr=30.00, toggle=15.59, total=29.03 | 0 | delta_total=0.00; merged_total=79.03; zero_delta |
| X030 | d | stmt=54.81, branch=33.79, cond=12.32, expr=30.00, toggle=16.36, total=29.46 | 0 | delta_total=0.13; merged_total=79.16; adds_code |
| X031 | d | stmt=54.81, branch=34.48, cond=10.95, expr=30.00, toggle=15.62, total=29.17 | 0 | delta_total=0.00; merged_total=79.16; zero_delta |
| X032 | d | stmt=55.72, branch=35.17, cond=10.95, expr=30.00, toggle=15.74, total=29.51 | 0 | delta_total=0.47; merged_total=79.63; adds_code |
| X033 | d | stmt=54.81, branch=33.79, cond=10.95, expr=30.00, toggle=15.66, total=29.04 | 0 | delta_total=0.00; merged_total=79.63; zero_delta |
| X034 | d | stmt=54.51, branch=33.79, cond=10.95, expr=30.00, toggle=15.55, total=28.96 | 0 | delta_total=0.00; merged_total=79.63; zero_delta |
| X035 | d | stmt=72.59, branch=51.72, cond=20.54, expr=50.00, toggle=17.63, total=42.49 | 0 | delta_total=0.06; merged_total=79.69; adds_code |
| X036 | d | stmt=71.38, branch=53.10, cond=20.54, expr=50.00, toggle=17.72, total=42.55 | 0 | delta_total=0.95; merged_total=80.64; adds_code |
| X037 | d | stmt=54.21, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.12 | 0 | delta_total=0.00; merged_total=80.64; zero_delta |
| X038 | d | stmt=67.77, branch=46.89, cond=19.17, expr=30.00, toggle=16.34, total=36.03 | 0 | delta_total=0.54; merged_total=81.18; adds_code |
| X039 | d | stmt=56.32, branch=37.24, cond=17.80, expr=30.00, toggle=15.85, total=31.44 | 0 | delta_total=1.88; merged_total=83.06; adds_code |
| X040 | d | stmt=73.49, branch=54.48, cond=28.76, expr=50.00, toggle=20.34, total=45.41 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X041 | d | stmt=59.63, branch=35.86, cond=19.17, expr=70.00, toggle=19.17, total=40.77 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X042 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X043 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X044 | d | stmt=54.21, branch=31.72, cond=10.95, expr=30.00, toggle=15.30, total=28.44 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X045 | d | stmt=67.16, branch=45.51, cond=17.80, expr=30.00, toggle=16.05, total=35.31 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X046 | d | stmt=54.21, branch=32.41, cond=13.69, expr=30.00, toggle=15.30, total=29.12 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X047 | d | stmt=53.01, branch=28.96, cond=6.84, expr=30.00, toggle=15.28, total=26.82 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X048 | d | stmt=53.01, branch=28.96, cond=6.84, expr=30.00, toggle=15.28, total=26.82 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X049 | d | stmt=53.01, branch=28.96, cond=6.84, expr=30.00, toggle=15.28, total=26.82 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |
| X050 | d | stmt=53.01, branch=28.96, cond=6.84, expr=30.00, toggle=15.28, total=26.82 | 0 | delta_total=0.00; merged_total=83.06; zero_delta |

ERROR ordered isolated merged total: `stmt=99.09, branch=100.00, cond=94.52, expr=90.00, toggle=31.71, total=83.06`

---

## 2. `all_buckets_frame` Total

`all_buckets_frame` functional total: `218/218 runtime cases observed with UVM_ERROR=0 and UVM_FATAL=0`.

---

## 3. Sign-off Totals

| Category | Target | Signoff merged primary+max32 | Status |
|----------|--------|-------------------------------|--------|
| Statement | >= 95% | 99.09% | ✅ |
| Branch | >= 90% | 100.00% | ✅ |
| Condition | >= 85% | 94.52% | ✅ |
| Expression | >= 85% | 90.00% | ✅ |
| FSM state | n/a | no DUT FSM coverage class emitted by Questa | ✅ |
| FSM transition | n/a | no DUT FSM coverage class emitted by Questa | ✅ |
| Toggle | >= 80% | 80.98% | ✅ |
| Functional cross | >= 95% | 100.00% (218/218 promoted cases) | ✅ |

Merged total coverage: `92.92%`.

---

## 4. Per-build Coverage Snapshots

| BUILD | Statement | Branch | Condition | Expression | Toggle | Total |
|-------|-----------|--------|-----------|------------|--------|-------|
| `cov_primary` | 99.09% | 100.00% | 94.52% | 90.00% | 31.71% | 83.06% |
| `max32` | 92.77% | 94.48% | 82.19% | 90.00% | 80.74% | 88.03% |

---

This dashboard is generated by `tb/uvm/script/generate_dv_cov.py`.
Regenerate with `python3 tb/uvm/script/generate_dv_cov.py` after refreshing coverage JSON and summary artifacts.
