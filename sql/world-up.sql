INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2000000,	4,	5651,	'Challenge Banner',	'',	'',	'',	1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	'',	'',	0),
(2000001,	4,	5652,	'Challenge Banner',	'',	'',	'',	1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	'',	'',	0),
(2000002,	4,	6944,	'Hero Shrine',	'',	'',	'',	1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	'',	'',	0),
(2000003,	4,	6,	'Hero Shrine',	'',	'',	'',	1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	'',	'',	0);

INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`) VALUES
(3301000, 2000000, 0, 0, 0, 1, 1, -8923.42, -150.462, 81.3038, 2.09107, -0, -0, -0.865193, -0.501439, 300, 0, 1, '', NULL), -- Northshire (Elwynn Forest)
(3301001, 2000000, 0, 0, 0, 1, 1, -6212.58, 330.028, 383.855, 3.0917, -0, -0, -0.999689, -0.024946, 300, 0, 1, '', NULL), -- Coldridge Valley (Dun Morogh)
(3301002, 2000000, 1, 0, 0, 1, 1, 10304.4, 826.646, 1326.99, 6.24235, -0, -0, -0.0204149, 0.999792, 300, 0, 1, '', NULL), -- Shadowglen (Teldrassil)
(3301003, 2000000, 530, 0, 0, 1, 1, -3959.9, -13915.4, 101.206, 3.18874, -0, -0, -0.999722, 0.0235698, 300, 0, 1, '', NULL), -- Ammen Vale (Azuremyst Isle)
(3301004, 2000001, 1, 0, 0, 1, 1, -641.453, -4249.13, 38.1633, 6.11507, -0, -0, -0.0839589, 0.996469, 300, 0, 1, '', NULL), -- Valley of Trials (Durotar)
(3301005, 2000001, 1, 0, 0, 1, 1, -2947.89, -245.954, 53.3611, 5.40119, -0, -0, -0.426842, 0.904326, 300, 0, 1, '', NULL), -- Camp Narache (Mulgore)
(3301006, 2000001, 0, 0, 0, 1, 1, 1670.2, 1663.47, 120.719, 2.35949, -0, -0, -0.924509, -0.38116, 300, 0, 1, '', NULL), -- Deathknell (Tirisfal Glades)
(3301007, 2000001, 530, 0, 0, 1, 1, 10338.7, -6384.63, 36.326, 2.01457, -0, -0, -0.845384, -0.534159, 300, 0, 1, '', NULL); -- Sunstrider Isle (Eversong Woods)
