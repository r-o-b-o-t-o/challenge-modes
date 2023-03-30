import Utils from "./Utils";
import Config from "./Config";
import PlayerMap from "./PlayerMap";
import Character from "./db/Character";
import HallOfFame from "./db/HallOfFame";
import { timestampToDate } from "./date";
import ChallengeGameObject from "./ChallengeGameObject";
import { allChallengeModes, EChallengeMode } from "./EChallengeMode";

const AIO = require("AIO") as Aio;

class ChallengeModes {
	private readonly addonVersion = "1.0.0";

	// Constants
	private readonly ACHIEVEMENT_CRITERIA_DEATHS = 111;
	private readonly MSG_AUCTION_HELLO = 0x255;
	private readonly CMSG_AUCTION_SELL_ITEM = 0x256;
	private readonly CMSG_AUCTION_PLACE_BID = 0x25A;
	private readonly CMSG_GUILD_BANKER_ACTIVATE = 0x3E6;
	private readonly CMSG_GUILD_BANK_SWAP_ITEMS = 0x3E9;
	private readonly CMSG_GUILD_BANK_DEPOSIT_MONEY = 0x3EC;
	private readonly CMSG_GUILD_BANK_WITHDRAW_MONEY = 0x3ED;

	// Ids
	private readonly allianceGobjEntry = 2000000;
	private readonly hordeGobjEntry = 2000001;
	private readonly allianceShrineGobjEntry = 2000002;
	private readonly hordeShrineGobjEntry = 2000003;
	private readonly hofGobjEntry = 2000004;
	private readonly startingGear = [38, 39, 40, 49778, 6948, 45, 43, 44, 2361, 49, 47, 48, 28979, 2092, 50055, 6098, 52, 53, 51, 35, 34652, 34655, 34659, 34650, 34653, 34649, 34651, 34656, 34648, 34657, 34658, 38145, 38147, 41751, 40582, 56, 1395, 55, 6096, 57, 6097, 1396, 59, 6125, 139, 140, 12282, 127, 6126, 6127, 2101, 2504, 2512, 2105, 120, 121, 25861, 154, 153, 36, 2362, 6129, 6117, 6118, 148, 147, 129, 2102, 2508, 2516, 6116, 159, 4540, 6120, 6121, 6122, 3661, 6119, 6123, 6124, 6144, 6140, 6139, 6136, 6137, 6138, 6134, 6135, 24143, 24145, 24146, 23346, 20901, 20899, 20900, 20980, 20982, 20897, 20896, 20898, 50057, 20891, 20978, 20893, 20894, 20895, 20892, 23473, 23474, 23475, 23476, 23477, 23345, 23344, 23348, 23347, 23322, 23478, 23479];
	private readonly startingGearQuantities = { 2512: 200, 2516: 200, 38145: 4, 41751: 10 };

	private readonly hallOfFame: HallOfFame;
	private readonly bannerGobj: ChallengeGameObject;
	private readonly hallOfFameGobj: ChallengeGameObject;
	private characters: PlayerMap<Character>; // Key: character's GUID converted to string
	private shrineBuff: number;

	public constructor() {
		AIO.AddHandlers(Config.instance.channelName, {
			/** @noSelf **/ enlist: (...args: [Player, EChallengeMode]) => this.enlist(...args),
			/** @noSelf **/ openBannerUI: (...args: [Player]) => this.openBannerUI(...args),
			/** @noSelf **/ closeBannerUI: (...args: [Player]) => this.closeBannerUI(...args),
			/** @noSelf **/ openHallOfFameUI: (...args: [Player]) => this.openHallOfFameUI(...args),
			/** @noSelf **/ closeHallOfFameUI: (...args: [Player]) => this.closeHallOfFameUI(...args),
			/** @noSelf **/ notifyInstallAddon: (...args: [Player, boolean]) => Utils.notifyInstallAddon(...args),
			/** @noSelf **/ hallOfFameData: (...args: [Player, number, boolean, boolean, boolean, boolean, number]) => this.hallOfFameData(...args),
		});

		this.pickRandomShrineBuff();
		CreateLuaEvent(() => this.pickRandomShrineBuff(), Config.instance.shrineBuffChangeTime * 1000, 0);

		this.hallOfFame = new HallOfFame();
		this.bannerGobj = new ChallengeGameObject(15, "CloseBannerUI");
		this.hallOfFameGobj = new ChallengeGameObject(15, "CloseHallOfFameUI");
		this.loadCharacters();
		this.registerBannerEvents();
		this.registerPlayerEvents();
		this.registerPacketEvents();
	}

