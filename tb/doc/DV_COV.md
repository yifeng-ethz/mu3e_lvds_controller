# DV Coverage — mu3e_lvds_controller (SV rebuild)

**Companion docs:** [DV_PLAN.md](DV_PLAN.md), [DV_HARNESS.md](DV_HARNESS.md),
[DV_BASIC.md](DV_BASIC.md), [DV_EDGE.md](DV_EDGE.md),
[DV_PROF.md](DV_PROF.md), [DV_ERROR.md](DV_ERROR.md),
[DV_CROSS.md](DV_CROSS.md), [DV_FORMAL.md](DV_FORMAL.md),
[BUG_HISTORY.md](../BUG_HISTORY.md)

This file is the maintained coverage ledger. It is populated as cases
land. Every row uses the strict per-bucket schema required by the
`dv-workflow` contract:

```
| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
```

Where:
- `case_id` — id from the corresponding bucket file
- `type (d/r)` — `d` for directed, `r` for random
- `coverage_by_this_case` — isolated UCDB result, key/value vector
  `stmt=…, branch=…, cond=…, expr=…, fsm=…, toggle=…`
- `executed random txn` — `0` for directed, transaction count for random
- `coverage_incr_per_txn` — for `r`-cases, per-txn isolated vector;
  for `d`-cases reuse the isolated vector once

---

## 1. Per-bucket Tables

### 1.1 BASIC

Running ordered isolated merged total (after each row):
- after `B001`: `pending`
- ... (rows are appended as the case is run; final merged total at
  the end of this section after closure)

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| B001 | d | pending | 0 | pending |
| B002 | d | pending | 0 | pending |
| B003 | d | pending | 0 | pending |
| B004 | d | pending | 0 | pending |
| B005 | d | pending | 0 | pending |
| B006 | d | pending | 0 | pending |
| B007 | d | pending | 0 | pending |
| B008 | d | pending | 0 | pending |
| B009 | d | pending | 0 | pending |
| B010 | d | pending | 0 | pending |
| B011 | d | pending | 0 | pending |
| B012 | d | pending | 0 | pending |
| B013 | d | pending | 0 | pending |
| B014 | d | pending | 0 | pending |
| B015 | d | pending | 0 | pending |
| B016 | d | pending | 0 | pending |
| B017 | d | pending | 0 | pending |
| B018 | d | pending | 0 | pending |
| B019 | d | pending | 0 | pending |
| B020 | d | pending | 0 | pending |
| B021 | d | pending | 0 | pending |
| B022 | d | pending | 0 | pending |
| B023 | d | pending | 0 | pending |
| B024 | d | pending | 0 | pending |
| B025 | d | pending | 0 | pending |
| B026 | d | pending | 0 | pending |
| B027 | d | pending | 0 | pending |
| B028 | d | pending | 0 | pending |
| B029 | d | pending | 0 | pending |
| B030 | d | pending | 0 | pending |
| B031 | d | pending | 0 | pending |
| B032 | d | pending | 0 | pending |
| B033 | d | pending | 0 | pending |
| B034 | d | pending | 0 | pending |
| B035 | d | pending | 0 | pending |
| B036 | d | pending | 0 | pending |
| B037 | d | pending | 0 | pending |
| B038 | d | pending | 0 | pending |
| B039 | d | pending | 0 | pending |
| B040 | d | pending | 0 | pending |
| B041 | d | pending | 0 | pending |
| B042 | d | pending | 0 | pending |
| B043 | d | pending | 0 | pending |
| B044 | d | pending | 0 | pending |
| B045 | d | pending | 0 | pending |
| B046 | d | pending | 0 | pending |
| B047 | d | pending | 0 | pending |
| B048 | d | pending | 0 | pending |
| B049 | d | pending | 0 | pending |
| B050 | d | pending | 0 | pending |
| B051 | d | pending | 0 | pending |
| B052 | d | pending | 0 | pending |
| B053 | d | pending | 0 | pending |
| B054 | d | pending | 0 | pending |
| B055 | d | pending | 0 | pending |
| B056 | d | pending | 0 | pending |
| B057 | d | pending | 0 | pending |
| B058 | d | pending | 0 | pending |
| B059 | d | pending | 0 | pending |
| B060 | d | pending | 0 | pending |
| B061 | d | pending | 0 | pending |
| B062 | d | pending | 0 | pending |
| B063 | d | pending | 0 | pending |
| B064 | d | pending | 0 | pending |
| B065 | d | pending | 0 | pending |
| B066 | d | pending | 0 | pending |
| B067 | d | pending | 0 | pending |
| B068 | d | pending | 0 | pending |
| B071 | d | pending | 0 | pending |
| B072 | d | pending | 0 | pending |
| B073 | d | pending | 0 | pending |
| B074 | d | pending | 0 | pending |
| B075 | d | pending | 0 | pending |
| B076 | d | pending | 0 | pending |
| B077 | d | pending | 0 | pending |
| B078 | d | pending | 0 | pending |
| B079 | d | pending | 0 | pending |
| B080 | d | pending | 0 | pending |

