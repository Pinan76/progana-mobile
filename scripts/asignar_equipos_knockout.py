#!/usr/bin/env python3
# =============================================================================
# PROGANA Fantasy - Asignador de equipos a la ELIMINATORIA (bracket)
# =============================================================================
# Problema que resuelve:
#   actualizar_resultados.py solo actualiza partidos cuyos equipos YA están
#   puestos (grupos). Los partidos de eliminatoria arrancan con equipo_*_id NULL
#   y NADIE los asigna → las quinielas nuevas salen sin equipos.
#
# Qué hace:
#   Jala TODOS los fixtures del Mundial de API-Football; para cada uno con
#   AMBOS equipos ya resueltos, ubica TU partido por fecha_hora (única por slot
#   en eliminatoria; en grupos desempata por ciudad) y escribe equipo_*_id.
#
# SEGURIDAD L41 (torneo EN VIVO):
#   * DRY_RUN=1 por DEFECTO: no escribe nada; imprime lo que HARÍA + una
#     VALIDACIÓN contra la fase de grupos (si reproduce los equipos ya correctos
#     de grupos, la llave fecha_hora es confiable). Solo con DRY_RUN=0 aplica.
#   * Nunca toca partidos 'finalizado'. Idempotente: solo escribe si cambia.
#
# ENV (mismas secrets que actualizar_resultados.py):
#   APIFOOTBALL_KEY, SUPABASE_URL, SUPABASE_SECRET_KEY
#   DRY_RUN (opcional; "1"=simular [default], "0"=aplicar)
# =============================================================================

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

LEAGUE_ID = 1
SEASON = 2026
APIFOOTBALL_BASE = "https://v3.football.api-sports.io"

# Alias nombre API-Football -> nombre EXACTO en Supabase (mismo que el otro script)
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

GRUPOS_FASES = {"grupos_j1", "grupos_j2", "grupos_j3"}


def map_team(name: str) -> str:
    return ALIAS.get(name, name)


def get_env(key: str, default=None) -> str:
    v = os.environ.get(key, default)
    if v is None:
        print(f"ERROR: falta variable de entorno {key}", file=sys.stderr)
        sys.exit(1)
    return v


APIFOOTBALL_KEY = get_env("APIFOOTBALL_KEY")
SUPABASE_URL = get_env("SUPABASE_URL").rstrip("/")
SUPABASE_SECRET_KEY = get_env("SUPABASE_SECRET_KEY")
DRY_RUN = get_env("DRY_RUN", "1") != "0"


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


def _sb_headers(write: bool = False) -> dict:
    h = {
        "apikey": SUPABASE_SECRET_KEY,
        "Authorization": f"Bearer {SUPABASE_SECRET_KEY}",
    }
    if write:
        h["Content-Type"] = "application/json"
        h["Prefer"] = "return=representation"
    return h


def _parse_dt(s: str) -> datetime | None:
    """Parsea ISO (API-Football o Supabase) a datetime UTC truncado al minuto."""
    if not s:
        return None
    try:
        s = s.replace("Z", "+00:00")
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        dt = dt.astimezone(timezone.utc).replace(second=0, microsecond=0)
        return dt
    except ValueError:
        return None


def fetch_all_fixtures() -> list:
    """Todos los fixtures del Mundial con AMBOS equipos resueltos."""
    url = f"{APIFOOTBALL_BASE}/fixtures?league={LEAGUE_ID}&season={SEASON}"
    data = http_get(url, {"x-apisports-key": APIFOOTBALL_KEY})
    if data.get("errors"):
        print(f"ERROR API-Football: {data['errors']}", file=sys.stderr)
        sys.exit(1)
    out = []
    for item in data.get("response", []):
        teams = item.get("teams", {}) or {}
        home = (teams.get("home", {}) or {}).get("name") or ""
        away = (teams.get("away", {}) or {}).get("name") or ""
        if not home or not away:
            continue  # aún sin resolver (TBD)
        fx = item.get("fixture", {}) or {}
        dt = _parse_dt(fx.get("date", ""))
        if dt is None:
            continue
        city = ((fx.get("venue", {}) or {}).get("city") or "").strip()
        out.append({
            "home": map_team(home),
            "away": map_team(away),
            "dt": dt,
            "city": city,
        })
    return out


def fetch_equipos() -> dict:
    rows = http_get(f"{SUPABASE_URL}/rest/v1/equipos?select=id,nombre", _sb_headers())
    return {r["nombre"]: r["id"] for r in rows}


def fetch_partidos() -> list:
    sel = "id,fase,numero_partido,fecha_hora,ciudad,equipo_local_id,equipo_visit_id,estado"
    return http_get(f"{SUPABASE_URL}/rest/v1/partidos?select={sel}", _sb_headers())


def _norm_city(c: str) -> str:
    return (c or "").lower().strip()


def index_partidos(partidos: list) -> dict:
    """Índice por datetime UTC (minuto) -> lista de partidos en ese horario."""
    idx: dict[datetime, list] = {}
    for p in partidos:
        dt = _parse_dt(p.get("fecha_hora", ""))
        if dt is None:
            continue
        idx.setdefault(dt, []).append(p)
    return idx