	private checkEligible(player: Player) {
		// Check level and xp
		if (player.GetLevel() > 1 || player.GetXP() > 0) {
			return "EXP";
		}

		// Check for items
		let items: { [key: number]: number } = {};
		const checkItems = (bag: number, slotStart: number, slotEnd: number) => {
			for (let slot = slotStart; slot <= slotEnd; ++slot) {
				const item = player.GetItemByPos(bag, slot);
				if (item) {
					const entry = item.GetEntry();
					const count = item.GetCount() + (items[entry] || 0);

					if (!this.startingGear.includes(entry) || count > (this.startingGearQuantities[entry] || 1)) {
						// Illegal item or too many instances of allowed item
						return false;
					}

					items[entry] = count;
				}
			}
			return true;
		};
		if (!checkItems(255, 0, 117)) {
			// Check equipment, bag slots, items in backpack, bank slots, keyring
			return "ITEMS";
		}
		for (let bag = 19; bag <= 22; ++bag) {
			// Check for items in equipped bags
			if (!checkItems(bag, 0, 35)) {
				return "ITEMS";
			}
		}

		// Check for money
		if (player.GetCoinage() > 0) {
			return "MONEY";
		}

		// Check for previous deaths from the achievements' stats
		const deaths = player.GetAchievementCriteriaProgress(this.ACHIEVEMENT_CRITERIA_DEATHS);
		if (deaths !== undefined && deaths > 0) {
			return "DEATHS";
		}

		// Check for pending mails
		if (player.GetMailCount() > 0) {
			return "MAIL";
		}

		// Make sure the player is still in range from the banner
		if (!this.bannerGobj.isPlayerInRange(player)) {
			return "RANGE";
		}

		return true;
	}

	private loadCharacters() {
		this.characters = new PlayerMap<Character>();

		for (const char of Character.getAllActive()) {
			this.characters.set(char.guid, char);
		}
	}

	private registerBannerEvents() {
		RegisterGameObjectEvent(this.allianceGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onAllianceBannerUse(...args));
		RegisterGameObjectEvent(this.hordeGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onHordeBannerUse(...args));
		RegisterGameObjectEvent(this.allianceShrineGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onShrineUse(...args));
		RegisterGameObjectEvent(this.hordeShrineGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onShrineUse(...args));
		RegisterGameObjectEvent(this.hofGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onHallOfFameUse(...args));
	}