BASIC ordered isolated merged total: `pending`

BASIC `bucket_frame` merged total: `pending`

BASIC functional cross hit (per `DV_CROSS.md`): `pending`

### 1.2 EDGE

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| E001 | d | pending | 0 | pending |
| E002 | d | pending | 0 | pending |
| E003 | d | pending | 0 | pending |
| E004 | d | pending | 0 | pending |
| E005 | d | pending | 0 | pending |
| E006 | d | pending | 0 | pending |
| E007 | d | pending | 0 | pending |
| E008 | d | pending | 0 | pending |
| E009 | d | pending | 0 | pending |
| E010 | d | pending | 0 | pending |
| E011 | d | pending | 0 | pending |
| E012 | d | pending | 0 | pending |
| E013 | d | pending | 0 | pending |
| E014 | d | pending | 0 | pending |
| E015 | d | pending | 0 | pending |
| E016 | d | pending | 0 | pending |
| E017 | d | pending | 0 | pending |
| E018 | d | pending | 0 | pending |
| E019 | d | pending | 0 | pending |
| E020 | d | pending | 0 | pending |
| E021 | d | pending | 0 | pending |
| E022 | d | pending | 0 | pending |
| E023 | d | pending | 0 | pending |
| E024 | d | pending | 0 | pending |
| E025 | d | pending | 0 | pending |
| E026 | d | pending | 0 | pending |
| E027 | d | pending | 0 | pending |
| E028 | d | pending | 0 | pending |
| E029 | d | pending | 0 | pending |
| E030 | d | pending | 0 | pending |
| E031 | d | pending | 0 | pending |
| E032 | d | pending | 0 | pending |
| E033 | d | pending | 0 | pending |
| E034 | d | pending | 0 | pending |
| E035 | d | pending | 0 | pending |
| E036 | d | pending | 0 | pending |
| E037 | d | pending | 0 | pending |
| E038 | d | pending | 0 | pending |
| E039 | d | pending | 0 | pending |
| E040 | d | pending | 0 | pending |
| E041 | d | pending | 0 | pending |
| E042 | d | pending | 0 | pending |
| E043 | d | pending | 0 | pending |
| E044 | d | pending | 0 | pending |
| E045 | d | pending | 0 | pending |
| E046 | d | pending | 0 | pending |
| E047 | d | pending | 0 | pending |
| E048 | d | pending | 0 | pending |
| E049 | d | pending | 0 | pending |
| E050 | d | pending | 0 | pending |

EDGE ordered isolated merged total: `pending`
EDGE `bucket_frame` merged total: `pending`

### 1.3 PROF

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| P001 | d | pending | 0 | pending |
| P002 | r | pending | pending | pending |
| P003 | r | pending | pending | pending |
| P004 | r | pending | pending | pending |
| P005 | r | pending | pending | pending |
| P006 | d | pending | 0 | pending |
| P007 | r | pending | pending | pending |
| P008 | d | pending | 0 | pending |
| P009 | r | pending | pending | pending |
| P010 | r | pending | pending | pending |
| P011 | d | pending | 0 | pending |
| P012 | r | pending | pending | pending |
| P013 | d | pending | 0 | pending |
| P014 | d | pending | 0 | pending |
| P015 | r | pending | pending | pending |
| P016 | r | pending | pending | pending |
| P017 | r | pending | pending | pending |
| P018 | r | pending | pending | pending |
| P019 | d | pending | 0 | pending |
| P020 | d | pending | 0 | pending |
| P021 | d | pending | 0 | pending |
| P022 | d | pending | 0 | pending |
| P023 | d | pending | 0 | pending |
| P024 | d | pending | 0 | pending |
| P025 | d | pending | 0 | pending |
| P026 | d | pending | 0 | pending |
| P027 | d | pending | 0 | pending |
| P028 | d | pending | 0 | pending |
| P029 | d | pending | 0 | pending |
| P030 | d | pending | 0 | pending |
| P031 | r | pending | pending | pending |
| P032 | r | pending | pending | pending |
| P033 | r | pending | pending | pending |
| P034 | r | pending | pending | pending |
| P035 | r | pending | pending | pending |
| P036 | r | pending | pending | pending |
| P037 | r | pending | pending | pending |
| P038 | r | pending | pending | pending |
| P039 | r | pending | pending | pending |
| P040 | r | pending | pending | pending |

PROF ordered isolated merged total: `pending`
PROF `bucket_frame` merged total: `pending`

### 1.4 ERROR

