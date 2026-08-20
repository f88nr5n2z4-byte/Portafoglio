from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any

from ortools.sat.python import cp_model

RESP = ["Umberto", "Fabio", "Emanuele"]
CASH = ["Stefania B", "Stefania F", "Romina", "Giada"]
FLOOR = ["Giuliano", "Manuel", "Daniele", "Paolo"]
TRAINED_CASH_FLOOR = ["Giuliano", "Manuel", "Daniele"]
MARCO = "Marco"
OTHERS = CASH + FLOOR + [MARCO]
PEOPLE = RESP + OTHERS
FULLTIME_OTHERS = [n for n in CASH + FLOOR if n != "Giada"]
TARGET = {**{n: 40 * 60 for n in PEOPLE}, "Giada": 30 * 60, MARCO: 16 * 60}

OPEN = "06:30-13:30"
CLOSE = "13:30-20:30"
CENTRAL = "10:00-17:00"
RESP_SPLIT = "06:30-13:30 / 17:00-20:30"
OFF = {"RIPOSO", "FERIE", "PERMESSO", "MALATTIA", "MATERNITÀ", "—"}
ANCHOR = date(2026, 8, 24)
FLOOR_PAIRS = [
    ("Giuliano", "Manuel"),
    ("Daniele", "Paolo"),
    ("Giuliano", "Daniele"),
    ("Manuel", "Paolo"),
    ("Giuliano", "Paolo"),
    ("Manuel", "Daniele"),
]

CASH_SHIFTS = [
    "RIPOSO", "07:00-12:00", "07:00-12:30", "07:00-13:00", "07:00-13:30",
    "07:00-14:00", "07:00-14:30", "07:00-15:00", "09:00-15:00", "09:00-16:00",
    "10:00-15:00", "10:00-16:00", "10:00-17:00", "10:00-18:00", "11:00-18:00",
    "11:00-19:00", "11:00-20:00", "11:30-20:30", "12:00-20:30", "12:30-20:30",
    "13:00-20:30", "13:30-20:30", "14:00-20:30", "14:30-20:30", "15:00-20:30",
    "16:30-20:30", "17:00-20:30",
    "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
]
FLOOR_SHIFTS = [
    "RIPOSO", "06:30-11:30", "06:30-12:00", "06:30-12:30", "06:30-13:00",
    "06:30-13:30", "06:30-14:00", "06:30-14:30", "07:00-13:00", "07:00-14:00",
    "09:00-15:00", "09:00-16:00", "10:00-15:00", "10:00-16:00", "10:00-17:00",
    "10:00-18:00", "11:00-18:00", "11:00-19:00", "11:00-20:00", "11:30-20:30",
    "12:00-20:30", "12:30-20:30", "13:00-20:30", "13:30-20:30", "14:00-20:30",
    "14:30-20:30", "15:00-20:30", "16:30-20:30", "17:00-20:30",
    "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
    "06:30-13:30 / 17:00-20:00", "06:30-13:30 / 17:00-20:30",
]
GIADA_SHIFTS = [
    "RIPOSO", "07:00-12:00", "07:00-12:30", "07:00-13:00", "09:00-14:00",
    "09:00-14:30", "09:00-15:00", "10:00-15:00", "10:00-15:30", "10:00-16:00",
    "11:00-16:00", "12:00-17:00", "13:00-18:00", "14:00-19:00", "14:30-19:30",
    "15:00-20:30", "15:30-20:30",
    "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
]
MARCO_SHIFTS = ["RIPOSO", "16:00-20:00", "16:30-20:30"]


def _hm(t: str) -> int:
    h, m = map(int, t.split(":"))
    return h * 60 + m


def spans(shift: str) -> list[tuple[int, int]]:
    if not shift or shift.strip().upper() in OFF:
        return []
    out: list[tuple[int, int]] = []
    for part in shift.split("/"):
        a, b = [x.strip() for x in part.split("-")]
        out.append((_hm(a), _hm(b)))
    return out


def minutes(shift: str) -> int:
    return sum(b - a for a, b in spans(shift))


