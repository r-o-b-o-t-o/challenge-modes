import PlayerMap, { PlayerMapKey } from "./PlayerMap";

export default class TokenBucket {
	private size: number;
	private refillAmount: number;
	private bucket: PlayerMap<number>;
	private onAfterRefill: Function[];

	public constructor(size: number, refillAmount: number, refillInterval: number) {
		this.size = size;
		this.refillAmount = refillAmount;
		this.bucket = new PlayerMap<number>();
		this.onAfterRefill = [];
		CreateLuaEvent(() => this.refill(), refillInterval, 0);
	}

	public take(player: PlayerMapKey): boolean {
		const amount = this.count(player);

		if (amount > 0) {
			this.bucket.set(player, amount - 1);
			return true;
		}

		return false;
	}

	public runAfterRefill(cb: Function) {
		this.onAfterRefill.push(cb);
	}

	private count(player: PlayerMapKey) {
		if (!this.bucket.has(player)) {
			return this.size;
		}
		return this.bucket.get(player);
	}

	private refill() {
		const keys = this.bucket.keys();
		if (keys.length === 0) {
			return;
		}

		for (const key of keys) {
			const newAmount = this.count(key) + this.refillAmount;
			if (newAmount >= this.size) {
				this.bucket.delete(key);
			} else {
				this.bucket.set(key, newAmount);
			}
		}

		for (const cb of this.onAfterRefill) {
			cb();
		}
		this.onAfterRefill.length = 0;
	}
}
