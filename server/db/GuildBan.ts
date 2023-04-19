import Config from "../Config";
import Database from "./Database";

export default class GuildBan {
	public account: number;

	public constructor(guid: number) {
		this.account = tonumber(tostring(guid)); // id can be userdata, force convert to number
	}

	public save(): void {
		CharDBExecute(`
			INSERT INTO ${GuildBan.table()} (account)
			VALUES
				(${this.account})
			ON DUPLICATE KEY UPDATE
				account = ${this.account}
		`);
	}

	public static getAll(): GuildBan[] {
		const res = CharDBQuery(`
			SELECT account
			FROM ${GuildBan.table()}
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	public static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_guild_ban`;
	}

	public static createFromRow(row: any): GuildBan {
		return new GuildBan(row.account);
	}
}
