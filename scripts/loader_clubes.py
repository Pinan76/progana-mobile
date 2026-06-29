"""Loader Motor 2 (clubes) — API-Football -> Supabase PROGANA Fantasy.

Reusa el patrón de api_football.py de PROGANA Predict (urllib + 'x-apisports-key').
Escribe en Supabase con psycopg2 (autocommit para REFRESH MATERIALIZED VIEW CONCURRENTLY).

Flujo:
  1. Asegura la competición (competiciones) por api_football_id.
  2. Trae equipos (GET /teams) -> UPSERT en clubes -> mapa {api_team_id: clube_id}.
  3. Trae fixtures (GET /fixtures) -> UPSERT en partidos_liga (mapea equipos).
  4. Partidos terminados (FT) -> goles -> resultado L/E/V lo calcula la BD.
  5. REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ranking_liga.
  6. SELECT actualizar_estados_quinielas_liga().

Variables de entorno:
  API_FOOTBALL_KEY   -> tu key de API-Sports (la misma de PROGANA Predict)
  SUPABASE_DB_URL    -> conexión DIRECTA a Postgres (puerto 5432, NO el pooler 6543)
                        ej: postgresql://postgres:[PASS]@db.zqqylkabzlqhtfhmbxse.supabase.co:5432/postgres

Uso:
  python loader_clubes.py --liga ligamx --season 2026 --round Apertura --dry-run
  python loader_clubes.py --liga ligamx --season 2026 --round Apertura
"""
from __future__ import annotations

import argparse
import json
import os
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import datetime

import psycopg2
from psycopg2.extras import execute_values

BASE_URL = "https://v3.football.api-sports.io"

# IDs de liga en API-Football (verificar en el dashboard):
LEAGUE_IDS = {
    "ligamx": 262, "epl": 39, "laliga": 140, "brasileirao": 71,
    "ligaarg": 128, "ucl": 2,
}

# Estado API-Football -> estado_partido (enum de tu BD)
STATUS_MAP = {
    "NS": "programado", "TBD": "programado", "PST": "programado",
    "1H": "en_juego", "2H": "en_juego", "HT": "en_juego", "ET": "en_juego",
    "BT": "en_juego", "P": "en_juego", "LIVE": "en_juego", "INT": "en_juego",
    "FT": "finalizado", "AET": "finalizado", "PEN": "finalizado",
    "CANC": "cancelado", "ABD": "cancelado", "AWD": "finalizado", "WO": "finalizado",
}
FINISHED = {"FT", "AET", "PEN", "AWD", "WO"}


@dataclass
class Fixture:
    fixture_id: int
    date: str
    status: str
    round: str
    home_id: int
    home: str
    away_id: int
    away: str
    home_goals: int | None
    away_goals: int | None


