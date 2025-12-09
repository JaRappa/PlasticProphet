-- 1) users
CREATE TABLE users (
  user_id         BIGSERIAL PRIMARY KEY,
  username        TEXT UNIQUE NOT NULL,
  email           CITEXT UNIQUE NOT NULL,
  password_hash   TEXT NOT NULL,
  phone_number    TEXT CHECK (phone_number ~ '^[0-9]+$'),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2) wallet (metadata only)
CREATE TABLE wallet (
  card_id       BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  card_type     TEXT,
  card_network  TEXT NOT NULL CHECK (card_network IN ('visa','mastercard','amex','discover','other')),
  card_issuer   TEXT,
  card_name     TEXT,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX wallet_user_idx ON wallet (user_id);

-- 3) rolling_merchant (≤20 per generation, per user)
CREATE TABLE rolling_merchant (
  user_id            BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  generation_id      UUID   NOT NULL,
  merchant_hash      TEXT   NOT NULL,
  raw_poi_name       TEXT,
  generalized_name   TEXT   NOT NULL,
  category_key       TEXT,
  mcc                TEXT,
  lat                DOUBLE PRECISION,
  lon                DOUBLE PRECISION,
  radius_meters      INTEGER,
  arm_geofence       BOOLEAN DEFAULT FALSE,
  region_identifier  TEXT,
  distance_meters    INTEGER,
  detected_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at         TIMESTAMPTZ,
  PRIMARY KEY (user_id, generation_id, merchant_hash)
);
CREATE INDEX rolling_user_recent_idx ON rolling_merchant (user_id, detected_at DESC);

-- 4) favorite_merchant (persistent favorites)
CREATE TABLE favorite_merchant (
  user_id           BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  merchant_hash     TEXT   NOT NULL,
  generalized_name  TEXT   NOT NULL,
  category_key      TEXT,
  lat               DOUBLE PRECISION,
  lon               DOUBLE PRECISION,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, merchant_hash)
);
CREATE INDEX fav_user_idx ON favorite_merchant (user_id);
