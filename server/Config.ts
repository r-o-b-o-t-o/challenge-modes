import * as json from "./lib/json";

export default class Config {
	public static instance: Config;

	public channelName: string;
	public maxLevel: number;
	public authDatabase: string;
	public charactersDatabase: string;
	public elunaDatabase: string;
	public announcePermanentDeaths: boolean;
	public announcePermanentDeathsMinLevel: number;
	public announceCompletions: boolean;
	public downloadUrl: string;
	public markerAuras: { [key: string]: number };
	public hallOfFameMaxResults: number;
	public shrineBuffs: number[];
	public shrineBuffChangeTime: number;
	public rewards: { [key: string]: { [key: string]: number[] } };
	public rewardsStore: {
		items: { [key: string]: number[] };
		classRestrictions: { [key: string]: number[] };
		costs: { [key: string]: number };
	};
	public rewardsSender: number | null;
	public logging: {
		directory: string;
		enlisted: boolean;
		died: boolean;
		deleting: boolean;
		completed: boolean;
		rewards: boolean;
		mobTagging: boolean | number;
		manualDelete: boolean;
		rewardsStore: boolean;
	};
	public broadcasts: string[];
	public broadcastFrequency: number;
	public guildNames: string[];
	public guildRanks: { [key: string]: number };

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
