#!/usr/bin/env python3
# =============================================================================
# PROGANA Fantasy - Actualizador de resultados (GitHub Actions)
# =============================================================================
#
# L41 COMPLIANT (17 jun 2026):
#   - Llama API-Football, trae partidos FINALIZADOS (FT/AET/PEN) del Mundial
#   - Aplica alias de nombres (Czechia->Czech Republic, etc.)
#   - Escribe a Supabase vía REST API (PATCH) con la secret key
#     (GitHub Actions = entorno protegido, la secret key SÍ funciona aquí)
#   - El UPDATE dispara el trigger tg_procesar_al_finalizar
#     -> procesar_partido_finalizado (puntos) + refresh_rankings (matviews)
#   - IDEMPOTENTE: solo actualiza partidos que NO están ya 'finalizado'
#   - DEFENSIVO: valida cada paso, reporta qué procesó
#
# VARIABLES DE ENTORNO (GitHub Secrets):
#   APIFOOTBALL_KEY       - tu key de API-Football
#   SUPABASE_URL          - https://zqqylkabzlqhtfhmbxse.supabase.co
#   SUPABASE_SECRET_KEY   - tu NUEVA sb_secret_ (la rotada)
#
# Sin dependencias externas: usa solo urllib (stdlib).
# =============================================================================

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

# --- Config ---
LEAGUE_ID = 1
SEASON = 2026
APIFOOTBALL_BASE = "https://v3.football.api-sports.io"
FINISHED_STATUSES = {"FT", "AET", "PEN"}

# --- Alias: nombre API-Football -> nombre EXACTO en Supabase ---
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


# --- Lectura de entorno ---
def get_env(key: str) -> str:
    v = os.environ.get(key)
    if not v:
        print(f"ERROR: falta variable de entorno {key}", file=sys.stderr)
        sys.exit(1)
    return v


APIFOOTBALL_KEY = get_env("APIFOOTBALL_KEY")
SUPABASE_URL = get_env("SUPABASE_URL").rstrip("/")
SUPABASE_SECRET_KEY = get_env("SUPABASE_SECRET_KEY")


# --- HTTP helpers ---
def http_get(url: str, headers: dict) -> dict:
    req = urllib.request.Request(url, headers=headers, method="GET")
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def http_patch(url: str, headers: dict, body: dict) -> list:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
    with urllib.request.urlopen(req, timeout=30) as resp:
        text = resp.read().decode("utf-8")
        return json.loads(text) if text else []


# --- API-Football: partidos finalizados ---
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


# --- Supabase: mapa nombre equipo -> id ---
def fetch_equipos() -> dict:
    url = f"{SUPABASE_URL}/rest/v1/equipos?select=id,nombre"
    headers = {
        "apikey": SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {SUPABASE_SECRET_KEY}",
    }
    rows = http_get(url, headers)
    return {r["nombre"]: r["id"] for r in rows}


# --- Supabase: actualizar un partido ---
def update_partido(local_id: int, visit_id: int, gl: int, gv: int,
                   resultado: str) -> list:
    # Filtra por equipos + que NO esté ya finalizado (idempotencia)
    params = urllib.parse.urlencode({
        "equipo_local_id": f"eq.{local_id}",
        "equipo_visit_id": f"eq.{visit_id}",
        "estado": "neq.finalizado",
    })
    url = f"{SUPABASE_URL}/rest/v1/partidos?{params}"
    headers = {
        "apikey": SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {SUPABASE_SECRET_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }
    body = {
        "goles_local": gl,
        "goles_visit": gv,
        "resultado": resultado,
        "estado": "finalizado",
    }
    return http_patch(url, headers, body)


# --- Main ---
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

        resultado = calc_resultado(fx["gl"], fx["gv"])
        try:
            updated = update_partido(local_id, visit_id, fx["gl"], fx["gv"],
                                     resultado)
        except urllib.error.HTTPError as e:
            print(f"  ERROR {fx['home']} vs {fx['away']}: "
                  f"HTTP {e.code} {e.read().decode('utf-8')[:200]}")
            continue

        if updated:
            actualizados += 1
            print(f"  OK {fx['home']} {fx['gl']}-{fx['gv']} {fx['away']} [{resultado}]")
        else:
            # Ya estaba finalizado (idempotencia) o no existe ese partido
            sin_match_partido.append(f"{fx['home']} vs {fx['away']}")

    print()
    print(f"=== RESUMEN ===")
    print(f"Actualizados: {actualizados}")
    print(f"Ya finalizados o sin partido en BD: {len(sin_match_partido)}")
    if sin_match_equipo:
        print(f"AVISO - equipos sin match (revisar alias): {sin_match_equipo}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