def at(shift: str, t: str) -> bool:
    q = _hm(t)
    return any(a <= q < b for a, b in spans(shift))


def is_split(shift: str) -> bool:
    return len(spans(shift)) > 1


def side(shift: str) -> int:
    ss = spans(shift)
    if len(ss) != 1:
        return 0
    a, b = ss[0]
    if a <= 10 * 60 and b <= 17 * 60:
        return -1
    if a >= 12 * 60:
        return 1
    return 0


def monday_of(raw: str) -> date:
    d = date.fromisoformat(raw)
    return d - timedelta(days=d.weekday())


def phase_for(monday: date) -> int:
    return (monday - ANCHOR).days // 7


def resp_nominal(name: str, weekday: int) -> str:
    k = (weekday + RESP.index(name)) % 3
    return OPEN if k == 0 else CLOSE if k == 1 else CENTRAL


def _absence_on(absences: list[dict[str, Any]], name: str, day: date) -> dict[str, Any] | None:
    s = day.isoformat()
    for a in absences:
        if a.get("employee_name") == name and a.get("date_from", "9999") <= s <= a.get("date_to", "0000"):
            return a
    return None


def _requests_on(requests: list[dict[str, Any]], name: str, day: date) -> list[dict[str, Any]]:
    s = day.isoformat()
    return [r for r in requests if r.get("employee_name") == name and r.get("request_date") == s and r.get("status") == "ACCETTATA"]


def _off_requested(requests: list[dict[str, Any]], name: str, day: date) -> bool:
    return any(r.get("kind") in {"RIPOSO", "PERMESSO", "FERIE"} for r in _requests_on(requests, name, day))


def _wanted_shift(requests: list[dict[str, Any]], name: str, day: date) -> str | None:
    vals: list[str] = []
    for r in _requests_on(requests, name, day):
        if r.get("kind") == "RIPOSO":
            vals.append("RIPOSO")
        elif r.get("kind") == "TURNO" and r.get("wanted_shift"):
            vals.append(str(r["wanted_shift"]))
    vals = list(dict.fromkeys(vals))
    if len(vals) > 1:
        raise ValueError(f"Richieste incompatibili per {name} il {day.isoformat()}")
    return vals[0] if vals else None


def _unavailable(absences: list[dict[str, Any]], requests: list[dict[str, Any]], name: str, day: date) -> bool:
    return _absence_on(absences, name, day) is not None or _off_requested(requests, name, day)


def _mapped(name: str, group: str, swaps: dict[str, Any]) -> str:
    g = swaps.get(group) if isinstance(swaps, dict) else None
    return str(g.get(name, name)) if isinstance(g, dict) else name


def _overlaps_week(a: dict[str, Any], lo: date, hi: date) -> bool:
    return str(a.get("date_from", "9999")) <= hi.isoformat() and str(a.get("date_to", "0000")) >= lo.isoformat()


def sunday_people(monday: date, absences: list[dict[str, Any]], requests: list[dict[str, Any]], swaps: dict[str, Any]) -> dict[str, Any]:
    phase = phase_for(monday)
    sunday = monday + timedelta(days=6)
    nominal_resp = _mapped(RESP[phase % 3], "resp", swaps)
    nominal_cash = _mapped(CASH[phase % 4], "cash", swaps)
    nominal_floor = [_mapped(x, "floor", swaps) for x in FLOOR_PAIRS[phase % 6]]

    def pick(group: list[str], preferred: str, used: set[str]) -> str:
        if preferred in group and preferred not in used and not _unavailable(absences, requests, preferred, sunday):
            return preferred
        idx = group.index(preferred) if preferred in group else 0
        order = group[idx + 1 :] + group[: idx + 1]
        for n in order:
            if n not in used and not _unavailable(absences, requests, n, sunday):
                return n
        raise ValueError(f"Nessun sostituto disponibile domenica per {preferred}")

    rr = pick(RESP, nominal_resp, set())
    cc = pick(CASH, nominal_cash, set())
    used: set[str] = set()
    ff: list[str] = []
    for p in nominal_floor:
        x = pick(FLOOR, p, used)
        used.add(x)
        ff.append(x)
    return {"resp": rr, "cash": cc, "floor": ff, "all": [rr, cc, *ff]}


