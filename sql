-- =====================================================
-- نظام إدارة مركبات بلدية محافظة جنوب الشرقية
-- قاعدة بيانات Supabase / PostgreSQL
-- =====================================================

-- ─── جدول المركبات ───
CREATE TABLE IF NOT EXISTS vehicles (
    id              BIGSERIAL PRIMARY KEY,
    vehicle_number  VARCHAR(50)  NOT NULL UNIQUE,
    vehicle_type    VARCHAR(150) NOT NULL,
    model_year      INT,
    color           VARCHAR(100),
    chassis_number  VARCHAR(100),
    engine_number   VARCHAR(100),
    fuel_type       VARCHAR(50),
    status          VARCHAR(30) DEFAULT 'available'
                    CHECK (status IN ('available','in_use','maintenance','accident','out_of_service')),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول حركات المركبات ───
CREATE TABLE IF NOT EXISTS vehicle_movements (
    id                  BIGSERIAL PRIMARY KEY,
    vehicle_id          BIGINT NOT NULL REFERENCES vehicles(id),
    driver_name         VARCHAR(255) NOT NULL,
    department          VARCHAR(255),
    mission_name        TEXT,
    mission_location    VARCHAR(255),
    pickup_date         DATE,
    pickup_time         TIME,
    pickup_meter        NUMERIC(12,2),
    pickup_fuel_level   VARCHAR(50),
    status              VARCHAR(20) DEFAULT 'active'
                        CHECK (status IN ('active','returned')),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول إعادة المركبات ───
CREATE TABLE IF NOT EXISTS vehicle_returns (
    id                  BIGSERIAL PRIMARY KEY,
    movement_id         BIGINT NOT NULL REFERENCES vehicle_movements(id),
    return_date         DATE,
    return_time         TIME,
    return_meter        NUMERIC(12,2),
    distance_km         NUMERIC(12,2),
    fuel_level          VARCHAR(50),
    driver_commitment   BOOLEAN DEFAULT TRUE,
    return_notes        TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول فحص ما قبل الخروج ───
CREATE TABLE IF NOT EXISTS vehicle_pre_inspections (
    id              BIGSERIAL PRIMARY KEY,
    movement_id     BIGINT NOT NULL REFERENCES vehicle_movements(id),
    tires_ok        BOOLEAN,
    lights_ok       BOOLEAN,
    ac_ok           BOOLEAN,
    oil_ok          BOOLEAN,
    water_ok        BOOLEAN,
    extinguisher_ok BOOLEAN,
    first_aid_ok    BOOLEAN,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول فحص ما بعد الإرجاع ───
CREATE TABLE IF NOT EXISTS vehicle_post_inspections (
    id              BIGSERIAL PRIMARY KEY,
    movement_id     BIGINT NOT NULL REFERENCES vehicle_movements(id),
    body_ok         BOOLEAN,
    tires_ok        BOOLEAN,
    lights_ok       BOOLEAN,
    new_damage      BOOLEAN DEFAULT FALSE,
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول الصيانة ───
CREATE TABLE IF NOT EXISTS maintenance_records (
    id                  BIGSERIAL PRIMARY KEY,
    vehicle_id          BIGINT NOT NULL REFERENCES vehicles(id),
    workshop_name       VARCHAR(255),
    maintenance_type    VARCHAR(255),
    maintenance_reason  TEXT,
    maintenance_date    DATE,
    maintenance_time    TIME,
    estimated_cost      NUMERIC(12,3),
    actual_cost         NUMERIC(12,3),
    end_date            DATE,
    status              VARCHAR(20) DEFAULT 'open'
                        CHECK (status IN ('open','in_progress','completed')),
    notes               TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول الحوادث ───
CREATE TABLE IF NOT EXISTS accident_records (
    id                      BIGSERIAL PRIMARY KEY,
    vehicle_id              BIGINT NOT NULL REFERENCES vehicles(id),
    movement_id             BIGINT REFERENCES vehicle_movements(id),
    driver_name             VARCHAR(255),
    accident_date           DATE,
    accident_time           TIME,
    accident_location       VARCHAR(255),
    accident_description    TEXT,
    management_decision     TEXT,
    status                  VARCHAR(20) DEFAULT 'under_review'
                            CHECK (status IN ('under_review','repairing','closed')),
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ─── جدول الأعطال ───
CREATE TABLE IF NOT EXISTS fault_records (
    id              BIGSERIAL PRIMARY KEY,
    vehicle_id      BIGINT NOT NULL REFERENCES vehicles(id),
    fault_type      VARCHAR(255),
    description     TEXT,
    reporter_name   VARCHAR(255),
    status          VARCHAR(20) DEFAULT 'open'
                    CHECK (status IN ('open','in_progress','resolved')),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── بيانات تجريبية - مركبات ───
INSERT INTO vehicles (vehicle_number, vehicle_type, model_year, color, fuel_type, status) VALUES
('أ ب ج 1234', 'تويوتا لاند كروزر',  2023, 'أبيض',  'بنزين', 'available'),
('د ه و 5678', 'نيسان باترول',        2022, 'أسود',  'بنزين', 'available'),
('ز ح ط 9012', 'هيونداي توسان',       2023, 'فضي',   'بنزين', 'available'),
('ك ل م 3456', 'تويوتا هايلوكس',      2021, 'أبيض',  'ديزل',  'available'),
('ن س ع 7890', 'فورد F150',           2022, 'أحمر',  'بنزين', 'available')
ON CONFLICT (vehicle_number) DO NOTHING;

-- ─── Row Level Security (RLS) ───
ALTER TABLE vehicles                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_movements         ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_returns           ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_pre_inspections   ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_post_inspections  ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records       ENABLE ROW LEVEL SECURITY;
ALTER TABLE accident_records          ENABLE ROW LEVEL SECURITY;
ALTER TABLE fault_records             ENABLE ROW LEVEL SECURITY;

-- السماح بالقراءة والكتابة للجميع (للمرحلة التجريبية)
-- يُستبدل لاحقاً بصلاحيات مبنية على المستخدمين
CREATE POLICY "allow_all_vehicles"                 ON vehicles                  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_movements"                ON vehicle_movements         FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_returns"                  ON vehicle_returns           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_pre_inspections"          ON vehicle_pre_inspections   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_post_inspections"         ON vehicle_post_inspections  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_maintenance"              ON maintenance_records       FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_accidents"                ON accident_records          FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_faults"                   ON fault_records             FOR ALL USING (true) WITH CHECK (true);
