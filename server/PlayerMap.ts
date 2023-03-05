export type PlayerMapKey = number | Player | string;

export default class PlayerMap<T> {
	private readonly map: LuaMap<string, T>; // Key: character's GUID converted to string

	public constructor() {
		this.map = new LuaMap<string, T>();
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

	public get(player: PlayerMapKey) {
		return this.map.get(this.getKey(player));
	}

	public set(player: PlayerMapKey, value: T) {
		return this.map.set(this.getKey(player), value);
	}

	public has(player: PlayerMapKey) {
		return this.map.has(this.getKey(player));
	}

	public delete(player: PlayerMapKey) {
		return this.map.delete(this.getKey(player));
	}

	public keys() {
		const keys: string[] = [];
		for (const [key, _] of this.map) {
			keys.push(key);
		}
		return keys;
	}
}
