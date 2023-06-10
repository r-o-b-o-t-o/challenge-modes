import Config from "../Config";
import Database from "./Database";

export default class AccountData {
	public account: number;
	public tokens: number;

	public constructor(account: number, tokens: number) {
		this.account = account;
		this.tokens = tokens;
	}

	public save(cb?: () => void): void {
		CharDBQueryAsync(`
			INSERT INTO ${AccountData.table()} (account, tokens)
			VALUES
				(${this.account}, ${this.tokens})
			ON DUPLICATE KEY UPDATE
				account = ${this.account},
				tokens = ${this.tokens}
		`, () => {
			cb?.();
		});
	}

	public static get(account: number, cb: (data: AccountData) => void) {
		CharDBQueryAsync(`
			SELECT account, tokens
			FROM ${AccountData.table()}
			WHERE account = ${account}
		`, (res) => {
			const rows = Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
			cb?.(rows[0]);
		});
	}

	public static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_account_data`;
	}

	public static createFromRow(row: any): AccountData {
		return new AccountData(row.account, row.tokens);
	}
}
