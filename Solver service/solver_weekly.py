from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any

from ortools.sat.python import cp_model

from solver import (
    RESP, CASH, FLOOR, TRAINED_CASH_FLOOR, FULLTIME_OTHERS,
    MARCO, OTHERS, PEOPLE, TARGET, CENTRAL,
    build_responsibles, monday_of, phase_for, shift_pool,
    _absence_on, _wanted_shift, _unavailable,
    minutes, at, is_split, side,
)


def solve_three_weeks_weekly(payload: dict[str, Any]) -> dict[str, Any]:
    start = monday_of(str(payload["startDate"]))
    days = [start + timedelta(days=i) for i in range(21)]
    absences = list(payload.get("absences") or [])
    requests = list(payload.get("requests") or [])
    swaps = payload.get("rotationSwaps") or {}
    max_seconds = float(payload.get("maxSolveSeconds") or 25)

    resp_schedule, sundays = build_responsibles(days, absences, requests, swaps)
    full: dict[str, list[str]] = {n: list(resp_schedule[n]) for n in RESP}
    for n in OTHERS:
        full[n] = []

    carry_streak = {n: 0 for n in OTHERS}
    weeks: list[dict[str, Any]] = []
    solver_meta: list[dict[str, Any]] = []

    for w in range(3):
        base_i = w * 7
        week_days = days[base_i:base_i + 7]
        absent_names = {
            str(a.get("employee_name"))
            for a in absences
            if a.get("employee_name") and any(
                _absence_on([a], str(a.get("employee_name")), d) for d in week_days
            )
        }
        ferie_names = {
            str(a.get("employee_name"))
            for a in absences
            if a.get("employee_name")
            and str(a.get("absence_type") or "").upper() == "FERIE"
            and any(_absence_on([a], str(a.get("employee_name")), d) for d in week_days)
        }
        ferie_count = len(ferie_names)

        model = cp_model.CpModel()
        x: dict[tuple[str, int, str], cp_model.IntVar] = {}
        opts_by: dict[tuple[str, int], list[str]] = {}
        work: dict[tuple[str, int], cp_model.IntVar] = {}
        splitv: dict[tuple[str, int], cp_model.IntVar] = {}
        morn: dict[tuple[str, int], cp_model.IntVar] = {}
        aft: dict[tuple[str, int], cp_model.IntVar] = {}

        for n in OTHERS:
            for local, d in enumerate(week_days):
                a = _absence_on(absences, n, d)
                wanted = _wanted_shift(requests, n, d)
                if a:
                    opts = [str(a.get("absence_type") or "FERIE").upper()]
                elif wanted:
                    opts = [wanted]
                elif local == 6:
                    opts = ["08:00-13:00"] if n in sundays[w]["all"] else ["RIPOSO"]
                else:
                    opts = shift_pool(n, ferie_count >= 1)

                opts = list(dict.fromkeys(opts))
                opts_by[(n, local)] = opts
                here: list[cp_model.IntVar] = []
                for j, s in enumerate(opts):
                    v = model.NewBoolVar(f"x__{n}__{local}__{j}")
                    x[(n, local, s)] = v
                    here.append(v)
                model.Add(sum(here) == 1)

                work[(n, local)] = model.NewBoolVar(f"work__{n}__{local}")
                model.Add(work[(n, local)] == sum(x[(n, local, s)] for s in opts if minutes(s) > 0))
                splitv[(n, local)] = model.NewBoolVar(f"split__{n}__{local}")
                model.Add(splitv[(n, local)] == sum(x[(n, local, s)] for s in opts if is_split(s)))
                morn[(n, local)] = model.NewBoolVar(f"m__{n}__{local}")
                model.Add(morn[(n, local)] == sum(x[(n, local, s)] for s in opts if side(s) < 0))
                aft[(n, local)] = model.NewBoolVar(f"a__{n}__{local}")
                model.Add(aft[(n, local)] == sum(x[(n, local, s)] for s in opts if side(s) > 0))

        def resp_count(local: int, t: str) -> int:
            gi = base_i + local
            return sum(1 for n in RESP if at(resp_schedule[n][gi], t))

        for local, d in enumerate(week_days[:6]):
            def total_at(t: str, include_marco: bool = True):
                names = OTHERS if include_marco else [n for n in OTHERS if n != MARCO]
                return resp_count(local, t) + sum(
                    x[(n, local, s)]
                    for n in names
                    for s in opts_by[(n, local)]
                    if at(s, t)
                )

            model.Add(total_at("07:00") >= 4)
            model.Add(total_at("10:00") >= 5)
            model.Add(total_at("13:30") >= 5)
            model.Add(total_at("16:30") >= 5)

            model.Add(sum(
                x[(n, local, s)]
                for n in FLOOR
                for s in opts_by[(n, local)]
                if at(s, "06:45")
            ) >= 1)
            if resp_count(local, "06:45") < 1:
                raise ValueError(f"Manca il Responsabile prima delle 07:00 il {d.isoformat()}")

            for t in ("17:00", "18:00", "19:00", "20:00", "20:29"):
                model.Add(total_at(t, include_marco=False) == 4)

            cash_absent_today = any(_unavailable(absences, requests, n, d) for n in CASH)
            cash_qualified = CASH + (TRAINED_CASH_FLOOR if cash_absent_today else [])
            for t in ("07:00", "13:30", "20:29"):
                model.Add(sum(
                    x[(n, local, s)]
                    for n in cash_qualified
                    for s in opts_by[(n, local)]
                    if at(s, t)
                ) >= 1)

        max_split = model.NewIntVar(0, 2, f"max_split_w{w}")
        ot_vars: list[cp_model.IntVar] = []
        total_splits: list[cp_model.LinearExpr] = []
        balance_terms: list[cp_model.IntVar] = []
        repeat_terms: list[cp_model.IntVar] = []

        for n in OTHERS:
            weekly_minutes = sum(
                minutes(s) * x[(n, local, s)]
                for local in range(7)
                for s in opts_by[(n, local)]
            )
            weekly_splits = sum(splitv[(n, local)] for local in range(7))
            total_splits.append(weekly_splits)
            absent = n in absent_names

            if not absent:
                if n in FULLTIME_OTHERS:
                    model.Add(sum(work[(n, local)] for local in range(6)) == 5)
                elif n == "Giada":
                    model.Add(sum(work[(n, local)] for local in range(6)) <= 5)
                elif n == MARCO:
                    model.Add(sum(work[(n, local)] for local in range(7)) == 4)

            if absent:
                model.Add(weekly_minutes <= TARGET[n])
            elif ferie_count < 2:
                model.Add(weekly_minutes == TARGET[n])
            else:
                model.Add(weekly_minutes >= TARGET[n])
                model.Add(weekly_minutes <= TARGET[n] + 3 * 60)

            if n == MARCO:
                model.Add(weekly_splits == 0)
            elif ferie_count == 0:
                model.Add(weekly_splits == 0)
            else:
                model.Add(weekly_splits <= 2)
                model.Add(max_split >= weekly_splits)

            ot = model.NewIntVar(0, 3 * 60 if ferie_count >= 2 else 0, f"ot__{n}__w{w}")
            if absent or ferie_count < 2:
                model.Add(ot == 0)
            else:
                model.Add(ot == weekly_minutes - TARGET[n])
            ot_vars.append(ot)

            m = sum(morn[(n, local)] for local in range(6))
            p = sum(aft[(n, local)] for local in range(6))
            diff = model.NewIntVar(0, 6, f"bal__{n}__w{w}")
            model.AddAbsEquality(diff, m - p)
            balance_terms.append(diff)

            for local in range(5):
                mm = model.NewBoolVar(f"mm__{n}__{local}")
                pp = model.NewBoolVar(f"pp__{n}__{local}")
                model.Add(mm <= morn[(n, local)])
                model.Add(mm <= morn[(n, local + 1)])
                model.Add(mm >= morn[(n, local)] + morn[(n, local + 1)] - 1)
                model.Add(pp <= aft[(n, local)])
                model.Add(pp <= aft[(n, local + 1)])
                model.Add(pp >= aft[(n, local)] + aft[(n, local + 1)] - 1)
                repeat_terms.extend([mm, pp])

            model.Add(sum(work[(n, local)] for local in range(7)) <= 6)
            k = carry_streak[n]
            if k > 0:
                limit = 7 - k
                if 1 <= limit <= 6:
                    model.Add(sum(work[(n, local)] for local in range(limit)) <= limit - 1)
                elif limit <= 0:
                    model.Add(work[(n, 0)] == 0)

        cash_splits = sum(splitv[(n, local)] for n in CASH for local in range(7))
        floor_splits = sum(splitv[(n, local)] for n in FLOOR for local in range(7))
        group_diff = model.NewIntVar(0, 12, f"split_group_diff_w{w}")
        model.AddAbsEquality(group_diff, cash_splits - floor_splits)

        model.Minimize(
            1_000_000 * sum(ot_vars)
            + 10_000 * sum(total_splits)
            + 1_000 * max_split
            + 100 * group_diff
            + 10 * sum(balance_terms)
            + sum(repeat_terms)
        )

        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = max(10.0, max_seconds / 3.0)
        solver.parameters.num_search_workers = 4
        solver.parameters.random_seed = 17 + w
        status = solver.Solve(model)
        if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            raise ValueError(
                f"Nessuna soluzione valida trovata per la settimana {week_days[0].isoformat()} "
                f"(stato {solver.StatusName(status)})"
            )

        ws: dict[str, list[str]] = {n: [resp_schedule[n][base_i + i] for i in range(7)] for n in RESP}
        for n in OTHERS:
            vals: list[str] = []
            for local in range(7):
                selected = "RIPOSO"
                for s in opts_by[(n, local)]:
                    if solver.Value(x[(n, local, s)]):
                        selected = s
                        break
                vals.append(selected)
            ws[n] = vals
            full[n].extend(vals)

            streak = carry_streak[n]
            for s in vals:
                streak = streak + 1 if minutes(s) > 0 else 0
                if streak > 6:
                    raise ValueError(f"Riposo oltre 6 giorni consecutivi per {n}")
            carry_streak[n] = streak

        for n in FULLTIME_OTHERS:
            if n in absent_names:
                continue
            worked_weekdays = sum(minutes(ws[n][local]) > 0 for local in range(6))
            if worked_weekdays != 5:
                raise ValueError(f"Audit: {n} deve lavorare esattamente 5 giorni lun-sab, trovati {worked_weekdays}")
            if minutes(ws[n][6]) == 0 and sum(ws[n][local] == "RIPOSO" for local in range(6)) != 1:
                raise ValueError(f"Audit: {n} riposa domenica ma non ha esattamente 1 RIPOSO lun-sab")

        if MARCO not in absent_names:
            marco_work = sum(minutes(s) > 0 for s in ws[MARCO])
            marco_minutes = sum(minutes(s) for s in ws[MARCO])
            if marco_work != 4 or marco_minutes != 16 * 60 or any(is_split(s) for s in ws[MARCO]):
                raise ValueError("Audit: Marco deve fare 4 turni da 4h, 16h totali, senza spezzati")

        wh = {n: round(sum(minutes(s) for s in ws[n]) / 60, 2) for n in PEOPLE}
        splits = {n: sum(is_split(s) for s in ws[n]) for n in PEOPLE}
        balance = {
            n: {"morning": sum(side(s) < 0 for s in ws[n]), "afternoon": sum(side(s) > 0 for s in ws[n])}
            for n in CASH + FLOOR
        }
        max_ot_hours = max([0.0] + [max(0.0, wh[n] - TARGET[n] / 60) for n in OTHERS])
        weeks.append({
            "label": f"{week_days[0].isoformat()} – {week_days[-1].isoformat()}",
            "dates": [d.isoformat() for d in week_days],
            "schedule": ws,
            "meta": {
                "phase": phase_for(week_days[0]),
                "absenceCount": len(absent_names),
                "ferieCount": ferie_count,
                "weekHours": wh,
                "splitByPerson": splits,
                "splitCount": sum(splits.values()),
                "maxOT": round(max_ot_hours, 2),
                "balance": balance,
                "sunday": sundays[w],
            },
        })
        solver_meta.append({
            "week": w + 1,
            "status": solver.StatusName(status),
            "wallTimeSeconds": round(solver.WallTime(), 3),
            "objective": round(solver.ObjectiveValue(), 3),
        })

    return {
        "version": "external-ortools-weekly-3-rest-rule",
        "startDate": days[0].isoformat(),
        "endDate": days[-1].isoformat(),
        "generatedAt": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "responsibleCentral": CENTRAL,
        "rules": {
            "weekdayRest": "full-time presenti: esattamente 5 giorni lavorati lun-sab",
            "marco": "16h, 4x4h, zero spezzati",
            "maxSplitsPerPerson": 2,
            "normalOvertime": 0,
            "paoloCashSubstitute": False,
        },
        "weeks": weeks,
        "solver": {"mode": "weekly-sequential-rest-rule", "weeks": solver_meta},
    }
