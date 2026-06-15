import Utils from "./Utils";
import Config from "./Config";
import PlayerMap from "./PlayerMap";

const AIO = require("AIO") as Aio;

interface IPlayerUsingGobj {
	gobj: number;
	map: number;
	responseReceived: boolean;
}

export default class ChallengeGameObject {
	private players: PlayerMap<IPlayerUsingGobj>;
	private range: number;

	public constructor(range: number, closeMessage: string) {
		this.range = range;
		this.players = new PlayerMap<IPlayerUsingGobj>();

		CreateLuaEvent(() => {
			for (const key of this.players.keys()) {
				const player = GetPlayerByGUID(tonumber(key));
				if (player === undefined || !this.isPlayerInRange(player)) {
					this.players.delete(key);
					if (player !== undefined) {
						AIO.Handle(player, Config.instance.channelName, closeMessage);
					}
				}
			}
		}, 5000, 0);
	}

	public use(gobj: GameObject, player: Player) {
		const guid = player.GetGUID();
		if (this.players.has(guid)) {
			return;
		}

		this.players.set(guid, {
			gobj: gobj.GetGUID(),
			map: gobj.GetMapId(),
			responseReceived: false,
		});

		CreateLuaEvent(() => {
			const player = GetPlayerByGUID(guid);
			if (player && this.players.get(player)?.responseReceived === false) {
				Utils.notifyInstallAddon(player);
				this.close(player);
			}
		}, 500);
	}

	public close(player: Player) {
		this.players.delete(player);
	}

	public responseReceived(player: Player) {
		const obj = this.players.get(player);
		if (obj) {
			obj.responseReceived = true;
		}
	}

	public isPlayerInRange(player: Player): boolean {
		const obj = this.players.get(player);
		if (!obj) {
			return false;
		}

		const map = GetMapById(obj.map);
		const gobj = map?.GetWorldObject(obj.gobj);
		if (gobj === undefined) {
			return false;
		}
		return player.IsInRange(gobj, 0, this.range);
	}
}