def match_partido(fx: dict, idx: dict) -> dict | None:
    """Ubica el partido por fecha_hora; si hay varios (grupos simultáneos),
    desempata por ciudad. En eliminatoria el horario es único."""
    cands = idx.get(fx["dt"])
    if not cands:
        return None
    if len(cands) == 1:
        return cands[0]
    fc = _norm_city(fx["city"])
    for p in cands:
        if fc and fc == _norm_city(p.get("ciudad", "")):
            return p
        if fc and (fc in _norm_city(p.get("ciudad", "")) or
                   _norm_city(p.get("ciudad", "")) in fc):
            return p
    return None  # ambiguo: no arriesgamos


def patch_partido(pid: int, local_id: int, visit_id: int) -> list:
    params = urllib.parse.urlencode({"id": f"eq.{pid}", "estado": "neq.finalizado"})
    url = f"{SUPABASE_URL}/rest/v1/partidos?{params}"
    body = {"equipo_local_id": local_id, "equipo_visit_id": visit_id}
    return http_patch(url, _sb_headers(write=True), body)


def main() -> int:
    modo = "DRY-RUN (simulación, no escribe)" if DRY_RUN else "APLICAR (escribe a la BD)"
    print(f"=== PROGANA - Asignador de eliminatoria | {modo} ===")

    fixtures = fetch_all_fixtures()
    equipos = fetch_equipos()
    partidos = fetch_partidos()
    idx = index_partidos(partidos)
    print(f"API-Football: {len(fixtures)} fixtures resueltos | "
          f"Supabase: {len(equipos)} equipos, {len(partidos)} partidos")

    val_ok = val_bad = 0          # validación contra grupos
    val_mismatches = []
    ko_planeados = []             # cambios propuestos en eliminatoria
    aplicados = 0
    sin_equipo = []
    sin_partido = []

    for fx in fixtures:
        local_id = equipos.get(fx["home"])
        visit_id = equipos.get(fx["away"])
        if local_id is None or visit_id is None:
            sin_equipo.append(f"{fx['home']} vs {fx['away']} (revisar ALIAS)")
            continue
        p = match_partido(fx, idx)
        if p is None:
            sin_partido.append(f"{fx['home']} vs {fx['away']} @ {fx['dt']}")
            continue

        if p["fase"] in GRUPOS_FASES:
            # VALIDACIÓN: ¿la llave reproduce los equipos correctos de grupos?
            if p.get("equipo_local_id") == local_id and p.get("equipo_visit_id") == visit_id:
                val_ok += 1
            else:
                val_bad += 1
                if len(val_mismatches) < 10:
                    val_mismatches.append(
                        f"  partido {p['numero_partido']} @ {fx['dt']}: "
                        f"BD=({p.get('equipo_local_id')},{p.get('equipo_visit_id')}) "
                        f"vs propuesto=({local_id},{visit_id}) [{fx['home']} vs {fx['away']}]")
            continue

        # ELIMINATORIA
        if p.get("estado") == "finalizado":
            continue
        if p.get("equipo_local_id") == local_id and p.get("equipo_visit_id") == visit_id:
            continue  # ya correcto, idempotente
        ko_planeados.append(
            f"  partido {p['numero_partido']} ({p['fase']}) @ {fx['dt']}: "
            f"-> {fx['home']} (L) vs {fx['away']} (V)  [ids {local_id},{visit_id}]")
        if not DRY_RUN:
            try:
                res = patch_partido(p["id"], local_id, visit_id)
                if res:
                    aplicados += 1
            except urllib.error.HTTPError as e:
                print(f"  ERROR partido {p['id']}: HTTP {e.code} "
                      f"{e.read().decode('utf-8')[:150]}")

    print("\n=== VALIDACIÓN CONTRA GRUPOS (confiabilidad de la llave) ===")
    print(f"  Coinciden: {val_ok}  |  NO coinciden: {val_bad}")
    if val_mismatches:
        print("  Desajustes (si hay, NO confíes aún — revisa ALIAS/ciudad):")
        print("\n".join(val_mismatches))

    print(f"\n=== ELIMINATORIA — cambios {'propuestos' if DRY_RUN else 'APLICADOS'} "
          f"({len(ko_planeados)}) ===")
    print("\n".join(ko_planeados) if ko_planeados else "  (ninguno)")
    if not DRY_RUN:
        print(f"\nAplicados: {aplicados}")

    if sin_equipo:
        print(f"\nAVISO - equipos sin match (revisar ALIAS): {sin_equipo}")
    if sin_partido:
        print(f"AVISO - fixtures sin partido en BD por fecha: {len(sin_partido)}")

    print("\n" + ("[DRY-RUN] No se escribió nada. Si la validación de GRUPOS da "
                  "0 desajustes, corre con DRY_RUN=0 para aplicar."
                  if DRY_RUN else "[APLICADO] Revisa las quinielas."))
    return 0


if __name__ == "__main__":
    sys.exit(main())
