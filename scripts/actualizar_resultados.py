#!/usr/bin/env python3
# =============================================================================
# PROGANA Fantasy - Actualizador de resultados (GitHub Actions + Postgres)
# =============================================================================
#
# L41 COMPLIANT (17 jun 2026):
#   - Llama API-Football, trae partidos FINALIZADOS (FT/AET/PEN) del Mundial
#   - Aplica alias de nombres (Czechia->Czech Republic, etc.)
#   - Escribe directo a Postgres con psycopg2 (NO usa REST API ni sb_secret,
#     que daban 403 Forbidden). La connection string del Session pooler
#     tiene permisos completos.
#   - El UPDATE dispara el trigger tg_procesar_al_finalizar
#     -> procesar_partido_finalizado (puntos) + refresh_rankings (matviews)
#   - IDEMPOTENTE: solo actualiza partidos que NO estan ya 'finalizado'
#   - DEFENSIVO: transaccion unica, rollback si algo falla, reporte claro
#
# VARIABLES DE ENTORNO (GitHub Secrets):
#   APIFOOTBALL_KEY  - tu key de API-Football
#   SUPABASE_DB_URL  - connection string del Session pooler:
#       postgresql://postgres.zqqyl...:[PASSWORD]@...pooler.supabase.com:5432/postgres
#
# Dependencia: psycopg2-binary (se instala en el workflow)
# =============================================================================

import json
import os
import sys
import urllib.error
import urllib.request

import psycopg2

# --- Config ---
LEAGUE_ID = 1
SEASON = 2026
APIFOOTBALL_BASE = "https://v3.football.api-sports.io"
FINISHED_STATUSES = {"FT", "AET", "PEN"}

# --- Alias: nombre API-Football -> nombre EXACTO en Supabase ---
ALIAS = {
    "Czechia": "Czech Republic",
    "Turkiye": "Turkey",
    "Curacao": "Curacao",
    "Cape Verde Islands": "Cape Verde",
    "Congo DR": "DR Congo",
    "Korea Republic": "South Korea",
    "IR Iran": "Iran",
}
# Variantes con caracteres especiales (por si llegan con acento)
ALIAS["T\u00fcrkiye"] = "Turkey"
ALIAS["Cura\u00e7ao"] = "Curacao"


def map_team(name):
    return ALIAS.get(name, name)


def calc_resultado(gl, gv):
    if gl > gv:
        return "L"
    if gl < gv:
        return "V"
    return "E"


def get_env(key):
    v = os.environ.get(key)
    if not v:
        print("ERROR: falta variable de entorno " + key, file=sys.stderr)
        sys.exit(1)
    return v


APIFOOTBALL_KEY = get_env("APIFOOTBALL_KEY")
SUPABASE_DB_URL = get_env("SUPABASE_DB_URL")


def fetch_finished_fixtures():
    url = APIFOOTBALL_BASE + "/fixtures?league=" + str(LEAGUE_ID) + "&season=" + str(SEASON)
    req = urllib.request.Request(url, headers={"x-apisports-key": APIFOOTBALL_KEY})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("ERROR API-Football HTTP " + str(e.code) + ": "
              + e.read().decode("utf-8")[:300], file=sys.stderr)
        sys.exit(1)

    if data.get("errors"):
        print("ERROR API-Football: " + str(data["errors"]), file=sys.stderr)
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


def main():
    print("=== PROGANA - Actualizador de resultados (Postgres directo) ===")

    fixtures = fetch_finished_fixtures()
    print("API-Football: " + str(len(fixtures)) + " partidos finalizados")

    if not fixtures:
        print("No hay partidos finalizados. Nada que hacer.")
        return 0

    print("Conectando a Postgres...")
    conn = psycopg2.connect(SUPABASE_DB_URL)
    conn.autocommit = False
    cur = conn.cursor()

    cur.execute("SELECT id, nombre FROM equipos;")
    equipos = {nombre: id_ for (id_, nombre) in cur.fetchall()}
    print("Equipos cargados: " + str(len(equipos)))

    actualizados = 0
    sin_match_equipo = []
    no_aplicados = []

    try:
        for fx in fixtures:
            local_id = equipos.get(fx["home"])
            visit_id = equipos.get(fx["away"])

            if local_id is None or visit_id is None:
                sin_match_equipo.append(fx["home"] + " vs " + fx["away"])
                continue

            resultado = calc_resultado(fx["gl"], fx["gv"])

            cur.execute(
                """
                UPDATE partidos
                SET goles_local = %s,
                    goles_visit = %s,
                    resultado   = %s,
                    estado      = 'finalizado'
                WHERE equipo_local_id = %s
                  AND equipo_visit_id = %s
                  AND estado <> 'finalizado';
                """,
                (fx["gl"], fx["gv"], resultado, local_id, visit_id),
            )

            if cur.rowcount > 0:
                actualizados += cur.rowcount
                print("  OK " + fx["home"] + " " + str(fx["gl"]) + "-"
                      + str(fx["gv"]) + " " + fx["away"] + " [" + resultado + "]")
            else:
                no_aplicados.append(fx["home"] + " vs " + fx["away"])

        conn.commit()
        print("\nTransaccion confirmada (commit).")

    except Exception as e:
        conn.rollback()
        print("\nERROR durante UPDATE, rollback aplicado: " + str(e), file=sys.stderr)
        cur.close()
        conn.close()
        return 1

    cur.close()
    conn.close()

    print()
    print("=== RESUMEN ===")
    print("Partidos actualizados: " + str(actualizados))
    print("Ya finalizados o sin partido en BD: " + str(len(no_aplicados)))
    if sin_match_equipo:
        print("AVISO - equipos sin match (agregar alias): " + str(sin_match_equipo))

    return 0


if __name__ == "__main__":
    sys.exit(main())
