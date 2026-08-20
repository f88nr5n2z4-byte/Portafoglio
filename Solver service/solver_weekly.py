from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any

from ortools.sat.python import cp_model

from solver import (
    RESP, CASH, FLOOR, MARCO, OTHERS, PEOPLE, TARGET, CENTRAL,
    build_responsibles, monday_of, phase_for, shift_pool,
    _absence_on, _wanted_shift, minutes, at, is_split, side,
)


def solve_three_weeks_weekly(payload: dict[str, Any]) -> dict[str, Any]:
    start = monday_of(str(payload["startDate"]))
    days = [start + timedelta(days=i) for i in range(21)]
    absences = list(payload.get("absences") or [])
    requests = list(payload.get("requests") or [])
    swaps = payload.get("rotationSwaps") or {}
    max_seconds = float(payload.get("maxSolveSeconds") or 20)

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
            if a.get("employee_name") and any(_absence_on([a], str(a.get("employee_name")), d) for d in week_days)
        }
        ac = len(absent_names)
        model = cp_model.CpModel()
        x: dict[tuple[str, int, str], cp_model.IntVar] = {}
        opts_by: dict[tuple[str, int], list[str]] = {}
        work: dict[tuple[str, int], cp_model.IntVar] = {}
        splitv: dict[tuple[str, int], cp_model.IntVar] = {}
        morn: dict[tuple[str, int], cp_model.IntVar] = {}
        aft: dict[tuple[str, int], cp_model.IntVar] = {}

        for n in OTHERS:
            for local, d in enumerate(week_days):
                gi = base_i + local
                a = _absence_on(absences, n, d)
                wanted = _wanted_shift(requests, n, d)
                if a:
                    opts = [str(a.get("absence_type") or "FERIE").upper()]
                elif wanted:
                    opts = [wanted]
                elif local == 6:
                    opts = ["08:00-13:00"] if n in sundays[w]["all"] else ["RIPOSO"]
                else:
                    opts = shift_pool(n, ac >= 2)
                    if ac == 0:
                        opts = [s for s in opts if not is_split(s)]
                    if ac == 1 and n in {"Giada", MARCO}:
                        opts = [s for s in opts if not is_split(s)]
                opts = list(dict.fromkeys(opts))
                opts_by[(n, local)] = opts
                here = []
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

        for local in range(6):
            cash_absent = any(n in CASH for n in absent_names)

            def total_at(t: str):
                return resp_count(local, t) + sum(
                    x[(n, local, s)]
                    for n in OTHERS for s in opts_by[(n, local)] if at(s, t)
                )

            model.Add(total_at("07:00") == 4)
            model.Add(total_at("10:00") >= 5)
            model.Add(total_at("13:30") >= 5)
            model.Add(total_at("16:30") >= 5)
            model.Add(total_at("20:29") == 4)

            for t in ("17:00", "19:59"):
                model.Add(
                    resp_count(local, t)
                    + sum(x[(n, local, s)] for n in OTHERS if n != MARCO for s in opts_by[(n, local)] if at(s, t))
                    == 4
                )

            model.Add(sum(x[(n, local, s)] for n in FLOOR for s in opts_by[(n, local)] if at(s, "06:45")) >= 1)
            cash_qualified = CASH + (FLOOR if cash_absent else [])
            for t in ("07:00", "13:30", "20:29"):
                model.Add(sum(x[(n, local, s)] for n in cash_qualified for s in opts_by[(n, local)] if at(s, t)) >= 1)

        max_split = model.NewIntVar(0, 7, f"max_split_w{w}")
        max_ot = model.NewIntVar(0, 4 * 60 if ac >= 2 else 0, f"max_ot_w{w}")
        ot_vars = []
        total_splits = []
        balance_terms = []
        repeat_terms = []

        for n in OTHERS:
            weekly_minutes = sum(
                minutes(s) * x[(n, local, s)]
                for local in range(7) for s in opts_by[(n, local)]
            )
            weekly_splits = sum(splitv[(n, local)] for local in range(7))
            total_splits.append(weekly_splits)
            absent = n in absent_names

            if absent:
                model.Add(weekly_minutes <= TARGET[n])
            elif ac == 0:
                model.Add(weekly_minutes == TARGET[n])
                model.Add(weekly_splits == 0)
            elif ac == 1:
                model.Add(weekly_minutes == TARGET[n])
                model.Add(weekly_splits <= (0 if n in {"Giada", MARCO} else 1))
            else:
                model.Add(weekly_minutes >= TARGET[n])
                model.Add(weekly_minutes <= TARGET[n] + 4 * 60)
                model.Add(weekly_splits <= 2)

            model.Add(max_split >= weekly_splits)
            ot = model.NewIntVar(0, 4 * 60 if ac >= 2 else 0, f"ot__{n}__w{w}")
            if absent or ac < 2:
                model.Add(ot == 0)
            else:
                model.Add(ot == weekly_minutes - TARGET[n])
            model.Add(max_ot >= ot)
            ot_vars.append(ot)

            m = sum(morn[(n, local)] for local in range(7))
            p = sum(aft[(n, local)] for local in range(7))
            diff = model.NewIntVar(0, 7, f"bal__{n}__w{w}")
            model.AddAbsEquality(diff, m - p)
            balance_terms.append(diff)

            for local in range(6):
                mm = model.NewBoolVar(f"mm__{n}__{local}")
                pp = model.NewBoolVar(f"pp__{n}__{local}")
                model.Add(mm <= morn[(n, local)])
                model.Add(mm <= morn[(n, local + 1)])
                model.Add(mm >= morn[(n, local)] + morn[(n, local + 1)] - 1)
                model.Add(pp <= aft[(n, local)])
                model.Add(pp <= aft[(n, local + 1)])
                model.Add(pp >= aft[(n, local)] + aft[(n, local + 1)] - 1)
                repeat_terms.extend([mm, pp])

            # Within-week maximum six consecutive working days.
            model.Add(sum(work[(n, local)] for local in range(7)) <= 6)
            # Carry the previous week's ending streak into this week.
            k = carry_streak[n]
            if k > 0:
                limit = 7 - k
                if 1 <= limit <= 6:
                    model.Add(sum(work[(n, local)] for local in range(limit)) <= limit - 1)
                elif limit <= 0:
                    model.Add(work[(n, 0)] == 0)

        model.Minimize(
            1_000_000 * max_ot
            + 10_000 * sum(ot_vars)
            + 1_000 * max_split
            + 100 * sum(total_splits)
            + 10 * sum(balance_terms)
            + sum(repeat_terms)
        )

        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = max(8.0, max_seconds / 3.0)
        solver.parameters.num_search_workers = 4
        solver.parameters.random_seed = 17 + w
        status = solver.Solve(model)
        if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            raise ValueError(f"Nessuna soluzione valida trovata per la settimana {week_days[0].isoformat()} (stato {solver.StatusName(status)})")

        ws: dict[str, list[str]] = {n: [resp_schedule[n][base_i + i] for i in range(7)] for n in RESP}
        for n in OTHERS:
            vals = []
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
                "absenceCount": ac,
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
        "version": "external-ortools-weekly-2",
        "startDate": days[0].isoformat(),
        "endDate": days[-1].isoformat(),
        "generatedAt": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "responsibleCentral": CENTRAL,
        "weeks": weeks,
        "solver": {"mode": "weekly-sequential", "weeks": solver_meta},
    }
