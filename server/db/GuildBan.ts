import Config from "../Config";
import Database from "./Database";

export default class GuildBan {
	public guild: number;
	public account: number;

	public constructor(guild: number, account: number) {
		this.guild = guild;
		this.account = tonumber(tostring(account)); // id can be userdata, force convert to number
	}

	public save(): void {
		CharDBExecute(`
			INSERT INTO ${GuildBan.table()} (guild, account)
			VALUES
				(${this.guild}, ${this.account})
			ON DUPLICATE KEY UPDATE
				guild = ${this.guild},
				account = ${this.account}
		`);
	}

	public static getAll(): GuildBan[] {
		const res = CharDBQuery(`
			SELECT guild, account
			FROM ${GuildBan.table()}
		`);
		return Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
	}

	public static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_guild_ban`;
	}

	public static createFromRow(row: any): GuildBan {
		return new GuildBan(row.guild, row.account);
	}
}
