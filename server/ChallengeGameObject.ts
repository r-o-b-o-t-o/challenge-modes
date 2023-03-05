import Utils from "./Utils";
import Config from "./Config";

const AIO = require("AIO") as Aio;

interface IPlayerUsingGobj {
	gobj: number;
	player: number;
	map: number;
	responseReceived: boolean;
}

export default class ChallengeGameObject {
	private players: IPlayerUsingGobj[];
	private range: number;

	public constructor(range: number, closeMessage: string) {
		this.range = range;
		this.players = [];

		CreateLuaEvent(() => {
			for (let i = this.players.length - 1; i >= 0; --i) {
				const obj = this.players[i];
				const player = GetPlayerByGUID(obj.player);
				if (player === undefined || !this.isPlayerInRange(player)) {
					this.players.splice(i, 1);
					if (player !== undefined) {
						AIO.Handle(player, Config.instance.channelName, closeMessage);
					}
				}
			}
		}, 5000, 0);
	}

	public use(gobj: GameObject, player: Player) {
		const guid = player.GetGUID();
		if (this.players.some(obj => obj.player === guid)) {
			return;
		}

		this.players.push({
			gobj: gobj.GetGUID(),
			player: guid,
			map: gobj.GetMapId(),
			responseReceived: false,
		});

		CreateLuaEvent(() => {
			const player = GetPlayerByGUID(guid);
			const obj = this.players.find(obj => obj.player === guid);
			if (player && obj?.responseReceived === false) {
				Utils.notifyInstallAddon(player);
				this.close(player);
			}
		}, 500);
	}

	public close(player: Player) {
		const idx = this.players.findIndex(obj => obj.player === player.GetGUID());
		if (idx !== -1) {
			this.players.splice(idx, 1);
		}
	}

	public responseReceived(player: Player) {
		const obj = this.players.find(obj => obj.player === player.GetGUID());
		obj.responseReceived = true;
	}

	public isPlayerInRange(player: Player): boolean {
		const obj = this.players.find(obj => obj.player === player.GetGUID());
		if (obj === undefined) {
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
