-- ============================================================================
-- USERS, STUDENTS e TEACHERS
-- ============================================================================

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    type_user VARCHAR(50) NOT NULL,
    campus VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    email_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME(6)
);

CREATE TABLE students (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    version BIGINT NOT NULL DEFAULT 0,
    user_id BIGINT NOT NULL UNIQUE,
    registration VARCHAR(255) NOT NULL UNIQUE,
    course VARCHAR(255),
    classroom VARCHAR(255),
    xp INT DEFAULT 0,
    level INT DEFAULT 1,
    badges_count INT DEFAULT 0,
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE teachers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    siape VARCHAR(50) NOT NULL UNIQUE,
    department VARCHAR(100),
    CONSTRAINT fk_teachers_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE token_confirmation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(255) NOT NULL UNIQUE,
    expiration_date DATETIME(6) NOT NULL,
    user_id BIGINT NOT NULL UNIQUE,
    CONSTRAINT fk_token_confirmation_user FOREIGN KEY (user_id) REFERENCES users(id)
);


-- ============================================================================
-- TRAILS, MODULES, CONTENTS e MATERIALS
-- ============================================================================

CREATE TABLE trails (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL,
    learning_hours INT,
    xp_reward INT,
    icon VARCHAR(255),
    color_theme VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6),
    teacher_id BIGINT,
    CONSTRAINT fk_trails_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

CREATE TABLE modules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    module_order INT,
    xp_reward INT,
    trail_id BIGINT NOT NULL,
    CONSTRAINT fk_modules_trail FOREIGN KEY (trail_id) REFERENCES trails(id)
);

CREATE TABLE contents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    type_content VARCHAR(50) NOT NULL,
    url VARCHAR(255),
    file_path VARCHAR(255),
    content_order INT,
    module_id BIGINT NOT NULL,
    author_id BIGINT,
    has_curated_path BOOLEAN NOT NULL DEFAULT FALSE,
    approved BOOLEAN NOT NULL DEFAULT FALSE,
    average_rating DOUBLE DEFAULT 0,
    total_downloads INT DEFAULT 0,
    tags VARCHAR(255),
    created_at DATETIME(6),
    CONSTRAINT fk_contents_module FOREIGN KEY (module_id) REFERENCES modules(id),
    CONSTRAINT fk_contents_author FOREIGN KEY (author_id) REFERENCES teachers(id)
);

CREATE TABLE materials (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    url VARCHAR(255),
    file_path VARCHAR(255),
    tags VARCHAR(255),
    approved BOOLEAN NOT NULL DEFAULT FALSE,
    curated BOOLEAN NOT NULL DEFAULT FALSE,
    total_downloads INT NOT NULL DEFAULT 0,
    average_rating DOUBLE NOT NULL DEFAULT 0,
    author_id BIGINT NOT NULL,
    created_at DATETIME(6) NOT NULL,
    CONSTRAINT fk_materials_author FOREIGN KEY (author_id) REFERENCES teachers(id)
);


-- ============================================================================
-- GAMIFICATION
-- ============================================================================

CREATE TABLE achievements (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    icon VARCHAR(255),
    xp_reward INT,
    type VARCHAR(50),
    standard_value INT
);

CREATE TABLE student_achievements (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    achievement_id BIGINT NOT NULL,
    achieved_at DATETIME(6),
    CONSTRAINT uk_student_achievement UNIQUE (student_id, achievement_id),
    CONSTRAINT fk_student_achievements_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_student_achievements_achievement FOREIGN KEY (achievement_id) REFERENCES achievements(id)
);

CREATE TABLE xp_weekly (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    xp_gained INT DEFAULT 0,
    number_week INT NOT NULL,
    year INT NOT NULL,
    start_week DATE NOT NULL,
    CONSTRAINT uk_xp_weekly_student_week UNIQUE (student_id, number_week, year),
    INDEX idx_xp_weekly_student_year (student_id, year),
    CONSTRAINT fk_xp_weekly_student FOREIGN KEY (student_id) REFERENCES students(id)
);


-- ============================================================================
-- LEARNING PROGRESS
-- ============================================================================

CREATE TABLE trail_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    trail_id BIGINT NOT NULL,
    completion_percentage INT DEFAULT 0,
    xp_gained INT DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    last_activity DATETIME(6),
    started_at DATETIME(6),
    CONSTRAINT uk_trail_progress_student_trail UNIQUE (student_id, trail_id),
    CONSTRAINT fk_trail_progress_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_trail_progress_trail FOREIGN KEY (trail_id) REFERENCES trails(id),
    CONSTRAINT chk_trail_progress_percentage CHECK (completion_percentage BETWEEN 0 AND 100)
);

CREATE TABLE content_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    content_id BIGINT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at DATETIME(6),
    CONSTRAINT uk_content_progress_student_content UNIQUE (student_id, content_id),
    CONSTRAINT fk_content_progress_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_content_progress_content FOREIGN KEY (content_id) REFERENCES contents(id)
);

