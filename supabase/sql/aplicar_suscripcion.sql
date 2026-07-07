-- =============================================================================
-- PROGANA Fantasy — aplicar_suscripcion()
-- El "cerebro" que conecta un evento de pago con el tier del usuario.
-- Fuente ÚNICA de verdad = profiles.tier. subscriptions_history = registro/auditoría.
--
-- Idempotente (webhooks de OpenPay reintentan): UPSERT por subscription_id.
-- Robusto a cambios de plan / eventos fuera de orden: el tier se RECALCULA
--   siempre desde TODAS las suscripciones vigentes del usuario (pro > plus).
-- SECURITY DEFINER: la llama solo el backend (service_role), nunca el usuario.
-- =============================================================================

-- 1) Índice UNIQUE requerido para el UPSERT idempotente (tabla vacía → seguro).
CREATE UNIQUE INDEX IF NOT EXISTS uq_subs_subscription_id
  ON public.subscriptions_history (subscription_id);

-- 2) La función
CREATE OR REPLACE FUNCTION public.aplicar_suscripcion(
  p_user_id         uuid,
  p_subscription_id text,
  p_provider        public.proveedor_pago,
  p_plan            text,                       -- 'plus' | 'pro'
  p_status          public.estado_suscripcion,
  p_amount          numeric,
  p_next_billing    timestamptz DEFAULT NULL,
  p_metadata        jsonb       DEFAULT '{}'::jsonb
) RETURNS public.tier_usuario
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_now  timestamptz := now();
  v_tier public.tier_usuario;
  v_is_pro boolean;
BEGIN
  -- Validación de entradas
  IF p_user_id IS NULL OR COALESCE(p_subscription_id,'') = '' THEN
    RAISE EXCEPTION 'user_id y subscription_id son obligatorios';
  END IF;
  IF p_plan NOT IN ('plus','pro') THEN
    RAISE EXCEPTION 'plan invalido "%": debe ser plus o pro', p_plan;
  END IF;

  -- 1) Registro idempotente en subscriptions_history (por subscription_id)
  INSERT INTO subscriptions_history AS s (
    user_id, subscription_id, payment_provider, plan_type, amount_mxn, currency,
    status, started_at, ended_at, next_billing_at, metadata, created_at, updated_at
  ) VALUES (
    p_user_id, p_subscription_id, p_provider, p_plan, p_amount, 'MXN',
    p_status,
    CASE WHEN p_status = 'activa' THEN v_now END,
    CASE WHEN p_status IN ('cancelada','expirada') THEN v_now END,
    p_next_billing, COALESCE(p_metadata,'{}'::jsonb), v_now, v_now
  )
  ON CONFLICT (subscription_id) DO UPDATE SET
    status          = EXCLUDED.status,
    plan_type       = EXCLUDED.plan_type,
    amount_mxn      = EXCLUDED.amount_mxn,
    next_billing_at = COALESCE(EXCLUDED.next_billing_at, s.next_billing_at),
    started_at      = COALESCE(s.started_at,
                               CASE WHEN EXCLUDED.status = 'activa' THEN v_now END),
    ended_at        = CASE WHEN EXCLUDED.status IN ('cancelada','expirada') THEN v_now
                           ELSE s.ended_at END,
    metadata        = COALESCE(s.metadata,'{}'::jsonb) || COALESCE(EXCLUDED.metadata,'{}'::jsonb),
    updated_at      = v_now;

  -- 2) Tier EFECTIVO = mejor suscripción vigente del usuario (pro > plus); si no hay, free.
  --    Recalcular desde TODAS las subs evita bugs por cambios de plan o eventos
  --    fuera de orden (p.ej. el "cancel" del plan viejo llega tras el "activa" del nuevo).
  SELECT plan_type::public.tier_usuario
    INTO v_tier
  FROM subscriptions_history
  WHERE user_id = p_user_id
    AND status IN ('activa','en_periodo_gracia')
  ORDER BY (plan_type = 'pro') DESC, next_billing_at DESC NULLS LAST
  LIMIT 1;

  v_tier   := COALESCE(v_tier, 'free'::public.tier_usuario);
  v_is_pro := (v_tier = 'pro');

  -- 3) profiles = fuente única. tier e is_pro NUNCA divergen (is_pro deriva del tier).
  UPDATE profiles SET
    tier           = v_tier,
    is_pro         = v_is_pro,
    pro_since      = CASE WHEN v_is_pro AND pro_since IS NULL THEN v_now
                          WHEN NOT v_is_pro THEN NULL
                          ELSE pro_since END,
    pro_expires_at = CASE WHEN v_is_pro THEN
                            (SELECT max(next_billing_at) FROM subscriptions_history
                             WHERE user_id = p_user_id AND plan_type = 'pro'
                               AND status IN ('activa','en_periodo_gracia'))
                          ELSE NULL END,
    updated_at     = v_now
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'profile no encontrado para user %', p_user_id;
  END IF;

  RETURN v_tier;
END;
$$;

-- 3) Permisos: SOLO el backend puede otorgar tier. El usuario NUNCA se auto-asigna plan.
REVOKE ALL ON FUNCTION public.aplicar_suscripcion(
  uuid, text, public.proveedor_pago, text, public.estado_suscripcion, numeric, timestamptz, jsonb
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.aplicar_suscripcion(
  uuid, text, public.proveedor_pago, text, public.estado_suscripcion, numeric, timestamptz, jsonb
) TO service_role;