def build_responsibles(days: list[date], absences: list[dict[str, Any]], requests: list[dict[str, Any]], swaps: dict[str, Any]) -> tuple[dict[str, list[str]], list[dict[str, Any]]]:
    out = {n: ["RIPOSO"] * len(days) for n in RESP}
    sunday_meta: list[dict[str, Any]] = []
    for w in range(3):
        base = days[w * 7]
        sun = sunday_people(base, absences, requests, swaps)
        sunday_meta.append(sun)
        rest_by_resp: dict[str, int | None] = {n: None for n in RESP}
        used_local_days: set[int] = set()
        for n in RESP:
            already_off = any(_unavailable(absences, requests, n, days[w * 7 + local]) for local in range(6))
            if already_off:
                continue
            candidates = [local for local in range(6) if resp_nominal(n, local) == CENTRAL and local not in used_local_days and not _unavailable(absences, requests, n, days[w * 7 + local])]
            if not candidates:
                candidates = [local for local in range(6) if local not in used_local_days and not _unavailable(absences, requests, n, days[w * 7 + local])]
            if candidates:
                chosen = candidates[0]
                rest_by_resp[n] = w * 7 + chosen
                used_local_days.add(chosen)

        for local in range(6):
            gi = w * 7 + local
            d = days[gi]
            for n in RESP:
                a = _absence_on(absences, n, d)
                if a:
                    out[n][gi] = str(a.get("absence_type") or "FERIE").upper()
                elif _off_requested(requests, n, d) or rest_by_resp[n] == gi:
                    out[n][gi] = "RIPOSO"

            available = [n for n in RESP if not _unavailable(absences, requests, n, d) and rest_by_resp[n] != gi]
            if not available:
                raise ValueError(f"Nessun Responsabile disponibile il {d.isoformat()}")
            if len(available) == 1:
                out[available[0]][gi] = RESP_SPLIT
            elif len(available) == 2:
                opener = next((n for n in available if resp_nominal(n, local) == OPEN), None)
                closer = next((n for n in available if resp_nominal(n, local) == CLOSE), None)
                if opener and closer:
                    out[opener][gi], out[closer][gi] = OPEN, CLOSE
                elif opener:
                    other = next(n for n in available if n != opener)
                    out[opener][gi], out[other][gi] = OPEN, CLOSE
                elif closer:
                    other = next(n for n in available if n != closer)
                    out[other][gi], out[closer][gi] = OPEN, CLOSE
                else:
                    out[available[0]][gi], out[available[1]][gi] = OPEN, CLOSE
            else:
                for n in available:
                    out[n][gi] = resp_nominal(n, local)

            for n in RESP:
                wanted = _wanted_shift(requests, n, d)
                if wanted and wanted != "RIPOSO" and out[n][gi] != wanted:
                    raise ValueError(f"Il turno richiesto da {n} il {d.isoformat()} non è compatibile con lo schema Responsabili")

        sun_idx = w * 7 + 6
        sd = days[sun_idx]
        for n in RESP:
            a = _absence_on(absences, n, sd)
            out[n][sun_idx] = str(a.get("absence_type") or "FERIE").upper() if a else ("08:00-13:00" if n == sun["resp"] else "RIPOSO")
    return out, sunday_meta


def shift_pool(name: str, splits_enabled: bool) -> list[str]:
    if name == "Giada":
        pool = GIADA_SHIFTS
    elif name == MARCO:
        return MARCO_SHIFTS
    else:
        pool = CASH_SHIFTS if name in CASH else FLOOR_SHIFTS
    return pool if splits_enabled else [s for s in pool if not is_split(s)]


