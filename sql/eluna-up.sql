CREATE TABLE `challenge_modes_character` (
	`guid` int(10) UNSIGNED NOT NULL,
	`name` varchar(12) NOT NULL,
	`challenge` int(11) NOT NULL COMMENT 'Bitmask, Hardcore = 1 / Ironman = 2 / Bloodthirsty = 4',
	`completed` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Did this character win the challenge',
	`dead` tinyint(1) NOT NULL DEFAULT 0,
	`died_level` int(11) UNSIGNED DEFAULT NULL,
	`died_on` int(11) UNSIGNED DEFAULT NULL,
	`char_deleted` tinyint(1) NOT NULL DEFAULT 0,
	`played_time` int(11) UNSIGNED DEFAULT NULL
);

ALTER TABLE `challenge_modes_character` ADD PRIMARY KEY (`guid`);
