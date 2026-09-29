-- ==============================================================================
-- SmartMess Queue & Campus Dining Platform - Supabase PostgreSQL Schema
-- Theme: Modern Food-Tech SaaS (Oceanic Teal & Fresh Emerald)
-- Includes: 16 Core Tables, RLS Policies, Indexes, and Production Seed Data
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. PROFILES (Students, Wardens, Kitchen Admins)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin', 'warden', 'staff')),
    hostel_block TEXT DEFAULT 'Hostel Block B',
    room_number TEXT DEFAULT '412',
    pass_code TEXT DEFAULT 'SM-2024',
    avatar_url TEXT DEFAULT 'assets/images/student-avatar.png',
    phone TEXT,
    dietary_preference TEXT DEFAULT 'all' CHECK (dietary_preference IN ('vegetarian', 'non-vegetarian', 'vegan', 'all')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_auth_user ON public.profiles(auth_user_id);

-- ==============================================================================
-- 2. MESS SETTINGS (Global dining hall configuration & thresholds)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mess_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mess_name TEXT NOT NULL DEFAULT 'Central Dining Hall - Block 3',
    max_capacity INTEGER NOT NULL DEFAULT 300 CHECK (max_capacity > 0),
    low_threshold_pct INTEGER NOT NULL DEFAULT 40 CHECK (low_threshold_pct >= 0 AND low_threshold_pct <= 100),
    mod_threshold_pct INTEGER NOT NULL DEFAULT 75 CHECK (mod_threshold_pct >= 0 AND mod_threshold_pct <= 100),
    operating_hours JSONB DEFAULT '{"breakfast": "07:30 - 09:30", "lunch": "12:00 - 14:30", "snacks": "17:00 - 18:30", "dinner": "19:30 - 22:00"}'::jsonb,
    is_queue_active BOOLEAN NOT NULL DEFAULT true,
    active_camera_id TEXT DEFAULT 'Cam-02 South Entrance Gate',
    yolo_inference_fps INTEGER DEFAULT 30,
    optical_flow_sensitivity INTEGER DEFAULT 75 CHECK (optical_flow_sensitivity >= 0 AND optical_flow_sensitivity <= 100),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 3. MENU ITEMS (Daily breakfast, lunch, snacks, dinner offerings)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'snacks', 'dinner')),
    category TEXT DEFAULT 'main' CHECK (category IN ('main', 'special', 'bread_rice', 'dessert', 'beverage', 'side')),
    is_vegetarian BOOLEAN NOT NULL DEFAULT true,
    is_chef_special BOOLEAN NOT NULL DEFAULT false,
    tags TEXT[] DEFAULT '{}',
    description TEXT,
    calories INTEGER,
    image_url TEXT,
    available_days TEXT[] DEFAULT '{"monday","tuesday","wednesday","thursday","friday","saturday","sunday"}',
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_menu_items_meal ON public.menu_items(meal_type);
CREATE INDEX IF NOT EXISTS idx_menu_items_veg ON public.menu_items(is_vegetarian);

-- ==============================================================================
-- 4. FOOD RATINGS (Per-dish star ratings & review tags)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.food_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_food_ratings_dish ON public.food_ratings(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_food_ratings_user ON public.food_ratings(user_id);

-- ==============================================================================
-- 5. FEEDBACK (Meal-level student dining feedback & service ratings)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'snacks', 'dinner')),
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
    service_speed_rating INTEGER CHECK (service_speed_rating >= 1 AND service_speed_rating <= 5),
    cleanliness_rating INTEGER CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
    comment TEXT,
    tags TEXT[] DEFAULT '{}',
    is_anonymous BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_feedback_created ON public.feedback(created_at DESC);

-- ==============================================================================
-- 6. FOOD SUGGESTIONS (Student dish requests for next cycle)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.food_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    dish_name TEXT NOT NULL,
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'snacks', 'dinner')),
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'approved', 'rejected')),
    vote_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_suggestions_status ON public.food_suggestions(status);

-- ==============================================================================
-- 7. SUGGESTION VOTES (Upvotes for food suggestions)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.suggestion_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id UUID NOT NULL REFERENCES public.food_suggestions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_suggestion_vote UNIQUE (suggestion_id, user_id)
);

