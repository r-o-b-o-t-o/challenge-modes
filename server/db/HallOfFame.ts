import Config from "../Config";
import Database from "./Database";
import Character from "./Character";
import TokenBucket from "../TokenBucket";

interface IHallOfFameRequest {
	player: number;
	challenge: number;
	completed: boolean;
	failed: boolean;
	active: boolean;
	myChars: boolean;
	account: number;
	offset: number;
	callback: (data: IHallOfFameData) => void;
	delayed?: boolean;
}

interface IHallOfFameRow {
	n: string; // Name
	r: number; // Rank
	s: number; // State (Active = 0, Dead = 1, Completed = 2)
	c: number; // Class
	l: number; // Level
	a: number; // Account (1 for current player's account, 0 otherwise)
}

interface IHallOfFameData {
	rows: IHallOfFameRow[];
	totalRows: number;
	maxResults: number;
}

export default class HallOfFame {
	private readonly requestBucket: TokenBucket;

	public constructor() {
		this.requestBucket = new TokenBucket(5, 1, 1000); // 5 initial tokens, refills 1 token every second
	}

	public fetch(req: IHallOfFameRequest) {
		if (!this.requestBucket.take(req.player)) {
			if (req.delayed !== true) {
				this.requestBucket.runAfterRefill(() => this.fetch(req));
				req.delayed = true;
			}
			return;
		}

		const stateFilters = [req.completed ? "completed = 1" : "", req.failed ? "dead = 1" : "", req.active ? "(completed = 0 AND dead = 0)" : ""]
			.filter(part => part !== "")
			.join(" OR ");
		const filter = `
			(${stateFilters !== "" ? stateFilters : "0"}) AND
			(${req.myChars ? `account = ${req.account}` : "1"})
		`;

		const res = CharDBQuery(`
			SELECT * FROM (
				SELECT
					account, name, class, level, completed, dead,
					RANK() OVER (ORDER BY completed DESC, level DESC, played_time ASC) ranking
				FROM ${Character.table()}
				WHERE challenge = ${req.challenge}
			) t
			WHERE ${filter}
			ORDER BY ranking ASC
			LIMIT ${Config.instance.hallOfFameMaxResults}
			OFFSET ${req.offset}
		`);
		const rows = Database.getRowsFromQuery(res).map(row => this.createFromRow(row, req.account));

		const countRes = CharDBQuery(`
			SELECT COUNT(guid) AS c
			FROM ${Character.table()}
			WHERE challenge = ${req.challenge} AND (${filter})
		`);
		const totalRows = Database.getRowsFromQuery(countRes)[0].c;

		req.callback({
			rows,
			totalRows,
			maxResults: Config.instance.hallOfFameMaxResults,
		});
	}

	private createFromRow(row: any, account: number): IHallOfFameRow {
		return {
			n: row.name,
			r: row.ranking,
			s: row.completed === 1 ? 2 : (row.dead === 1 ? 1 : 0), // Active = 0, Dead = 1, Completed = 2
			c: row.class,
			l: row.level,
			a: row.account === account ? 1 : 0,
		};
	}
}
