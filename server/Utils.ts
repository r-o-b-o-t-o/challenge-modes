import Config from "./Config";
import { Date } from "./date";

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

	public static testRegex(str: string, pattern: string): boolean {
		const res = string.match(str, pattern);
		if (!res) {
			return false;
		}
		return res.length > 0;
	}

	public static getPathSeparator(): string {
		return string.sub(_G.package.config, 1, 1);
	}

	public static getOS(): "win" | "unix" {
		return this.getPathSeparator() === "\\" ? "win" : "unix";
	}

	public static isPathAbsolute(path: string): boolean {
		if (this.getOS() === "win") {
			return this.testRegex(path, "^[a-zA-Z]:[\\/]");
		}
		return path.startsWith("/");
	}

	public static formatDate(date: Date, separator = "-"): string {
		const month = (date.month + 1).toString().padStart(2, "0");
		const day = date.mday.toString().padStart(2, "0");
		return `${date.year}${separator}${month}${separator}${day}`;
	}
}