-- ==============================================================================
-- 8. MONTHLY VOTES (Shape Next Month's Menu poll sessions)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.monthly_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL DEFAULT 'Shape Next Month''s Menu',
    month_year TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    total_votes INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    expires_at TIMESTAMPTZ
);

-- ==============================================================================
-- 9. MONTHLY VOTE OPTIONS (Options in the poll: Masala Dosa, Paneer Pizza)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.monthly_vote_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.monthly_votes(id) ON DELETE CASCADE,
    item_key TEXT NOT NULL,
    display_name TEXT NOT NULL,
    vote_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_poll_item UNIQUE (poll_id, item_key)
);

CREATE INDEX IF NOT EXISTS idx_monthly_options_poll ON public.monthly_vote_options(poll_id);

-- ==============================================================================
-- 10. MONTHLY USER VOTES (One vote per user per poll session)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.monthly_user_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES public.monthly_votes(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES public.monthly_vote_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT unique_user_poll_vote UNIQUE (poll_id, user_id)
);

-- ==============================================================================
-- 11. COMPLAINTS (Student mess tickets: hygiene, taste, shortage)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    category TEXT NOT NULL CHECK (category IN ('hygiene', 'quality', 'shortage', 'queue', 'staff', 'other')),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(status);

-- ==============================================================================
-- 12. OCCUPANCY (Current live hall capacity & radar telemetry)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.occupancy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mess_id UUID REFERENCES public.mess_settings(id) ON DELETE CASCADE,
    current_count INTEGER NOT NULL DEFAULT 147 CHECK (current_count >= 0),
    in_line_count INTEGER NOT NULL DEFAULT 32 CHECK (in_line_count >= 0),
    estimated_wait_minutes INTEGER NOT NULL DEFAULT 7,
    status_tier TEXT NOT NULL DEFAULT 'moderate' CHECK (status_tier IN ('low', 'moderate', 'peak')),
    optical_in_rate INTEGER DEFAULT 14,
    optical_out_rate INTEGER DEFAULT 9,
    throughput_per_minute INTEGER DEFAULT 23,
    yolo_fps INTEGER DEFAULT 30,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 13. OCCUPANCY EVENTS (YOLO camera entry/exit detection stream)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.occupancy_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mess_id UUID REFERENCES public.mess_settings(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('entry', 'exit', 'calibration', 'surge_alert')),
    delta INTEGER NOT NULL DEFAULT 1,
    current_occupancy INTEGER NOT NULL,
    camera_id TEXT DEFAULT 'Cam-02 South Entrance Gate',
    confidence NUMERIC(4, 2) DEFAULT 0.97,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_occupancy_events_ts ON public.occupancy_events(timestamp DESC);

-- ==============================================================================
-- 14. QUEUE ENTRIES (Virtual boarding pass tickets)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.queue_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number INTEGER NOT NULL,
    ticket_code TEXT NOT NULL,
    lane TEXT NOT NULL DEFAULT 'Lane B2' CHECK (lane IN ('Lane B2', 'Dietary A1', 'Counter 1', 'Counter 2')),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'called', 'served', 'cancelled', 'expired')),
    students_ahead INTEGER NOT NULL DEFAULT 31,
    estimated_call_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    called_at TIMESTAMPTZ,
    served_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_queue_status ON public.queue_entries(status);
CREATE INDEX IF NOT EXISTS idx_queue_ticket_num ON public.queue_entries(ticket_number);

-- ==============================================================================
-- 15. NOTIFICATIONS (Broadcast announcements & personal queue alerts)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_role TEXT DEFAULT 'all' CHECK (target_role IN ('all', 'student', 'admin', 'warden')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'alert', 'menu_special', 'queue_call', 'rush_warning')),
    icon TEXT DEFAULT 'notifications',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- ==============================================================================
-- 16. MENU CHANGE HISTORY (Audit trail of warden menu swaps & broadcasts)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menu_change_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('swap', 'update', 'special_broadcast', 'disable')),
    old_value JSONB,
    new_value JSONB,
    broadcast_sent BOOLEAN DEFAULT false,
    broadcast_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mess_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suggestion_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_vote_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_user_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occupancy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occupancy_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_change_history ENABLE ROW LEVEL SECURITY;

