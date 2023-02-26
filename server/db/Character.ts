import { Config } from "../Config";
import { Database } from "./Database";
import { allChallengeModes, EChallengeMode } from "../EChallengeMode";

export class Character {
	public guid: number;
	public name: string;
	public challenge: EChallengeMode;
	public completed: boolean;
	public dead: boolean;
	public diedLevel: number;
	public diedOn: number;
	public charDeleted: boolean;
	public playedTime: number;

	public constructor(guid: number, name: string, challenge: EChallengeMode, completed = false, dead = false, diedLevel?: number, diedOn?: number, charDeleted = false, playedTime = null) {
		this.guid = guid;
		this.name = name;
		this.challenge = challenge;
		this.completed = completed;
		this.dead = dead;
		this.diedLevel = diedLevel;
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

	public formatChallenges(): string {
		const challenges = allChallengeModes()
			.map(challenge => this.hasChallenge(challenge) ? EChallengeMode[challenge] : "")
			.filter(str => str !== "");
		return challenges.join(" + ");
	}

	public save(): void {
		CharDBExecute(`
			INSERT INTO ${Character.table()} (guid, name, challenge, completed, dead, died_level, died_on, char_deleted)
			VALUES
				(${this.guid}, "${this.name}", ${this.challenge}, ${this.completed ? 1 : 0}, ${this.dead ? 1 : 0}, ${this.diedLevel ?? "NULL"}, ${this.diedOn ?? "NULL"}, ${this.charDeleted ? 1 : 0})
			ON DUPLICATE KEY UPDATE
				guid = ${this.guid}, name = "${this.name}", challenge = ${this.challenge}, completed = ${this.completed ? 1 : 0},
				dead = ${this.dead ? 1 : 0}, died_level = ${this.diedLevel ?? "NULL"}, died_on = ${this.diedOn ?? "NULL"},
				char_deleted = ${this.charDeleted ? 1 : 0}, played_time = ${this.playedTime ?? "NULL"}
		`);
	}

	public getRank(): number {
		const res = CharDBQuery(`
			SELECT COUNT(guid) + 1 AS ranking FROM ${Character.table()}
			WHERE
				guid <> ${this.guid} AND challenge = ${this.challenge} AND
				(
					completed = 1 OR
					(
						dead = 1 AND
						(
							died_level > ${this.diedLevel} OR
							(died_level = ${this.diedLevel} AND played_time < ${this.playedTime})
						)
					)
				)
		`);
		const rows = Database.getRowsFromQuery(res);
		return rows.length > 0 ? rows[0].ranking : -1;
	}

	public print(): void {
		print(`guid: ${this.guid}, name: "${this.name}", challenge: ${this.challenge}, completed: ${this.completed ? 1 : 0}, dead: ${this.dead ? 1 : 0}, diedLevel: ${this.diedLevel ?? "null"}, diedOn: ${this.diedOn ?? "null"}, charDeleted: ${this.charDeleted ? 1 : 0}, playedTime: ${this.playedTime ?? "null"}`);
	}

	public static getAllActive(): Character[] {
		const res = CharDBQuery(`
			SELECT guid, name, challenge, completed, dead, died_level, died_on, char_deleted, played_time
			FROM ${Character.table()}
			WHERE
				completed = 0 AND
				(dead = 0 OR char_deleted = 0)
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	private static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_character`;
	}

	private static createFromRow(row: any): Character {
		return new Character(row.guid, row.name, row.challenge, row.completed === 1, row.dead === 1, row.died_level, row.died_on, row.char_deleted === 1, row.played_time);
	}
}
