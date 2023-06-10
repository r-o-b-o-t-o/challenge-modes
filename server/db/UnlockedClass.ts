import Config from "../Config";
import Database from "./Database";

export default class UnlockedClass {
	public account: number;
	public class: number;

	public constructor(account: number, classId: number) {
		this.account = account;
		this.class = classId;
	}

	public save(cb?: () => void): void {
		CharDBQueryAsync(`
			INSERT INTO ${UnlockedClass.table()} (account, class)
			VALUES
				(${this.account}, ${this.class})
			ON DUPLICATE KEY UPDATE
				account = ${this.account},
				class = ${this.class}
		`, () => {
			cb?.();
		});
	}

	public static get(account: number, cb: (classIds: number[]) => void) {
		CharDBQueryAsync(`
			SELECT account, class
			FROM ${UnlockedClass.table()}
			WHERE account = ${account}
		`, (res) => {
			const rows = Database.getRowsFromQuery(res).map(row => this.createFromRow(row));
			cb?.(rows.map(row => row.class));
		});
	}

	public static table(): string {
		return `${Config.instance.elunaDatabase}.challenge_modes_rewards_unlocked_class`;
	}

	public static createFromRow(row: any): UnlockedClass {
		return new UnlockedClass(row.account, row.class);
	}
}