-- Permissive Read policies for public demo and authenticated users
CREATE POLICY "Public profiles read" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Public mess settings read" ON public.mess_settings FOR SELECT USING (true);
CREATE POLICY "Public menu read" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Public ratings read" ON public.food_ratings FOR SELECT USING (true);
CREATE POLICY "Public feedback read" ON public.feedback FOR SELECT USING (true);
CREATE POLICY "Public suggestions read" ON public.food_suggestions FOR SELECT USING (true);
CREATE POLICY "Public suggestion votes read" ON public.suggestion_votes FOR SELECT USING (true);
CREATE POLICY "Public monthly votes read" ON public.monthly_votes FOR SELECT USING (true);
CREATE POLICY "Public monthly vote options read" ON public.monthly_vote_options FOR SELECT USING (true);
CREATE POLICY "Public complaints read" ON public.complaints FOR SELECT USING (true);
CREATE POLICY "Public occupancy read" ON public.occupancy FOR SELECT USING (true);
CREATE POLICY "Public occupancy events read" ON public.occupancy_events FOR SELECT USING (true);
CREATE POLICY "Public queue read" ON public.queue_entries FOR SELECT USING (true);
CREATE POLICY "Public notifications read" ON public.notifications FOR SELECT USING (true);
CREATE POLICY "Public menu history read" ON public.menu_change_history FOR SELECT USING (true);

-- Permissive Insert policies for student participation
CREATE POLICY "Allow ratings insert" ON public.food_ratings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow feedback insert" ON public.feedback FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow queue join insert" ON public.queue_entries FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow queue status update" ON public.queue_entries FOR UPDATE USING (true);
CREATE POLICY "Allow monthly user vote insert" ON public.monthly_user_votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow suggestion vote insert" ON public.suggestion_votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow complaints insert" ON public.complaints FOR INSERT WITH CHECK (true);

-- Admin management policies
CREATE POLICY "Admin manage mess settings" ON public.mess_settings FOR ALL USING (true);
CREATE POLICY "Admin manage menu items" ON public.menu_items FOR ALL USING (true);
CREATE POLICY "Admin manage occupancy" ON public.occupancy FOR ALL USING (true);
CREATE POLICY "Admin manage notifications" ON public.notifications FOR ALL USING (true);
CREATE POLICY "Admin manage menu history" ON public.menu_change_history FOR ALL USING (true);

-- ==============================================================================
-- INITIAL SEED DATA (Aligns with SmartMess Stitch UI)
-- ==============================================================================

-- 1. Demo Profiles
INSERT INTO public.profiles (id, full_name, email, role, hostel_block, room_number, pass_code)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Utkarsh Sharma', 'utkarsh@campus.edu', 'student', 'Hostel Block B', '412', 'SM-2024'),
    ('00000000-0000-0000-0000-000000000002', 'Chief Kitchen Warden', 'warden@campus.edu', 'admin', 'Dining Administration', 'Office 1', 'ADMIN-01')
ON CONFLICT (id) DO NOTHING;

-- 2. Mess Settings
INSERT INTO public.mess_settings (id, mess_name, max_capacity, low_threshold_pct, mod_threshold_pct)
VALUES ('00000000-0000-0000-0000-000000000010', 'Central Dining Hall - Block 3', 300, 40, 75)
ON CONFLICT (id) DO NOTHING;

-- 3. Live Occupancy
INSERT INTO public.occupancy (id, mess_id, current_count, in_line_count, estimated_wait_minutes, status_tier, optical_in_rate, optical_out_rate, throughput_per_minute, yolo_fps)
VALUES (
    '00000000-0000-0000-0000-000000000020',
    '00000000-0000-0000-0000-000000000010',
    147,
    32,
    7,
    'moderate',
    14,
    9,
    23,
    30
) ON CONFLICT (id) DO NOTHING;

