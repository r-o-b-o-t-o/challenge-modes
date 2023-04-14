import Config from "../Config";
import Database from "./Database";
import { allChallengeModes, EChallengeMode } from "../EChallengeMode";

export default class Character {
	public guid: number;
	public account: number;
	public name: string;
	public race: number;
	public class: number;
	public gender: number;
	public level: number;
	public challenge: EChallengeMode;
	public completed: boolean;
	public dead: boolean;
	public diedOn: number;
	public charDeleted: boolean;
	public playedTime: number;

	public constructor(guid: number, account: number, name: string, race: number, _class: number, gender: number, level: number, challenge: EChallengeMode, completed = false, dead = false, diedOn?: number, charDeleted = false, playedTime = null) {
		this.guid = tonumber(tostring(guid)); // guid can be userdata, force convert to number
		this.account = account;
		this.name = name;
		this.race = race;
		this.class = _class;
		this.gender = gender;
		this.level = level;
		this.challenge = challenge;
		this.completed = completed;
		this.dead = dead;
		this.diedOn = diedOn;
		this.charDeleted = charDeleted;
		this.playedTime = playedTime;
	}

	public isHardcore(): boolean {
		return this.hasChallenge(EChallengeMode.Hardcore);
	}

	public isIronman(): boolean {
		return this.hasChallenge(EChallengeMode.Ironman);
	}

	public isBloodthirsty(): boolean {
		return this.hasChallenge(EChallengeMode.Bloodthirsty);
	}

	public hasChallenge(challenge: EChallengeMode): boolean {
		return bit32.band(this.challenge, challenge) === challenge;
	}

	public addChallenge(challenge: EChallengeMode) {
		this.challenge = bit32.bor(this.challenge, challenge);
	}

	public removeChallenge(challenge: EChallengeMode) {
		this.challenge = bit32.band(this.challenge, bit32.bnot(challenge));
	}

	public getChallengesArray() {
		return allChallengeModes()
			.filter(challenge => this.hasChallenge(challenge))
			.map(challenge => EChallengeMode[challenge]);
	}

	public formatChallenges(): string {
		const challenges = this.getChallengesArray();
		return challenges.join(" + ");
	}

	public save(): void {
		CharDBExecute(`
			INSERT INTO ${Character.table()} (guid, account, name, race, class, gender, level, challenge, completed, dead, died_on, char_deleted, played_time)
			VALUES
				(${this.guid}, ${this.account}, "${this.name}", ${this.race}, ${this.class}, ${this.gender}, ${this.level}, ${this.challenge},
				${this.completed ? 1 : 0}, ${this.dead ? 1 : 0}, ${this.diedOn ?? "NULL"}, ${this.charDeleted ? 1 : 0}, ${this.playedTime ?? "NULL"})
			ON DUPLICATE KEY UPDATE
				guid = ${this.guid}, account = ${this.account}, name = "${this.name}", race = ${this.race}, class = ${this.class}, gender = ${this.gender},
				level = ${this.level}, challenge = ${this.challenge}, completed = ${this.completed ? 1 : 0}, dead = ${this.dead ? 1 : 0},
				died_on = ${this.diedOn ?? "NULL"}, char_deleted = ${this.charDeleted ? 1 : 0}, played_time = ${this.playedTime ?? "NULL"}
		`);
	}

	public getRank(cb: (rank: number) => void) {
		CharDBQueryAsync(`
			SELECT ranking FROM (
				SELECT
					guid,
					RANK() OVER (ORDER BY completed DESC, level DESC, played_time ASC) ranking
				FROM ${Character.table()}
				WHERE challenge = ${this.challenge}
			) t
			WHERE guid = ${this.guid}
		`, (res) => {
			const rows = Database.getRowsFromQuery(res);
			cb?.(rows.length > 0 ? rows[0].ranking : -1);
		});
	}

	public updateCharacterData(player: Player) {
		this.name = player.GetName();
		this.race = player.GetRace();
		this.gender = player.GetGender();
		this.level = player.GetLevel();
	}

	public static getAllActive(): Character[] {
		const res = CharDBQuery(`
			SELECT ch.guid, ch.account, ch.name, ch.race, ch.class, ch.gender, ch.level, ch.challenge, ch.completed, ch.dead, ch.died_on, ch.char_deleted, ch.played_time
			FROM ${Character.table()} ch
			INNER JOIN acore_characters.characters ON characters.guid = ch.guid
			WHERE
				completed = 0 AND
				(dead = 0 OR char_deleted = 0) AND
				characters.deleteInfos_Account IS NULL;
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	public static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_character`;
	}

	public static formatChallenges(challenge: EChallengeMode): string {
		const challenges = allChallengeModes()
			.filter(c => bit32.band(challenge, c) === c)
			.map(c => EChallengeMode[c]);
		return challenges.join(" + ");
	}

	private static createFromRow(row: any): Character {
		return new Character(row.guid, row.account, row.name, row.race, row.class, row.gender, row.level, row.challenge, row.completed === 1, row.dead === 1, row.died_on, row.char_deleted === 1, row.played_time);
	}
}
