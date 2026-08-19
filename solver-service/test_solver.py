from solver import PEOPLE, RESP, TARGET, is_split, minutes, solve_three_weeks


def absences(*names):
    return [
        {
            "employee_name": n,
            "absence_type": "FERIE",
            "date_from": "2026-08-24",
            "date_to": "2026-08-30",
        }
        for n in names
    ]


def run(*names):
    return solve_three_weeks(
        {
            "startDate": "2026-08-24",
            "absences": absences(*names),
            "requests": [],
            "rotationSwaps": {},
            "maxSolveSeconds": 30,
        }
    )


def check_week(data, absent=()):
    w = data["weeks"][0]
    ac = len(absent)
    for n in PEOPLE:
        shifts = w["schedule"][n]
        h = sum(minutes(s) for s in shifts)
        splits = sum(is_split(s) for s in shifts)
        if n in absent:
            assert h == 0
            continue
        if n in RESP:
            continue
        target = TARGET[n]
        if ac == 0:
            assert h == target
            assert splits == 0
        elif ac == 1:
            assert h == target
            assert splits <= (0 if n in {"Giada", "Marco"} else 1)
        else:
            assert target <= h <= target + 240
            assert splits <= 2


def test_normal():
    d = run()
    check_week(d)


def test_one_floor_absent():
    d = run("Giuliano")
    check_week(d, {"Giuliano"})


def test_one_responsible_absent():
    d = run("Umberto")
    check_week(d, {"Umberto"})


def test_floor_cash_absent():
    d = run("Giuliano", "Romina")
    check_week(d, {"Giuliano", "Romina"})


def test_floor_responsible_absent():
    d = run("Giuliano", "Umberto")
    check_week(d, {"Giuliano", "Umberto"})
