import { Config } from "../Config";
import { Database } from "./Database";
import { EChallengeMode } from "../ChallengeModes";

export class Character {
	public guid: number;
	public name: string;
	public challenge: EChallengeMode;
	public completed: boolean;
	public dead: boolean;
	public diedLevel: number;
	public diedOn: number;

	public constructor(guid: number, name: string, challenge: EChallengeMode, completed = false, dead = false, diedLevel?: number, diedOn?: number) {
		this.guid = guid;
		this.name = name;
		this.challenge = challenge;
		this.completed = completed;
		this.dead = dead;
		this.diedLevel = diedLevel;
		this.diedOn = diedOn;
	}

	public save(): void {
		CharDBExecute(`
			INSERT INTO ${Character.table()} (guid, name, challenge, completed, dead, died_level, died_on)
			VALUES
				(${this.guid}, "${this.name}", ${this.challenge}, ${this.completed ? 1 : 0}, ${this.dead ? 1 : 0}, ${this.diedLevel ?? "NULL"}, ${this.diedOn ?? "NULL"})
			ON DUPLICATE KEY UPDATE
				guid = ${this.guid}, name = "${this.name}", challenge = ${this.challenge}, completed = ${this.completed ? 1 : 0},
				dead = ${this.dead ? 1 : 0}, died_level = ${this.diedLevel ?? "NULL"}, died_on = ${this.diedOn ?? "NULL"}
		`);
	}

	public print(): void {
		print(`guid: ${this.guid}, name: "${this.name}", challenge: ${this.challenge}, completed: ${this.completed ? 1 : 0}, dead: ${this.dead ? 1 : 0}, diedLevel: ${this.diedLevel ?? "null"}, diedOn: ${this.diedOn ?? "null"}`);
	}

	public static getAll(): Character[] {
		const res = CharDBQuery(`
			SELECT guid, name, challenge, completed, dead, died_level, died_on
			FROM ${Character.table()}
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	public static getAllAlive(): Character[] {
		const res = CharDBQuery(`
			SELECT guid, name, challenge, completed, dead, died_level, died_on
			FROM ${Character.table()}
			WHERE dead = 0
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	private static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_character`;
	}

	private static createFromRow(row: any): Character {
		return new Character(row.guid, row.name, row.challenge, row.completed === 1, row.dead === 1, row.died_level, row.died_on);
	}
}
