#!/usr/bin/env python3
# =============================================================================
# PROGANA Fantasy - Actualizador de resultados (GitHub Actions)
# =============================================================================
# FIX (jul 2026): apikey-only (sin Authorization:Bearer) para las keys nuevas
#   sb_secret_ (no son JWT; con Bearer daban 403). + imprime el cuerpo del error.
#   Requiere GRANTs: SELECT en equipos, SELECT+UPDATE en partidos, a service_role.
# =============================================================================

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

LEAGUE_ID = 1
SEASON = 2026
APIFOOTBALL_BASE = "https://v3.football.api-sports.io"
FINISHED_STATUSES = {"FT", "AET", "PEN"}

ALIAS = {
    "Czechia": "Czech Republic",
    "Türkiye": "Turkey",
    "Turkiye": "Turkey",
    "Curaçao": "Curacao",
    "Cape Verde Islands": "Cape Verde",
    "Congo DR": "DR Congo",
    "Korea Republic": "South Korea",
    "IR Iran": "Iran",
}


def map_team(name: str) -> str:
    return ALIAS.get(name, name)


def calc_resultado(gl: int, gv: int) -> str:
    if gl > gv:
        return "L"
    if gl < gv:
        return "V"
    return "E"


def get_env(key: str) -> str:
    v = os.environ.get(key)
    if not v:
        print(f"ERROR: falta variable de entorno {key}", file=sys.stderr)
        sys.exit(1)
    return v


APIFOOTBALL_KEY = get_env("APIFOOTBALL_KEY")
SUPABASE_URL = get_env("SUPABASE_URL").rstrip("/")
SUPABASE_SECRET_KEY = get_env("SUPABASE_SECRET_KEY")


def http_get(url: str, headers: dict) -> dict:
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")[:400]
        print(f"HTTP {e.code} en GET {url}\n  Respuesta: {body}", file=sys.stderr)
        raise


def http_patch(url: str, headers: dict, body: dict) -> list:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode("utf-8")
            return json.loads(text) if text else []
    except urllib.error.HTTPError as e:
        eb = e.read().decode("utf-8", "ignore")[:400]
        print(f"HTTP {e.code} en PATCH {url}\n  Respuesta: {eb}", file=sys.stderr)
        raise


def _sb_headers(write: bool = False) -> dict:
    # apikey-only: las keys sb_secret_ NO son JWT; con Authorization:Bearer daban 403.
    h = {"apikey": SUPABASE_SECRET_KEY}
    if write:
        h["Content-Type"] = "application/json"
        h["Prefer"] = "return=representation"
    return h


def fetch_finished_fixtures() -> list:
    url = f"{APIFOOTBALL_BASE}/fixtures?league={LEAGUE_ID}&season={SEASON}"
    data = http_get(url, {"x-apisports-key": APIFOOTBALL_KEY})
    if data.get("errors"):
        print(f"ERROR API-Football: {data['errors']}", file=sys.stderr)
        sys.exit(1)
    out = []
    for item in data.get("response", []):
        status = (item.get("fixture", {}).get("status", {}) or {}).get("short", "")
        if status not in FINISHED_STATUSES:
            continue
        goals = item.get("goals", {}) or {}
        gh, ga = goals.get("home"), goals.get("away")
        if gh is None or ga is None:
            continue
        teams = item.get("teams", {}) or {}
        out.append({
            "home": map_team((teams.get("home", {}) or {}).get("name", "")),
            "away": map_team((teams.get("away", {}) or {}).get("name", "")),
            "gl": int(gh),
            "gv": int(ga),
        })
    return out


def fetch_equipos() -> dict:
    rows = http_get(f"{SUPABASE_URL}/rest/v1/equipos?select=id,nombre", _sb_headers())
    return {r["nombre"]: r["id"] for r in rows}


def update_partido(local_id: int, visit_id: int, gl: int, gv: int) -> list:
    params = urllib.parse.urlencode({
        "equipo_local_id": f"eq.{local_id}",
        "equipo_visit_id": f"eq.{visit_id}",
        "estado": "neq.finalizado",
    })
    url = f"{SUPABASE_URL}/rest/v1/partidos?{params}"
    # OJO: 'resultado' es columna GENERADA (L/E/V se calcula de los goles).
    # NO se puede setear (da 400: "can only be updated to DEFAULT").
    # Solo mandamos goles + estado; Postgres computa 'resultado' solo.
    body = {
        "goles_local": gl,
        "goles_visit": gv,
        "estado": "finalizado",
    }
    return http_patch(url, _sb_headers(write=True), body)


def main() -> int:
    print("=== PROGANA - Actualizador de resultados (GitHub Actions) ===")
    fixtures = fetch_finished_fixtures()
    print(f"API-Football: {len(fixtures)} partidos finalizados")
    if not fixtures:
        print("No hay partidos finalizados. Nada que hacer.")
        return 0

    equipos = fetch_equipos()
    print(f"Supabase: {len(equipos)} equipos cargados")

    actualizados = 0
    sin_match_equipo = []
    sin_match_partido = []

    for fx in fixtures:
        local_id = equipos.get(fx["home"])
        visit_id = equipos.get(fx["away"])
        if local_id is None or visit_id is None:
            sin_match_equipo.append(f"{fx['home']} vs {fx['away']}")
            continue
        try:
            updated = update_partido(local_id, visit_id, fx["gl"], fx["gv"])
        except urllib.error.HTTPError:
            continue
        if updated:
            actualizados += 1
            print(f"  OK {fx['home']} {fx['gl']}-{fx['gv']} {fx['away']}")
        else:
            sin_match_partido.append(f"{fx['home']} vs {fx['away']}")

    print()
    print("=== RESUMEN ===")
    print(f"Actualizados: {actualizados}")
    print(f"Ya finalizados o sin partido en BD: {len(sin_match_partido)}")
    if sin_match_equipo:
        print(f"AVISO - equipos sin match (revisar alias): {sin_match_equipo}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
