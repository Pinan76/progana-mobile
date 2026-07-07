-- =============================================================================
-- PROGANA Fantasy — expirar_suscripciones_vencidas()
-- Red de seguridad: baja a 'free' a quien venció y no renovó, por si el webhook
-- final de OpenPay ("cancelled/expired") nunca llegó (webhook perdido, downtime).
--
-- Reusa aplicar_suscripcion() → el downgrade pasa por el MISMO camino robusto
-- (recalcula el tier desde todas las subs; nunca baja de más).
-- Idempotente: al correr de nuevo, las ya expiradas no vuelven a entrar.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.expirar_suscripciones_vencidas(
  p_dias_gracia integer DEFAULT 3
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  v_count integer := 0;
BEGIN
  FOR r IN
    SELECT subscription_id, user_id, payment_provider, plan_type,
           amount_mxn, next_billing_at
    FROM subscriptions_history
    WHERE status IN ('activa','en_periodo_gracia')
      AND next_billing_at IS NOT NULL
      AND next_billing_at < (now() - make_interval(days => GREATEST(p_dias_gracia,0)))
  LOOP
    PERFORM public.aplicar_suscripcion(
      r.user_id, r.subscription_id, r.payment_provider, r.plan_type,
      'expirada'::public.estado_suscripcion, r.amount_mxn, r.next_billing_at,
      jsonb_build_object('expirado_por','job_automatico','fecha', now())
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;   -- cuántas suscripciones se expiraron en esta corrida
END;
$$;

REVOKE ALL ON FUNCTION public.expirar_suscripciones_vencidas(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expirar_suscripciones_vencidas(integer) TO service_role;

-- =============================================================================
-- AGENDADO (elige UNA opción cuando vayas a producción):
--
-- Opción pg_cron (nativo — requiere activar la extensión primero):
--   Dashboard → Database → Extensions → activar "pg_cron", luego:
--   SELECT cron.schedule('expirar-subs', '0 * * * *',
--          $$ SELECT public.expirar_suscripciones_vencidas(3); $$);
--
-- Opción GitHub Action (reusa tu patrón ya probado del Mundial):
--   un workflow con schedule que hace POST a
--   {SUPABASE_URL}/rest/v1/rpc/expirar_suscripciones_vencidas  con apikey=service key
-- =============================================================================
