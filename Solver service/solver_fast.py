from __future__ import annotations

from datetime import timedelta
from typing import Any

import solver_weekly
from solver import CASH, FLOOR, MARCO, monday_of, _absence_on


def _compact_pool(name: str, splits_enabled: bool) -> list[str]:
    if not splits_enabled:
        return solver_weekly.shift_pool(name, False)

    if name == "Giada":
        return [
            "RIPOSO", "07:00-12:00", "07:00-13:00", "10:00-15:00",
            "11:00-16:00", "15:30-20:30",
            "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
        ]
    if name == MARCO:
        return ["RIPOSO", "16:00-20:00", "16:30-20:30"]
    if name in CASH:
        return [
            "RIPOSO", "07:00-12:00", "07:00-13:00", "07:00-13:30",
            "07:00-14:00", "10:00-17:00", "11:30-20:30", "12:30-20:30",
            "13:30-20:30", "14:00-20:30", "17:00-20:30",
            "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
        ]
    if name in FLOOR:
        return [
            "RIPOSO", "06:30-12:00", "06:30-13:00", "06:30-13:30",
            "06:30-14:00", "07:00-13:00", "10:00-17:00", "11:30-20:30",
            "12:30-20:30", "13:30-20:30", "14:00-20:30", "17:00-20:30",
            "07:00-13:00 / 17:00-20:00", "07:00-13:00 / 17:00-20:30",
            "06:30-13:30 / 17:00-20:00", "06:30-13:30 / 17:00-20:30",
        ]
    return solver_weekly.shift_pool(name, splits_enabled)


def _has_two_ferie(payload: dict[str, Any]) -> bool:
    start = monday_of(str(payload["startDate"]))
    absences = list(payload.get("absences") or [])
    for w in range(3):
        days = [start + timedelta(days=w * 7 + i) for i in range(7)]
        names = {
            str(a.get("employee_name"))
            for a in absences
            if a.get("employee_name")
            and str(a.get("absence_type") or "").upper() == "FERIE"
            and any(_absence_on([a], str(a.get("employee_name")), d) for d in days)
        }
        if len(names) >= 2:
            return True
    return False


def solve_three_weeks_fast(payload: dict[str, Any]) -> dict[str, Any]:
    if not _has_two_ferie(payload):
        return solver_weekly.solve_three_weeks_weekly(payload)

    original_pool = solver_weekly.shift_pool

    def compact(name: str, splits_enabled: bool) -> list[str]:
        return _compact_pool(name, splits_enabled)

    try:
        solver_weekly.shift_pool = compact
        p = dict(payload)
        p["maxSolveSeconds"] = max(float(p.get("maxSolveSeconds") or 25), 45.0)
        out = solver_weekly.solve_three_weeks_weekly(p)
        out["version"] = "external-ortools-fast-4-rest-rule"
        out.setdefault("solver", {})["mode"] = "fast-two-ferie-optimised"
        return out
    finally:
        solver_weekly.shift_pool = original_pool
