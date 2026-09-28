-- PrepLoop schema v1 (single-user app: one row in users)

CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE stacks (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    icon       VARCHAR(50),
    color      VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE topics (
    id         BIGSERIAL PRIMARY KEY,
    stack_id   BIGINT NOT NULL REFERENCES stacks(id) ON DELETE CASCADE,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (stack_id, name)
);

CREATE TABLE import_batches (
    id             BIGSERIAL PRIMARY KEY,
    topic_id       BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    source_name    VARCHAR(255),
    raw_text_hash  VARCHAR(64),
    question_count INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE questions (
    id              BIGSERIAL PRIMARY KEY,
    topic_id        BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    import_batch_id BIGINT REFERENCES import_batches(id) ON DELETE SET NULL,
    text            TEXT NOT NULL,
    type            VARCHAR(10) NOT NULL CHECK (type IN ('MCQ', 'OPEN')),
    category        VARCHAR(15) NOT NULL CHECK (category IN ('CONCEPTUAL', 'TECHNICAL', 'SCENARIO')),
    difficulty      VARCHAR(10) NOT NULL CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
    answer          TEXT,
    hint            TEXT,
    explanation     TEXT,
    tags            TEXT[] NOT NULL DEFAULT '{}',
    text_hash       VARCHAR(64) NOT NULL,
    archived        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_questions_topic ON questions(topic_id);
CREATE INDEX idx_questions_hash  ON questions(text_hash);

CREATE TABLE question_options (
    id          BIGSERIAL PRIMARY KEY,
    question_id BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    is_correct  BOOLEAN NOT NULL DEFAULT FALSE,
    position    INT NOT NULL
);
CREATE INDEX idx_options_question ON question_options(question_id);

CREATE TABLE quiz_sessions (
    id         BIGSERIAL PRIMARY KEY,
    topic_id   BIGINT REFERENCES topics(id) ON DELETE SET NULL,
    filters    JSONB NOT NULL DEFAULT '{}',
    status     VARCHAR(12) NOT NULL DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'FINISHED')),
    started_at TIMESTAMP NOT NULL DEFAULT now(),
    ended_at   TIMESTAMP
);

CREATE TABLE attempts (
    id              BIGSERIAL PRIMARY KEY,
    session_id      BIGINT NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
    question_id     BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    result          VARCHAR(10) NOT NULL
                    CHECK (result IN ('PERFECT', 'ASSISTED', 'REVEALED', 'MISSED', 'GOT_IT', 'PARTLY')),
    tries           INT NOT NULL DEFAULT 1,
    hint_used       BOOLEAN NOT NULL DEFAULT FALSE,
    answer_revealed BOOLEAN NOT NULL DEFAULT FALSE,
    time_ms         INT,
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_attempts_created  ON attempts(created_at);
CREATE INDEX idx_attempts_question ON attempts(question_id);

CREATE TABLE question_stats (
    question_id     BIGINT PRIMARY KEY REFERENCES questions(id) ON DELETE CASCADE,
    attempts        INT NOT NULL DEFAULT 0,
    misses          INT NOT NULL DEFAULT 0,
    assists         INT NOT NULL DEFAULT 0,
    last_result     VARCHAR(10),
    last_attempt_at TIMESTAMP,
    weakness_score  NUMERIC(5,2) NOT NULL DEFAULT 0
);
CREATE INDEX idx_stats_weakness ON question_stats(weakness_score DESC);
