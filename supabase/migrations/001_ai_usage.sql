-- Track AI API usage per user per day for rate limiting
CREATE TABLE IF NOT EXISTS public.ai_usage (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    action TEXT NOT NULL CHECK (action IN ('summarize', 'translate')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One row per user per day per action for efficient counting
CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_usage_user_date_action
    ON public.ai_usage (user_id, date, action);

-- RLS: users can only read their own usage
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own usage"
    ON public.ai_usage FOR SELECT
    USING (auth.uid() = user_id);

-- Edge Function uses service_role, bypasses RLS for inserts