-- 4. Initial Menu Items (Matches Student Dashboard & Dining Menu screens)
INSERT INTO public.menu_items (id, name, meal_type, category, is_vegetarian, is_chef_special, tags, description, calories, image_url)
VALUES 
    (
        '10000000-0000-0000-0000-000000000001',
        'Paneer Butter Masala',
        'lunch',
        'special',
        true,
        true,
        ARRAY['Student Favorite', 'Mild Spice', 'High Protein'],
        'Cottage cheese cubes in rich tomato-cashew gravy',
        380,
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCSzd9PDsbtdj8G1KRUOkgmgiVgQayeygTFLMyUr5j6jA8hFzTi4nZr_HCqXiMHtsJI-uFNyQWhq1DEXl9P204dB5WaJbg2TMdLgcVh-TOeHLr3y2kihMyfjTOibmRvEMD-Y1Isg7YvJo-gpf1TjaIjq6DG6FWLly0OFgi3Xh45J7Vyl5NdBpuZOaxakkaGJnrPn71OWv6DVXf0ozJPR93mAf7b5Ll1wrUhm1aYiRvelaMqTdIu3ioD'
    ),
    (
        '10000000-0000-0000-0000-000000000002',
        'Chicken Curry (Special)',
        'dinner',
        'special',
        false,
        true,
        ARRAY['High Protein', 'Chef Special'],
        'Slow-cooked homestyle spicy coriander gravy',
        420,
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDZXJ54EWslAq2zh_kFRfnUxVvSBEauwprevht3yvTZpQ9V1pKja_ZkWCJu23nNKH7s2eXY2j5vj-JgG5vaIm_YyPZCG-y9mZJbZnc0cE79m2BDxBTwWbjPoshMwWNQw4jgTjKfT2NXwicTO_MRUSH4CKBQ9nLFbmEV_xAA6nP827NpFkF-NIkrQl-51ZSnKHuc1T4HYAJ-xsYMlm20PaZhJfckXhvR9g7Nh2eCD33SnfxcLsS4x43B'
    ),
    (
        '10000000-0000-0000-0000-000000000003',
        'Crispy Masala Dosa & Sambar',
        'breakfast',
        'main',
        true,
        false,
        ARRAY['South Indian', 'Fresh Coconut Chutney'],
        'Golden fermented crepe with spiced potato filling and piping hot lentil stew',
        310,
        NULL
    ),
    (
        '10000000-0000-0000-0000-000000000004',
        'Crispy Veg Samosa (2 pcs)',
        'snacks',
        'main',
        true,
        false,
        ARRAY['Tea-Time', 'Popular'],
        'Spiced potato & green peas wrapped in flaky golden pastry with mint chutney',
        260,
        NULL
    )
ON CONFLICT (id) DO NOTHING;

-- 5. Initial Virtual Queue Pass (#38)
INSERT INTO public.queue_entries (id, ticket_number, ticket_code, lane, user_id, status, students_ahead, estimated_call_time)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    38,
    'SMM-Q-2024-0038-NX',
    'Lane B2',
    '00000000-0000-0000-0000-000000000001',
    'waiting',
    31,
    timezone('utc'::text, now()) + interval '7 minutes'
) ON CONFLICT (id) DO NOTHING;

-- 6. Initial Monthly Poll
INSERT INTO public.monthly_votes (id, title, month_year, is_active, total_votes)
VALUES (
    '30000000-0000-0000-0000-000000000001',
    'Shape Next Month''s Menu',
    'October 2026',
    true,
    1248
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.monthly_vote_options (id, poll_id, item_key, display_name, vote_count)
VALUES 
    ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'dosa', 'Masala Dosa', 382),
    ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'pizza', 'Paneer Pizza', 291)
ON CONFLICT (id) DO NOTHING;

-- 7. Initial Campus Notifications
INSERT INTO public.notifications (user_id, target_role, title, message, type, icon)
VALUES 
    (NULL, 'all', 'Menu Special Live', 'Chef''s special Paneer Butter Masala added for lunch today.', 'menu_special', 'restaurant_menu'),
    (NULL, 'all', 'Low Rush Prediction', 'Recommended slot is 2:05 PM - 2:25 PM with <3 min wait.', 'rush_warning', 'access_time'),
    ('00000000-0000-0000-0000-000000000001', 'student', 'Virtual Pass Confirmed', 'You are #38 in Lane B2. Estimated wait: ~7 minutes.', 'queue_call', 'confirmation_number')
ON CONFLICT DO NOTHING;