| case_id | type (d/r) | coverage_by_this_case | executed random txn | coverage_incr_per_txn |
|---------|-----------|----------------------|---------------------|-----------------------|
| X001 | d | pending | 0 | pending |
| X002 | d | pending | 0 | pending |
| X003 | d | pending | 0 | pending |
| X004 | d | pending | 0 | pending |
| X005 | d | pending | 0 | pending |
| X006 | d | pending | 0 | pending |
| X007 | d | pending | 0 | pending |
| X008 | d | pending | 0 | pending |
| X009 | d | pending | 0 | pending |
| X010 | d | pending | 0 | pending |
| X011 | d | pending | 0 | pending |
| X012 | d | pending | 0 | pending |
| X013 | d | pending | 0 | pending |
| X014 | d | pending | 0 | pending |
| X015 | d | pending | 0 | pending |
| X016 | d | pending | 0 | pending |
| X017 | d | pending | 0 | pending |
| X018 | d | pending | 0 | pending |
| X019 | d | pending | 0 | pending |
| X020 | d | pending | 0 | pending |
| X021 | d | pending | 0 | pending |
| X022 | d | pending | 0 | pending |
| X023 | d | pending | 0 | pending |
| X024 | d | pending | 0 | pending |
| X025 | d | pending | 0 | pending |
| X026 | d | pending | 0 | pending |
| X027 | d | pending | 0 | pending |
| X028 | d | pending | 0 | pending |
| X029 | d | pending | 0 | pending |
| X030 | d | pending | 0 | pending |
| X031 | d | pending | 0 | pending |
| X032 | d | pending | 0 | pending |
| X033 | d | pending | 0 | pending |
| X034 | d | pending | 0 | pending |
| X035 | d | pending | 0 | pending |
| X036 | d | pending | 0 | pending |
| X037 | d | pending | 0 | pending |
| X038 | d | pending | 0 | pending |
| X039 | d | pending | 0 | pending |
| X040 | d | pending | 0 | pending |
| X041 | d | pending | 0 | pending |
| X042 | d | pending | 0 | pending |
| X043 | d | pending | 0 | pending |
| X044 | d | pending | 0 | pending |
| X045 | d | pending | 0 | pending |
| X046 | d | pending | 0 | pending |
| X047 | d | pending | 0 | pending |
| X048 | d | pending | 0 | pending |
| X049 | d | pending | 0 | pending |
| X050 | d | pending | 0 | pending |

ERROR ordered isolated merged total: `pending`
ERROR `bucket_frame` merged total: `pending`

---

## 2. `all_buckets_frame` Total

`all_buckets_frame` merged total: `pending`

---

## 3. Sign-off Totals

| Category | Target | Isolated merged | bucket_frame merged | all_buckets_frame |
|----------|--------|-----------------|---------------------|-------------------|
| Statement | ≥ 95% | pending | pending | pending |
| Branch | ≥ 90% | pending | pending | pending |
| Condition | ≥ 85% | pending | pending | pending |
| Expression | ≥ 85% | pending | pending | pending |
| FSM state | 100% | pending | pending | pending |
| FSM transition | ≥ 95% | pending | pending | pending |
| Toggle | ≥ 80% | pending | pending | pending |
| Functional cross (per `DV_CROSS.md`) | ≥ 95% | pending | pending | pending |

Sign-off is gated on every cell in this table being ≥ target or
explicitly waived in `DV_REPORT.md` with a reason and a remediation
plan.

---

## 4. Per-build Coverage Snapshots

For each `BUILD=<tag>` in `DV_HARNESS.md §10`, the merged regression
coverage is recorded here as the build is closed. Each build carries
the same row schema as §1, plus a `(N_LANE, N_ENGINE,
ROUTING_TOPOLOGY, SCORE_WINDOW_W, SYNC_PATTERN, INSTANCE_ID)`
header.

### 4.1 `primary` build — `(N_LANE=12, N_ENGINE=1, full_xbar, 10, K28.5, 0)`

`pending`

### 4.2 `legacy` build — `(N_LANE=9, N_ENGINE=9, full_xbar, 10, K28.5, 0)`

`pending`

### 4.3 `topo_butterfly_h` build — `(N_LANE=12, N_ENGINE=4, butterfly_half, 10, K28.5, 0)`

`pending`

### 4.4 `topo_butterfly_q` build — `(N_LANE=12, N_ENGINE=4, butterfly_quarter, 10, K28.5, 0)`

`pending`

### 4.5 `topo_nearest_k` build — `(N_LANE=12, N_ENGINE=4, nearest_k, 10, K28.5, 0)`

`pending`

### 4.6 `score_w6` build — `(N_LANE=4, N_ENGINE=2, full_xbar, 6, K28.5, 0)`

`pending`

### 4.7 `score_w16` build — `(N_LANE=4, N_ENGINE=2, full_xbar, 16, K28.5, 0)`

`pending`

### 4.8 `sync_k280` build — `(N_LANE=4, N_ENGINE=1, full_xbar, 10, K28.0, 0)`

`pending`

### 4.9 `sync_k237` build — `(N_LANE=4, N_ENGINE=1, full_xbar, 10, K23.7, 0)`

`pending`

### 4.10 `lane1` build — `(N_LANE=1, N_ENGINE=1, full_xbar, 10, K28.5, 0)`

`pending`

### 4.11 `lane4` build — `(N_LANE=4, N_ENGINE=2, full_xbar, 10, K28.5, 0)`

`pending`
