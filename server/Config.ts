import * as json from "./lib/json";

export default class Config {
	public static instance: Config;

	public channelName: string;
	public maxLevel: number;
	public elunaDatabase: string;
	public announcePermanentDeaths: boolean;
	public announcePermanentDeathsMinLevel: number;
	public downloadUrl: string;
	public hallOfFameMaxResults: number;
	public shrineBuffs: number[];
	public shrineBuffChangeTime: number;
	public rewards: { [key: string]: { [key: string]: number[] } };
	public rewardsSender: number | null;

	public static read(): void {
		const [file, err, errCode] = io.open(this.getDirectory() + "/../config.json", "r");
		if (file === undefined) {
			error("Could not open config file: " + err);
		}

		const contents = file.read("*a");
		file.close();

		if (contents === undefined) {
			error("Reading config file returned null value");
		}
		this.instance = json.decode(contents) as Config;
	}

	private static getDirectory(): string {
		const info = debug.getinfo(2, "S");
		if (info === undefined) {
			error("Config: debug.getinfo() is undefined");
		}
		const curFile: string = (info.source || "").substring(1);
		const split = curFile.split("/");
		if (split.length === 1) {
			return ".";
		}

		split.pop();
		return split.join("/");
	}
}