	private registerPlayerEvents() {
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_LOGIN, (...args) => this.onPlayerLogin(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_REPOP, (...args) => this.onPlayerRepop(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_RESURRECT, (...args) => this.onPlayerResurrect(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_GIVE_XP, (...args) => this.onPlayerGiveXP(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CAN_INIT_TRADE, (...args) => this.onPlayerTrade(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CAN_USE_ITEM, (...args) => this.onPlayerCanUseItem(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_LEARN_TALENTS, (...args) => this.onPlayerLearnTalent(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_LEVEL_CHANGE, (...args) => this.onPlayerChangeLevel(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CAN_SEND_MAIL, (...args) => this.onPlayerSendMail(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CAN_JOIN_LFG, (...args) => this.onPlayerQueueRdf(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_KILLED_BY_CREATURE, (...args) => this.onPlayerKilledByCreature(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_KILL_PLAYER, (...args) => this.onPlayerPvPKilled(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CAN_GROUP_INVITE, (...args) => this.onPlayerCanGroupInvite(...args));
	}

	private registerPacketEvents() {
		const opcodes = [
			this.MSG_AUCTION_HELLO, this.CMSG_AUCTION_SELL_ITEM, this.CMSG_AUCTION_PLACE_BID,
			this.CMSG_GUILD_BANKER_ACTIVATE, this.CMSG_GUILD_BANK_SWAP_ITEMS, this.CMSG_GUILD_BANK_DEPOSIT_MONEY, this.CMSG_GUILD_BANK_WITHDRAW_MONEY,
		];
		for (const opcode of opcodes) {
			RegisterPacketEvent(opcode, PacketEvents.PACKET_EVENT_ON_PACKET_RECEIVE, (...args) => this.cancelPacket(...args));
		}
	}

	private onAllianceBannerUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		if (player.IsAlliance()) {
			this.onBannerUse(gobj, player);
		}

		return false;
	}

	private onHordeBannerUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		if (player.IsHorde()) {
			this.onBannerUse(gobj, player);
		}

		return false;
	}

	private onBannerUse(gobj: GameObject, player: Player) {
		const char = this.getCharacter(player);

		this.bannerGobj.use(gobj, player);

		const eligible = this.checkEligible(player);
		const eligibilityArray = allChallengeModes().map(challenge => char?.hasChallenge(challenge) ? "CHALLENGEACTIVE" : eligible);
		AIO.Handle(player, Config.instance.channelName, "OpenBannerUI", this.addonVersion, eligibilityArray);
	}

	private onShrineUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		player.PerformEmote(16); // Kneel
		const effectAura = 55845;

		if (Config.instance.shrineBuffs?.length > 0 && this.isPlayerEnlisted(player)) {
			const guid = player.GetGUID();
			CreateLuaEvent(() => {
				const player = GetPlayerByGUID(guid);
				if (player && !Config.instance.shrineBuffs.some(aura => player.HasAura(aura))) {
					player.AddAura(effectAura, player);
					player.AddAura(this.shrineBuff, player);
				}
			}, 1200);
			CreateLuaEvent(() => GetPlayerByGUID(guid)?.RemoveAura(effectAura), 2200);
		}

		return true;
	}

	private pickRandomShrineBuff() {
		this.shrineBuff = Config.instance.shrineBuffs[Math.floor(Math.random() * Config.instance.shrineBuffs.length)];
	}

	private onHallOfFameUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		this.hallOfFameGobj.use(gobj, player);
		AIO.Handle(player, Config.instance.channelName, "OpenHallOfFameUI", this.addonVersion, Config.instance.hallOfFameMaxResults);
		return true;
	}

	private hallOfFameData(player: Player, challenge: EChallengeMode, completed: boolean, failed: boolean, active: boolean, myChars: boolean, offset: number) {
		if (!this.hallOfFameGobj.isPlayerInRange(player)) {
			return;
		}

		const guid = player.GetGUID();
		this.hallOfFame.fetch({
			player: guid, challenge, completed, failed, active, myChars, account: player.GetAccountId(), offset,
			callback: ({ rows, totalRows }) => {
				const player = GetPlayerByGUID(guid);
				if (player) {
					AIO.Handle(player, Config.instance.channelName, "HallOfFameData", rows, totalRows);
				}
			}
		});
	}

	private onPlayerLogin(event: PlayerEvents, player: Player) {
		if (this.isPlayerEnlisted(player)) {
			AIO.Handle(player, Config.instance.channelName, "CheckAddonVersion", this.addonVersion);
		}
	}

	private onPlayerRepop(event: PlayerEvents, player: Player) {
		if (!this.isPlayerEnlisted(player)) {
			return;
		}

		const char = this.getCharacter(player);
		if (!char.isHardcore()) {
			return;
		}

		// When the player releases spirit (PLAYER_EVENT_ON_REPOP), force them to resurrect.
		// This will call onPlayerResurrect which handles the character's deletion.
		player.ResurrectPlayer(1, false);
	}

	private onPlayerResurrect(event: PlayerEvents, player: Player) {
		if (!this.isPlayerEnlisted(player)) {
			return;
		}

		const char = this.getCharacter(player);
		if (!char.isHardcore()) {
			return;
		}

		char.updateCharacterData(player);
		char.charDeleted = true;
		char.save();
		this.characters.delete(player);

		this.log("Deleting character", player);
		RunCommand(`ban character ${player.GetName()} -1 Challenge Mode Death`);
		CreateLuaEvent(() => {
			CharDBExecute(`
				UPDATE characters
				SET deleteInfos_Name = name, deleteInfos_Account = account, deleteDate = UNIX_TIMESTAMP(), name = "", account = 0
				WHERE guid = ${char.guid}
			`);
			RunCommand(`cache delete ${char.name}`);
		}, 3000); // Wait for a few seconds, otherwise the name gets written again since the char data is saved when the player is disconnected
	}

	private onPlayerGiveXP(event: PlayerEvents, player: Player, amount: number, victim: Unit): number {
		if (this.isPlayerEnlisted(player)) {
			const char = this.getCharacter(player);
			if (char.isBloodthirsty() && (victim === null || victim.ToPlayer() !== null)) {
				return 0;
			}
		}
		return amount;
	}

	private onPlayerTrade(event: PlayerEvents, player: Player, target: Player): boolean {
		const a = this.getCharacter(player);
		const b = this.getCharacter(target);
		const res = a?.challenge === b?.challenge;
		if (!res) {
			if (a) {
				player.SendNotification(`You can only trade with other ${a.formatChallenges()} players.`);
			} else {
				player.SendNotification(`You cannot trade with ${b.formatChallenges()} players.`);
			}
		}
		return res;
	}

	private onPlayerCanUseItem(event: PlayerEvents, player: Player, itemEntry: number): InventoryResult {
		const character = this.getCharacter(player);
		const itemTemplate = GetItemTemplate(itemEntry);
		if (character?.isIronman() && itemTemplate?.GetQuality() > 1) {
			// Prevent using items better than Common in Ironman mode
			return InventoryResult.EQUIP_ERR_CANT_DO_RIGHT_NOW;
		}

		return InventoryResult.EQUIP_ERR_OK;
	}

	private onPlayerLearnTalent(event: PlayerEvents, player: Player, talent: number, rank: number, spell: number) {
		const character = this.getCharacter(player);
		if (character?.isIronman()) {
			// Reset talents instantly for Ironman players if they try to use their points
			player.ResetTalents(true);
		}
	}

	private onPlayerChangeLevel(event: PlayerEvents, player: Player, oldLevel: number) {
		if (!this.isPlayerEnlisted(player)) {
			return;
		}

		const char = this.getCharacter(player);
		char.updateCharacterData(player);
		char.playedTime = player.GetTotalPlayedTime();

		if (player.GetLevel() >= Config.instance.maxLevel) {
			this.log(`Challenge ${char.formatChallenges()} completed`, GetPlayerByGUID(char.guid));
			char.completed = true;
			this.characters.delete(player);
			// char.save() is async, and we need the char to be saved in order to compute the rank correctly,
			// so we wait for a few seconds before sending the results
			CreateLuaEvent(() => this.onPlayerCompletedChallenge(char), 3000);
		}

		char.save();
	}

	private onPlayerCompletedChallenge(char: Character) {
		this.sendRewards(char);
		this.openCompletedUI(char);
	}

	private openCompletedUI(char: Character) {
		const player = GetPlayerByGUID(char.guid);
		if (!player) {
			return;
		}

		if (player.IsInCombat()) {
			CreateLuaEvent(() => this.openCompletedUI(char), 1000);
			return;
		}

		AIO.Handle(player, Config.instance.channelName, "OpenCompletedUI", char.formatChallenges(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), char.getRank());
	}

	private sendRewards(char: Character) {
		const body = "";
		const classRewards = Config.instance.rewards[char.class.toString()];
		if (!classRewards) {
			return;
		}

		const player = GetPlayerByGUID(char.guid);

		for (let challengeStr in classRewards) {
			const challenge = parseInt(challengeStr);
			if (char.hasChallenge(challenge)) {
				const items = classRewards[challengeStr];
				if (items.length > 0) {
					const values = items.map(item => [item, 1]).flat();
					SendMail(Character.formatChallenges(challenge) + " Challenge Rewards", body, char.guid, Config.instance.rewardsSender ?? 0, MailStationery.MAIL_STATIONERY_GM, 0, 0, 0, ...values);
					this.log(`Sent rewards for ${Character.formatChallenges(challenge)}`, player);
				}
			}
		}
	}

	private onPlayerSendMail(event: PlayerEvents, player: Player, receiverGuid: number, mailbox: number, subject: string, body: string, money: number, cod: number, item: Item): boolean {
		if (this.characters.has(receiverGuid) && (money > 0 || item !== null)) {
			// Prevent from sending the mail if the target character is running a challenge and the mail contains money or items
			return false;
		}
		if (this.isPlayerEnlisted(player) && cod > 0) {
			// Prevent the player from getting money from CODs if they're running a challenge
			return false;
		}

		return true;
	}

	private onPlayerQueueRdf(event: PlayerEvents, player: Player, roles: number, dungeons: number[], comment: string): boolean {
		if (!this.isPlayerEnlisted(player)) {
			return true;
		}

		const char = this.getCharacter(player);

		if (!player.IsInGroup()) {
			player.SendNotification("You cannot queue alone on a Challenge character.");
			return false;
		}

		const group = player.GetGroup();
		if (group.GetMembersCount() !== 5) {
			player.SendNotification("You can only queue with a full group of 5 players running the same Challenges.");
			return false;
		}

		for (const member of group.GetMembers()) {
			const memberChar = this.getCharacter(member);

			if (memberChar?.challenge !== char.challenge) {
				// Shouldn't be possible because of the group invite check, but better safe than sorry
				player.SendNotification(`You can only queue with other ${char.formatChallenges()} players.`);
				return false;
			}
		}

		return true;
	}

	private onPlayerKilledByCreature(event: PlayerEvents, killer: Unit, player: Player) {
		if (!this.isPlayerEnlisted(player)) {
			return;
		}

		const char = this.getCharacter(player);
		if (!char.isHardcore()) {
			return;
		}

		if (Config.instance.announcePermanentDeaths) {
			SendWorldMessage(`${player.GetName()} was killed by ${killer.GetName()} at level ${player.GetLevel()} (${char.formatChallenges()} Challenge).`);
		}
		this.onPlayerDied(player);
	}

	private onPlayerPvPKilled(event: PlayerEvents, killer: Player, killed: Player) {
		if (!this.isPlayerEnlisted(killed)) {
			return;
		}

		const char = this.getCharacter(killed);
		if (!char.isHardcore()) {
			return;
		}

		if (Config.instance.announcePermanentDeaths) {
			if (killer.GetGUID() === killed.GetGUID()) {
				SendWorldMessage(`${killed.GetName()} died at level ${killed.GetLevel()} (${char.formatChallenges()} Challenge).`);
			} else {
				SendWorldMessage(`${killed.GetName()} was killed by player ${killer.GetName()} at level ${killed.GetLevel()} (${char.formatChallenges()} Challenge).`);
			}
		}

		this.onPlayerDied(killed);
	}

	private onPlayerDied(player: Player) {
		this.log("Died", player);
		const char = this.getCharacter(player);
		char.dead = true;
		char.updateCharacterData(player);
		char.diedOn = GetGameTime();
		char.save();

		AIO.Handle(player, Config.instance.channelName, "OpenDeathUI", char.formatChallenges(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), char.getRank());
	}

	private onPlayerCanGroupInvite(event: PlayerEvents, player: Player, newMemberName: string): boolean {
		// Prevent inviting if the new member has a different set of challenges

		const newMember = GetPlayerByName(newMemberName);
		if (!newMember) {
			return true;
		}

		const char = this.getCharacter(player);
		const newMemberChar = this.getCharacter(newMember);
		let canInvite = newMemberChar?.challenge === char?.challenge;

		const group = player.GetGroup();
		if (canInvite && group !== null) {
			for (const member of group.GetMembers()) {
				const memberCharacter = this.getCharacter(member);
				if (newMemberChar?.challenge !== memberCharacter?.challenge) {
					canInvite = false;
					break;
				}
			}
		}

		if (!canInvite) {
			if (char) {
				player.SendNotification(`You can only party up with ${char.formatChallenges()} players.`);
			} else {
				player.SendNotification("You cannot party up with players running Challenge Modes.");
			}
			return false;
		}

		return true;
	}

	private cancelPacket(event: PacketEvents, packet: WorldPacket, player: Player): boolean {
		return !this.isPlayerEnlisted(player);
	}

	private enlist(player: Player, challenge: EChallengeMode) {
		AIO.Handle(player, Config.instance.channelName, "CloseBannerUI");

		if (!allChallengeModes().includes(challenge)) {
			// Invalid challenge id
			return;
		}

		let char = this.getCharacter(player);
		if (char?.hasChallenge(challenge)) {
			player.SendNotification(`You are already enlisted for the ${EChallengeMode[challenge]} challenge.`);
			return;
		}

		if (this.checkEligible(player) !== true) {
			player.SendNotification(`Could not enable the ${EChallengeMode[challenge]} challenge.`);
			return;
		}

		if (!char) {
			char = new Character(player.GetGUID(), player.GetAccountId(), player.GetName(), player.GetRace(), player.GetClass(), player.GetGender(), player.GetLevel(), challenge);
			this.characters.set(player, char);
		} else {
			char.addChallenge(challenge);
		}
		char.save();
		this.log(`Enlisted for ${Character.formatChallenges(challenge)}`, player);

		AIO.Handle(player, Config.instance.channelName, "Enlisted", EChallengeMode[challenge]);

		if (player.IsInGroup()) {
			// Remove from group
			const group = player.GetGroup();
			group.RemoveMember(player.GetGUID(), RemoveMethod.GROUP_REMOVEMETHOD_LEAVE);
		}
	}

	private openBannerUI(player: Player) {
		this.bannerGobj.responseReceived(player);
	}

	private closeBannerUI(player: Player) {
		this.bannerGobj.close(player);
	}

	private openHallOfFameUI(player: Player) {
		this.hallOfFameGobj.responseReceived(player);
	}

	private closeHallOfFameUI(player: Player) {
		this.hallOfFameGobj.close(player);
	}

	private isPlayerEnlisted(player: Player): boolean {
		return this.characters.has(player);
	}

	private getCharacter(player: Player): Character {
		return this.characters.get(player);
	}

	private log(text: string, player?: Player) {
		const [dir] = string.match(debug.getinfo(1).source, "@?(.*/)");
		const [f, _, __] = io.open(dir + "/challengemodes.log", "a");
		if (!f) {
			return;
		}

		const date = timestampToDate(parseInt(GetGameTime() + ""));
		const playerStr = player != undefined ? ` [${player.GetName()} (${player.GetGUID()})]` : "";
		f.write(`[${date.year}-${date.month + 1}-${date.mday} ${date.hour}:${date.min}:${date.sec} UTC]${playerStr} ${text}\n`);
		f.close();
	}
}

Config.read();
new ChallengeModes();
