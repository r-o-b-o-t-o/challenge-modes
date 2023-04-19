export type PlayerMapKey = number | Player | string;

export default class GuidSet {
	private readonly set: LuaSet<string>; // Key: GUID converted to string

	public constructor() {
		this.set = new LuaSet<string>();
	}

	private getKey(player: PlayerMapKey): string {
		if (typeof player === "string") {
			return player;
		}
		if (typeof player === "number") {
			return player.toString();
		}
		if (player.GetGUID !== undefined) {
			return player.GetGUID().toString();
		}
		return (player as any).toString(); // Userdata
	}

	public add(player: PlayerMapKey) {
		return this.set.add(this.getKey(player));
	}

	public has(player: PlayerMapKey) {
		return this.set.has(this.getKey(player));
	}

	public delete(player: PlayerMapKey) {
		return this.set.delete(this.getKey(player));
	}

	public keys() {
		const keys: string[] = [];
		for (const [key, _] of this.set) {
			keys.push(key);
		}
		return keys;
	}
}
