CREATE TABLE `challenge_modes_character` (
	`guid` INT UNSIGNED NOT NULL,
	`account` INT UNSIGNED NOT NULL,
	`name` varchar(12) NOT NULL,
	`race` TINYINT UNSIGNED NOT NULL,
	`class` TINYINT UNSIGNED NOT NULL,
	`gender` TINYINT UNSIGNED NOT NULL,
	`level` TINYINT UNSIGNED DEFAULT NULL,
	`challenge` TINYINT NOT NULL COMMENT 'Bitmask, Hardcore = 1 / Ironman = 2 / Bloodthirsty = 4',
	`completed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Did this character win the challenge',
	`dead` TINYINT UNSIGNED NOT NULL DEFAULT 0,
	`died_on` INT UNSIGNED DEFAULT NULL,
	`char_deleted` TINYINT UNSIGNED NOT NULL DEFAULT 0,
	`played_time` INT UNSIGNED DEFAULT NULL
);

ALTER TABLE `challenge_modes_character` ADD PRIMARY KEY (`guid`);
