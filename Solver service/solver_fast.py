from __future__ import annotations

from typing import Any

from ortools.sat.python import cp_model

import solver_weekly
from solver import CASH, FLOOR, MARCO, is_split


def _compact_pool(name: str, two_absences: bool) -> list[str]:
    # Compact candidate catalogue used only for 2+ simultaneous absences.
    # It preserves opening, central, closing and split options while avoiding
    # dozens of near-duplicate half-hour variants that slow CP-SAT heavily.
    if not two_absences:
        return solver_weekly.shift_pool(name, False)

    if name == "Giada":
        return [
            "RIPOSO",
            "07:00-12:00",
            "07:00-13:00",
            "10:00-15:00",
            "11:00-16:00",
            "15:30-20:30",
            "07:00-13:00 / 17:00-20:00",
            "07:00-13:00 / 17:00-20:30",
        ]
    if name == MARCO:
        return [
            "RIPOSO",
            "16:00-20:00",
            "16:30-20:30",
            "17:30-20:30",
            "07:00-11:00 / 17:00-20:00",
        ]
    if name in CASH:
        return [
            "RIPOSO",
            "07:00-12:00",
            "07:00-13:00",
            "07:00-13:30",
            "07:00-14:00",
            "10:00-17:00",
            "11:30-20:30",
            "12:30-20:30",
            "13:30-20:30",
            "14:00-20:30",
            "17:00-20:30",
            "07:00-13:00 / 17:00-20:00",
            "07:00-13:00 / 17:00-20:30",
        ]
    if name in FLOOR:
        return [
            "RIPOSO",
            "06:30-12:00",
            "06:30-13:00",
            "06:30-13:30",
            "06:30-14:00",
            "10:00-17:00",
            "11:30-20:30",
            "12:30-20:30",
            "13:30-20:30",
            "14:00-20:30",
            "17:00-20:30",
            "06:30-13:30 / 17:00-20:00",
            "06:30-13:30 / 17:00-20:30",
        ]
    return solver_weekly.shift_pool(name, two_absences)


def _has_two_absences(payload: dict[str, Any]) -> bool:
    from solver import monday_of, _absence_on
    from datetime import timedelta

    start = monday_of(str(payload["startDate"]))
    absences = list(payload.get("absences") or [])
    for w in range(3):
        days = [start + timedelta(days=w * 7 + i) for i in range(7)]
        names = {
            str(a.get("employee_name"))
            for a in absences
            if a.get("employee_name") and any(
                _absence_on([a], str(a.get("employee_name")), d) for d in days
            )
        }
        if len(names) >= 2:
            return True
    return False


def solve_three_weeks_fast(payload: dict[str, Any]) -> dict[str, Any]:
    if not _has_two_absences(payload):
        return solver_weekly.solve_three_weeks_weekly(payload)

    original_pool = solver_weekly.shift_pool
    original_minimize = cp_model.CpModel.Minimize

    def compact(name: str, two_absences: bool) -> list[str]:
        if two_absences:
            return _compact_pool(name, True)
        return original_pool(name, False)

    try:
        # First priority with 2+ absences is feasibility. Mandatory coverage,
        # hours, overtime ceilings, split ceilings and rest constraints remain.
        # Removing the objective lets CP-SAT stop at the first valid roster.
        solver_weekly.shift_pool = compact
        cp_model.CpModel.Minimize = lambda self, expr: None
        p = dict(payload)
        p["maxSolveSeconds"] = max(float(p.get("maxSolveSeconds") or 20), 45.0)
        out = solver_weekly.solve_three_weeks_weekly(p)
        out["version"] = "external-ortools-fast-3"
        out.setdefault("solver", {})["mode"] = "fast-feasibility-two-absences"
        return out
    finally:
        solver_weekly.shift_pool = original_pool
        cp_model.CpModel.Minimize = original_minimize