def solve_three_weeks(payload: dict[str, Any]) -> dict[str, Any]:
    start = monday_of(str(payload["startDate"]))
    days = [start + timedelta(days=i) for i in range(21)]
    absences = list(payload.get("absences") or [])
    requests = list(payload.get("requests") or [])
    swaps = payload.get("rotationSwaps") or {}

    resp_schedule, sundays = build_responsibles(days, absences, requests, swaps)
    model = cp_model.CpModel()

    x: dict[tuple[str, int, str], cp_model.IntVar] = {}
    chosen_shifts: dict[tuple[str, int], list[str]] = {}
    work: dict[tuple[str, int], cp_model.IntVar] = {}
    split_var: dict[tuple[str, int], cp_model.IntVar] = {}
    morning_var: dict[tuple[str, int], cp_model.IntVar] = {}
    afternoon_var: dict[tuple[str, int], cp_model.IntVar] = {}

    absent_names_by_week: list[set[str]] = []
    ferie_names_by_week: list[set[str]] = []
    for w in range(3):
        lo = days[w * 7]
        hi = days[w * 7 + 6]
        absent = {str(a.get("employee_name")) for a in absences if a.get("employee_name") and _overlaps_week(a, lo, hi)}
        ferie = {str(a.get("employee_name")) for a in absences if a.get("employee_name") and str(a.get("absence_type") or "").upper() == "FERIE" and _overlaps_week(a, lo, hi)}
        absent_names_by_week.append(absent)
        ferie_names_by_week.append(ferie)

    for n in OTHERS:
        for di, d in enumerate(days):
            w = di // 7
            sunday = di % 7 == 6
            sun_people = sundays[w]["all"]
            a = _absence_on(absences, n, d)
            wanted = _wanted_shift(requests, n, d)
            if a:
                opts = [str(a.get("absence_type") or "FERIE").upper()]
            elif wanted:
                opts = [wanted]
            elif sunday:
                opts = ["08:00-13:00"] if n in sun_people else ["RIPOSO"]
            else:
                opts = shift_pool(n, splits_enabled=len(ferie_names_by_week[w]) >= 1)
            opts = list(dict.fromkeys(opts))
            chosen_shifts[(n, di)] = opts
            vars_here: list[cp_model.IntVar] = []
            for s in opts:
                v = model.NewBoolVar(f"x__{n}__{di}__{len(vars_here)}")
                x[(n, di, s)] = v
                vars_here.append(v)
            model.Add(sum(vars_here) == 1)
            work[(n, di)] = model.NewBoolVar(f"work__{n}__{di}")
            model.Add(work[(n, di)] == sum(x[(n, di, s)] for s in opts if minutes(s) > 0))
            split_var[(n, di)] = model.NewBoolVar(f"split__{n}__{di}")
            model.Add(split_var[(n, di)] == sum(x[(n, di, s)] for s in opts if is_split(s)))
            morning_var[(n, di)] = model.NewBoolVar(f"morning__{n}__{di}")
            model.Add(morning_var[(n, di)] == sum(x[(n, di, s)] for s in opts if side(s) < 0))
            afternoon_var[(n, di)] = model.NewBoolVar(f"afternoon__{n}__{di}")
            model.Add(afternoon_var[(n, di)] == sum(x[(n, di, s)] for s in opts if side(s) > 0))

    def resp_count(di: int, t: str) -> int:
        return sum(1 for n in RESP if at(resp_schedule[n][di], t))

    for di, d in enumerate(days):
        if di % 7 == 6:
            continue

        def total_at(t: str, include_marco: bool = True):
            names = OTHERS if include_marco else [n for n in OTHERS if n != MARCO]
            return resp_count(di, t) + sum(x[(n, di, s)] for n in names for s in chosen_shifts[(n, di)] if at(s, t))

        model.Add(total_at("07:00") >= 4)
        model.Add(total_at("10:00") >= 5)
        model.Add(total_at("13:30") >= 5)
        model.Add(total_at("16:30") >= 5)
        model.Add(sum(x[(n, di, s)] for n in FLOOR for s in chosen_shifts[(n, di)] if at(s, "06:45")) >= 1)
        if resp_count(di, "06:45") < 1:
            raise ValueError(f"Manca il Responsabile prima delle 07:00 il {d.isoformat()}")

        for t in ("17:00", "18:00", "19:00", "20:00", "20:29"):
            model.Add(total_at(t, include_marco=False) == 4)

        cash_absent_today = any(_unavailable(absences, requests, n, d) for n in CASH)
        cash_qualified = CASH + (TRAINED_CASH_FLOOR if cash_absent_today else [])
        for t in ("07:00", "13:30", "20:29"):
            model.Add(sum(x[(n, di, s)] for n in cash_qualified for s in chosen_shifts[(n, di)] if at(s, t)) >= 1)

    max_split_week_vars: list[cp_model.IntVar] = []
    total_split_terms: list[cp_model.LinearExpr] = []
    total_ot_terms: list[cp_model.IntVar] = []
    split_group_diff_terms: list[cp_model.IntVar] = []
    balance_terms: list[cp_model.IntVar] = []
    repeat_terms: list[cp_model.IntVar] = []

    for w in range(3):
        all_idxs = list(range(w * 7, w * 7 + 7))
        weekday_idxs = list(range(w * 7, w * 7 + 6))
        ferie_count = len(ferie_names_by_week[w])
        max_split = model.NewIntVar(0, 2, f"max_split_w{w}")
        max_split_week_vars.append(max_split)

        for n in OTHERS:
            weekly_minutes = sum(minutes(s) * x[(n, di, s)] for di in all_idxs for s in chosen_shifts[(n, di)])
            weekly_splits = sum(split_var[(n, di)] for di in all_idxs)
            total_split_terms.append(weekly_splits)
            absent_this_week = n in absent_names_by_week[w]

            if not absent_this_week:
                if n in FULLTIME_OTHERS:
                    model.Add(sum(work[(n, di)] for di in weekday_idxs) == 5)
                elif n == "Giada":
                    model.Add(sum(work[(n, di)] for di in weekday_idxs) <= 5)
                elif n == MARCO:
                    model.Add(sum(work[(n, di)] for di in all_idxs) == 4)

            if absent_this_week:
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
            if absent_this_week or ferie_count < 2:
                model.Add(ot == 0)
            else:
                model.Add(ot == weekly_minutes - TARGET[n])
            total_ot_terms.append(ot)

            m = sum(morning_var[(n, di)] for di in weekday_idxs)
            p = sum(afternoon_var[(n, di)] for di in weekday_idxs)
            diff = model.NewIntVar(0, 6, f"bal__{n}__w{w}")
            model.AddAbsEquality(diff, m - p)
            balance_terms.append(diff)

            for di in weekday_idxs[:-1]:
                mm = model.NewBoolVar(f"mm__{n}__{di}")
                pp = model.NewBoolVar(f"pp__{n}__{di}")
                model.Add(mm <= morning_var[(n, di)])
                model.Add(mm <= morning_var[(n, di + 1)])
                model.Add(mm >= morning_var[(n, di)] + morning_var[(n, di + 1)] - 1)
                model.Add(pp <= afternoon_var[(n, di)])
                model.Add(pp <= afternoon_var[(n, di + 1)])
                model.Add(pp >= afternoon_var[(n, di)] + afternoon_var[(n, di + 1)] - 1)
                repeat_terms.extend([mm, pp])

        cash_splits = sum(split_var[(n, di)] for n in CASH for di in all_idxs)
        floor_splits = sum(split_var[(n, di)] for n in FLOOR for di in all_idxs)
        gd = model.NewIntVar(0, 12, f"split_group_diff_w{w}")
        model.AddAbsEquality(gd, cash_splits - floor_splits)
        split_group_diff_terms.append(gd)

    for n in OTHERS:
        for start_i in range(0, 15):
            model.Add(sum(work[(n, di)] for di in range(start_i, start_i + 7)) <= 6)

    objective = 1_000_000 * sum(total_ot_terms) + 10_000 * sum(total_split_terms) + 1_000 * sum(max_split_week_vars) + 100 * sum(split_group_diff_terms) + 10 * sum(balance_terms) + sum(repeat_terms)
    model.Minimize(objective)

    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = float(payload.get("maxSolveSeconds") or 25)
    solver.parameters.num_search_workers = 8
    solver.parameters.random_seed = 17
    status = solver.Solve(model)
    if status not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        raise ValueError(f"Nessuna soluzione valida trovata per la settimana {start.isoformat()} (stato {solver.StatusName(status)})")

    schedule: dict[str, list[str]] = {n: list(resp_schedule[n]) for n in RESP}
    for n in OTHERS:
        schedule[n] = []
        for di in range(21):
            selected = "RIPOSO"
            for s in chosen_shifts[(n, di)]:
                if solver.Value(x[(n, di, s)]):
                    selected = s
                    break
            schedule[n].append(selected)

    for w in range(3):
        idxs = list(range(w * 7, w * 7 + 7))
        weekdays = idxs[:6]
        sun = idxs[6]
        for n in FULLTIME_OTHERS:
            if n in absent_names_by_week[w]:
                continue
            worked_weekdays = sum(minutes(schedule[n][di]) > 0 for di in weekdays)
            if worked_weekdays != 5:
                raise ValueError(f"Audit: {n} deve lavorare esattamente 5 giorni lun-sab, trovati {worked_weekdays}")
            if minutes(schedule[n][sun]) == 0 and sum(schedule[n][di] == "RIPOSO" for di in weekdays) != 1:
                raise ValueError(f"Audit: {n} riposa domenica ma non ha esattamente 1 RIPOSO lun-sab")
        if MARCO not in absent_names_by_week[w]:
            marco_work = sum(minutes(schedule[MARCO][di]) > 0 for di in idxs)
            marco_minutes = sum(minutes(schedule[MARCO][di]) for di in idxs)
            if marco_work != 4 or marco_minutes != 16 * 60 or any(is_split(schedule[MARCO][di]) for di in idxs):
                raise ValueError("Audit: Marco deve fare 4 turni da 4h, 16h totali, senza spezzati")

    weeks: list[dict[str, Any]] = []
    for w in range(3):
        idxs = list(range(w * 7, w * 7 + 7))
        ws = {n: [schedule[n][i] for i in idxs] for n in PEOPLE}
        wh = {n: round(sum(minutes(s) for s in ws[n]) / 60, 2) for n in PEOPLE}
        splits = {n: sum(is_split(s) for s in ws[n]) for n in PEOPLE}
        balance = {n: {"morning": sum(side(s) < 0 for s in ws[n]), "afternoon": sum(side(s) > 0 for s in ws[n])} for n in CASH + FLOOR}
        max_ot = max([0.0] + [max(0.0, wh[n] - TARGET[n] / 60) for n in OTHERS])
        weeks.append({"label": f"{days[idxs[0]].isoformat()} – {days[idxs[-1]].isoformat()}", "dates": [days[i].isoformat() for i in idxs], "schedule": ws, "meta": {"phase": phase_for(days[idxs[0]]), "absenceCount": len(absent_names_by_week[w]), "ferieCount": len(ferie_names_by_week[w]), "weekHours": wh, "splitByPerson": splits, "splitCount": sum(splits.values()), "maxOT": round(max_ot, 2), "balance": balance, "sunday": sundays[w]}})

    return {"version": "external-ortools-2-rest-rule", "startDate": days[0].isoformat(), "endDate": days[-1].isoformat(), "generatedAt": datetime.utcnow().isoformat(timespec="seconds") + "Z", "responsibleCentral": CENTRAL, "rules": {"weekdayRest": "full-time presenti: esattamente 5 giorni lavorati lun-sab", "marco": "16h, 4x4h, zero spezzati", "maxSplitsPerPerson": 2, "overtimeNormal": 0}, "weeks": weeks, "solver": {"status": "OPTIMAL" if status == cp_model.OPTIMAL else "FEASIBLE", "wallTimeSeconds": round(solver.WallTime(), 3), "objective": round(solver.ObjectiveValue(), 3)}}
