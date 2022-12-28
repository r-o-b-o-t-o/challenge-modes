export class Database {
	public static getRowsFromQuery(res: ElunaQuery): any[] {
		if (!res) {
			return [];
		}

		const rows = [];
		for (let i = 0; i < res.GetRowCount(); ++i) {
			rows.push(res.GetRow());
			res.NextRow();
		}

		return rows;
	}
}