-- Historico tecnico. Os triggers abaixo apenas auditam mudancas; eles nao
-- concedem XP nem executam regras de gamificacao pertencentes ao backend.
CREATE TABLE content_progress_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    content_progress_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    content_id BIGINT NOT NULL,
    old_completed BOOLEAN,
    new_completed BOOLEAN NOT NULL,
    operation_type VARCHAR(20) NOT NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    changed_by VARCHAR(255) NOT NULL
);


-- ============================================================================
-- FEATURE: NOTIFICACOES
-- ============================================================================

CREATE TABLE notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    author_id BIGINT,
    target_class VARCHAR(255),
    created_at DATETIME(6),
    CONSTRAINT fk_notifications_author FOREIGN KEY (author_id) REFERENCES teachers(id)
);

CREATE TABLE notification_reads (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    notification_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    read_at DATETIME(6) NOT NULL,
    CONSTRAINT uk_notification_read UNIQUE (notification_id, student_id),
    CONSTRAINT fk_notification_reads_notification
        FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_reads_student
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);


-- ============================================================================
-- VIEWS: CONSULTAS CONSOLIDADAS POR FEATURE
-- ============================================================================

-- FEATURE: PROGRESSO
-- Compara o percentual persistido com o percentual calculado a partir dos
-- conteudos existentes. Isso ajuda a identificar progresso desatualizado.
CREATE OR REPLACE VIEW vw_student_trail_progress AS
SELECT
    tp.student_id,
    u.name AS student_name,
    s.registration,
    s.classroom,
    tp.trail_id,
    t.title AS trail_title,
    COUNT(DISTINCT c.id) AS total_contents,
    COUNT(DISTINCT CASE WHEN cp.completed = TRUE THEN c.id END) AS completed_contents,
    CASE
        WHEN COUNT(DISTINCT c.id) = 0 THEN 0
        ELSE FLOOR(
            COUNT(DISTINCT CASE WHEN cp.completed = TRUE THEN c.id END)
            * 100.0 / COUNT(DISTINCT c.id)
        )
    END AS calculated_percentage,
    tp.completion_percentage AS stored_percentage,
    tp.completed,
    tp.started_at,
    tp.last_activity
FROM trail_progress tp
JOIN students s ON s.id = tp.student_id
JOIN users u ON u.id = s.user_id
JOIN trails t ON t.id = tp.trail_id
LEFT JOIN modules m ON m.trail_id = t.id
LEFT JOIN contents c ON c.module_id = m.id
LEFT JOIN content_progress cp
    ON cp.student_id = tp.student_id
   AND cp.content_id = c.id
GROUP BY
    tp.student_id,
    u.name,
    s.registration,
    s.classroom,
    tp.trail_id,
    t.title,
    tp.completion_percentage,
    tp.completed,
    tp.started_at,
    tp.last_activity;

-- FEATURE: GAMIFICACAO
-- DENSE_RANK mantem estudantes empatados na mesma colocacao.
CREATE OR REPLACE VIEW vw_weekly_ranking AS
SELECT
    xw.year,
    xw.number_week,
    xw.start_week,
    xw.student_id,
    u.name AS student_name,
    s.registration,
    s.classroom,
    COALESCE(xw.xp_gained, 0) AS xp_gained,
    DENSE_RANK() OVER (
        PARTITION BY xw.year, xw.number_week
        ORDER BY COALESCE(xw.xp_gained, 0) DESC
    ) AS ranking_position
FROM xp_weekly xw
JOIN students s ON s.id = xw.student_id
JOIN users u ON u.id = s.user_id;

-- FEATURE: NOTIFICACOES
CREATE OR REPLACE VIEW vw_notification_statistics AS
SELECT
    n.id AS notification_id,
    n.title,
    n.type,
    n.target_class,
    n.author_id,
    u.name AS author_name,
    n.created_at,
    COUNT(nr.id) AS read_count
FROM notifications n
LEFT JOIN teachers t ON t.id = n.author_id
LEFT JOIN users u ON u.id = t.user_id
LEFT JOIN notification_reads nr ON nr.notification_id = n.id
GROUP BY
    n.id,
    n.title,
    n.type,
    n.target_class,
    n.author_id,
    u.name,
    n.created_at;


-- ============================================================================
-- TRIGGERS: AUDITORIA DO PROGRESSO
-- ============================================================================

DELIMITER $$

CREATE TRIGGER trg_content_progress_after_insert
AFTER INSERT ON content_progress
FOR EACH ROW
BEGIN
    INSERT INTO content_progress_audit (
        content_progress_id,
        student_id,
        content_id,
        old_completed,
        new_completed,
        operation_type,
        changed_at,
        changed_by
    ) VALUES (
        NEW.id,
        NEW.student_id,
        NEW.content_id,
        NULL,
        NEW.completed,
        'INSERT',
        CURRENT_TIMESTAMP(6),
        CURRENT_USER()
    );
END$$

CREATE TRIGGER trg_content_progress_after_update
AFTER UPDATE ON content_progress
FOR EACH ROW
BEGIN
    IF NOT (OLD.completed <=> NEW.completed) THEN
        INSERT INTO content_progress_audit (
            content_progress_id,
            student_id,
            content_id,
            old_completed,
            new_completed,
            operation_type,
            changed_at,
            changed_by
        ) VALUES (
            NEW.id,
            NEW.student_id,
            NEW.content_id,
            OLD.completed,
            NEW.completed,
            'UPDATE',
            CURRENT_TIMESTAMP(6),
            CURRENT_USER()
        );
    END IF;