# ─────────────────────────── HTTP (aislado) ────────────────────────────────
def _get(path: str, params: dict, api_key: str, timeout: int = 20) -> dict:
    url = f"{BASE_URL}{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(
        url, headers={"x-apisports-key": api_key, "User-Agent": "progana-fantasy-loader/0.1"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


# ─────────────────────────── Parseo (puro) ─────────────────────────────────
def parse_teams(data: dict) -> list[dict]:
    out = []
    for it in data.get("response", []):
        t = it.get("team", {})
        if t.get("id"):
            out.append({
                "api_team_id": t["id"],
                "nombre": t.get("name"),
                "nombre_corto": (t.get("code") or (t.get("name") or "")[:3]).upper(),
                "escudo_url": t.get("logo"),
                "ciudad": (it.get("venue") or {}).get("city"),
            })
    return out


def parse_fixtures(data: dict) -> list[Fixture]:
    out = []
    for it in data.get("response", []):
        fx, lg = it.get("fixture", {}), it.get("league", {})
        tm, gl = it.get("teams", {}), it.get("goals", {})
        h, a = tm.get("home") or {}, tm.get("away") or {}
        if not h.get("id") or not a.get("id"):
            continue
        out.append(Fixture(
            fixture_id=fx.get("id"),
            date=fx.get("date", ""),
            status=(fx.get("status") or {}).get("short", ""),
            round=lg.get("round", "") or "",
            home_id=h["id"], home=h.get("name"),
            away_id=a["id"], away=a.get("name"),
            home_goals=gl.get("home"), away_goals=gl.get("away"),
        ))
    return out


# ─────────────────────────── Escritura (Supabase) ──────────────────────────
def ensure_competicion(cur, nombre, nombre_corto, api_id, pais, temporada) -> int:
    cur.execute(
        """
        INSERT INTO competiciones (nombre, nombre_corto, api_football_id, pais, tipo, temporada)
        VALUES (%s, %s, %s, %s, 'liga', %s)
        ON CONFLICT (api_football_id) DO UPDATE
          SET nombre = EXCLUDED.nombre, temporada = EXCLUDED.temporada, updated_at = now()
        RETURNING id
        """,
        (nombre, nombre_corto, api_id, pais, temporada),
    )
    return cur.fetchone()[0]


def upsert_clubes(cur, competicion_id: int, teams: list[dict]) -> dict[int, int]:
    rows = [(competicion_id, t["api_team_id"], t["nombre"], t["nombre_corto"],
             t["escudo_url"], t["ciudad"]) for t in teams]
    execute_values(
        cur,
        """
        INSERT INTO clubes (competicion_id, api_team_id, nombre, nombre_corto, escudo_url, ciudad)
        VALUES %s
        ON CONFLICT (api_team_id) DO UPDATE
          SET nombre = EXCLUDED.nombre, escudo_url = EXCLUDED.escudo_url,
              competicion_id = EXCLUDED.competicion_id, updated_at = now()
        """,
        rows,
    )
    cur.execute("SELECT api_team_id, id FROM clubes WHERE competicion_id = %s", (competicion_id,))
    return {api: cid for api, cid in cur.fetchall()}


def upsert_fixtures(cur, competicion_id: int, fixtures: list[Fixture], team_map: dict[int, int]) -> int:
    rows = []
    for f in fixtures:
        local = team_map.get(f.home_id)
        visit = team_map.get(f.away_id)
        if not local or not visit:
            continue  # equipo no mapeado (faltaría cargarlo)
        estado = STATUS_MAP.get(f.status, "programado")
        # goles solo cuando está terminado (para no calcular resultado a media)
        gl = f.home_goals if f.status in FINISHED else None
        gv = f.away_goals if f.status in FINISHED else None
        try:
            fecha = datetime.fromisoformat(f.date.replace("Z", "+00:00"))
        except ValueError:
            continue
        jornada = _extract_jornada(f.round)
        rows.append((competicion_id, jornada, local, visit, fecha, fecha,
                     estado, gl, gv, f.fixture_id))
    if not rows:
        return 0
    execute_values(
        cur,
        """
        INSERT INTO partidos_liga
          (competicion_id, jornada, equipo_local_id, equipo_visit_id,
           fecha_hora, fecha_cierre_predicciones, estado, goles_local, goles_visit, api_fixture_id)
        VALUES %s
        ON CONFLICT (api_fixture_id) DO UPDATE
          SET fecha_hora = EXCLUDED.fecha_hora,
              fecha_cierre_predicciones = EXCLUDED.fecha_cierre_predicciones,
              estado = EXCLUDED.estado,
              goles_local = EXCLUDED.goles_local,
              goles_visit = EXCLUDED.goles_visit,
              updated_at = now()
        """,
        rows,
    )
    return len(rows)


def _extract_jornada(round_str: str) -> int | None:
    # "Apertura - 5" / "Regular Season - 12" -> 5 / 12
    for tok in round_str.replace("-", " ").split():
        if tok.isdigit():
            return int(tok)
    return None


# ─────────────────────────────── Main ──────────────────────────────────────
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--liga", required=True, help="ligamx, epl, laliga, brasileirao, ligaarg, ucl")
    ap.add_argument("--season", type=int, required=True)
    ap.add_argument("--round", default=None, help="filtro de 'round' (ej. Apertura). Vacío = todos.")
    ap.add_argument("--dry-run", action="store_true", help="solo lee y muestra, no escribe")
    args = ap.parse_args()

    api_key = os.environ["API_FOOTBALL_KEY"]
    league_id = LEAGUE_IDS.get(args.liga)
    if not league_id:
        raise SystemExit(f"Liga desconocida: {args.liga}")

    print(f"→ API-Football: league={league_id} season={args.season}")
    teams = parse_teams(_get("/teams", {"league": league_id, "season": args.season}, api_key))
    fixtures = parse_fixtures(_get("/fixtures", {"league": league_id, "season": args.season}, api_key))

    if args.round:
        fixtures = [f for f in fixtures if args.round.lower() in f.round.lower()]

    print(f"  equipos: {len(teams)} · fixtures: {len(fixtures)}")
    rounds = sorted({f.round for f in fixtures})
    print(f"  rounds distintos: {rounds[:12]}{' ...' if len(rounds) > 12 else ''}")

    if args.dry_run:
        print("\n[DRY-RUN] Muestra de fixtures:")
        for f in fixtures[:8]:
            print(f"  {f.date[:16]} | {f.round:18} | {f.home} vs {f.away} "
                  f"| {f.status} {f.home_goals}-{f.away_goals}")
        print("\n[DRY-RUN] No se escribió nada en la BD.")
        return

    # Escritura
    conn = psycopg2.connect(os.environ["SUPABASE_DB_URL"])
    try:
        with conn:
            with conn.cursor() as cur:
                comp_id = ensure_competicion(
                    cur, _liga_nombre(args.liga), args.liga.upper(),
                    league_id, _liga_pais(args.liga), f"{args.round or args.season}")
                team_map = upsert_clubes(cur, comp_id, teams)
                n = upsert_fixtures(cur, comp_id, fixtures, team_map)
                print(f"  competicion_id={comp_id} · clubes={len(team_map)} · partidos upsert={n}")
        # REFRESH + estados (autocommit, fuera de transacción)
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ranking_liga;")
            cur.execute("SELECT actualizar_estados_quinielas_liga();")
            print(f"  ranking refrescado · estados: {cur.fetchone()[0]}")
    finally:
        conn.close()
    print("✓ Carga completa.")


def _liga_nombre(k):
    return {"ligamx": "Liga MX", "epl": "Premier League", "laliga": "La Liga",
            "brasileirao": "Brasileirão", "ligaarg": "Liga Argentina",
            "ucl": "Champions League"}.get(k, k)


def _liga_pais(k):
    return {"ligamx": "México", "epl": "Inglaterra", "laliga": "España",
            "brasileirao": "Brasil", "ligaarg": "Argentina", "ucl": "Europa"}.get(k)


if __name__ == "__main__":
    main()
