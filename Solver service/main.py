from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

sys.path.insert(0, str((Path(__file__).resolve().parent.parent / "solver-service").resolve()))
from solver_weekly import solve_three_weeks_weekly

app = FastAPI(title="Eurospin Turni Solver", version="1.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

class SolveRequest(BaseModel):
    startDate: str
    absences: list[dict[str, Any]] = Field(default_factory=list)
    requests: list[dict[str, Any]] = Field(default_factory=list)
    rotationSwaps: dict[str, Any] = Field(default_factory=dict)
    maxSolveSeconds: float = 20.0

@app.get("/health")
def health() -> dict[str, str]:
    return {"ok": "true", "service": "eurospin-ortools-solver"}

@app.post("/solve")
def solve(payload: SolveRequest) -> dict[str, Any]:
    try:
        return {"schedule": solve_three_weeks_weekly(payload.model_dump())}
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Errore solver: {exc}") from exc
