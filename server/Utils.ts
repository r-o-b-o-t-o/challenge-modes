import Config from "./Config";

export default class Utils {
	public static formatPlayedTime(seconds: number): string {
		const d = Math.floor(seconds / (3600 * 24));
		const h = Math.floor(seconds % (3600 * 24) / 3600);
		const m = Math.floor(seconds % 3600 / 60);

		const days = d > 0 ? d + "d " : "";
		const hours = h > 0 ? h + "h " : "";
		const minutes = m + "m";
		return days + hours + minutes;
	}

	public static notifyInstallAddon(player: Player, outdatedPatch: boolean = false) {
		let msg: string;
		if (outdatedPatch) {
			msg = "A newer version of the Challenge Modes patch is available.";
		} else {
			msg = "You need to install the AIO addon and the Challenge Modes patch to use this feature.";
		}
		if (Config.instance.downloadUrl?.length > 0) {
			msg += "\nVisit " + Config.instance.downloadUrl;
		}
		player.SendNotification(msg);
	}
}