END$$

DELIMITER ;


-- ============================================================================
-- STORED PROCEDURES: MANUTENCAO DO PROGRESSO
-- ============================================================================

DELIMITER $$

-- Recalcula uma unica combinacao estudante/trilha com operacoes em conjunto.
-- A procedure nao concede XP para que uma manutencao nao gere recompensas
-- duplicadas. A concessao de XP continua na camada de servico da aplicacao.
CREATE PROCEDURE sp_recalculate_trail_progress (
    IN p_student_id BIGINT,
    IN p_trail_id BIGINT
)
BEGIN
    DECLARE v_total_contents BIGINT DEFAULT 0;
    DECLARE v_completed_contents BIGINT DEFAULT 0;
    DECLARE v_percentage INT DEFAULT 0;

    IF NOT EXISTS (SELECT 1 FROM students WHERE id = p_student_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estudante nao encontrado';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM trails WHERE id = p_trail_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Trilha nao encontrada';
    END IF;

    SELECT COUNT(c.id)
        INTO v_total_contents
        FROM modules m
        JOIN contents c ON c.module_id = m.id
    WHERE m.trail_id = p_trail_id;

    SELECT COUNT(DISTINCT cp.content_id)
        INTO v_completed_contents
        FROM content_progress cp
        JOIN contents c ON c.id = cp.content_id
        JOIN modules m ON m.id = c.module_id
    WHERE cp.student_id = p_student_id
        AND m.trail_id = p_trail_id
        AND cp.completed = TRUE;

    SET v_percentage = CASE
        WHEN v_total_contents = 0 THEN 0
        ELSE FLOOR(v_completed_contents * 100.0 / v_total_contents)
    END;

    INSERT INTO trail_progress (
        student_id,
        trail_id,
        completion_percentage,
        xp_gained,
        completed,
        started_at,
        last_activity
    ) 
    VALUES (
        p_student_id,
        p_trail_id,
        v_percentage,
        0,
        v_percentage = 100,
        CURRENT_TIMESTAMP(6),
        CURRENT_TIMESTAMP(6)
    )
    ON DUPLICATE KEY UPDATE
        completion_percentage = v_percentage,
        completed = (v_percentage = 100),
        last_activity = CURRENT_TIMESTAMP(6);
END$$

-- Exemplo intencional de CURSOR: rotina administrativa que percorre apenas
-- pares estudante/trilha que ja possuem progresso ou conteudo concluido.
-- Para operacoes frequentes da API, prefira SQL em conjunto e os services Java.
CREATE PROCEDURE sp_rebuild_all_trail_progress ()
BEGIN
    DECLARE v_done BOOLEAN DEFAULT FALSE;
    DECLARE v_student_id BIGINT;
    DECLARE v_trail_id BIGINT;

    DECLARE progress_cursor CURSOR FOR
        SELECT pairs.student_id, pairs.trail_id
            FROM (
                SELECT tp.student_id, tp.trail_id
                    FROM trail_progress tp
                UNION
                SELECT cp.student_id, m.trail_id
                    FROM content_progress cp
                    JOIN contents c ON c.id = cp.content_id
                    JOIN modules m ON m.id = c.module_id
                WHERE cp.completed = TRUE
            ) AS pairs
        ORDER BY pairs.student_id, pairs.trail_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN progress_cursor;

    progress_loop: LOOP
        FETCH progress_cursor INTO v_student_id, v_trail_id;

        IF v_done THEN
            LEAVE progress_loop;
        END IF;

        CALL sp_recalculate_trail_progress(v_student_id, v_trail_id);
    END LOOP;

    CLOSE progress_cursor;
END$$

-- Procedure de consulta parametrizada para consumidores que nao desejem
-- consultar a view diretamente.
CREATE PROCEDURE sp_get_weekly_ranking (
    IN p_year INT,
    IN p_number_week INT,
    IN p_classroom VARCHAR(255)
)
BEGIN
    SELECT
        ranking_position,
        student_id,
        student_name,
        registration,
        classroom,
        xp_gained,
        start_week
    FROM vw_weekly_ranking
    WHERE year = p_year
        AND number_week = p_number_week
        AND (p_classroom IS NULL OR classroom = p_classroom)
    ORDER BY ranking_position, student_name;
END$$

DELIMITER ;


-- ============================================================================
-- EXEMPLOS DE USO (DESCOMENTE PARA TESTAR)
-- ============================================================================

-- SELECT * FROM vw_student_trail_progress;
-- SELECT * FROM vw_weekly_ranking WHERE year = 2026 AND number_week = 36;
-- SELECT * FROM vw_notification_statistics;
-- SELECT * FROM content_progress_audit ORDER BY changed_at DESC;

-- CALL sp_recalculate_trail_progress(1, 1);
-- CALL sp_rebuild_all_trail_progress();
-- CALL sp_get_weekly_ranking(2026, 36, NULL);
