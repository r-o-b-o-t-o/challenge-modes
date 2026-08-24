SET @exists := (
    SELECT COUNT(*)
        FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'challenge_modes_character'
        AND INDEX_NAME = 'idx_challenge_modes_character_name'
);

SET @sql := IF(@exists > 0,
    'SELECT ''Index already present; nothing to do.'' AS result',
    'CREATE INDEX `idx_challenge_modes_character_name` ON `challenge_modes_character` (`name`)');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
