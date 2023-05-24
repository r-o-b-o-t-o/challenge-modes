import Utils from "./Utils";
import Areas from "./Areas";
import Config from "./Config";
import GuidSet from "./GuidSet";
import PlayerMap from "./PlayerMap";
import Database from "./db/Database";
import GuildBan from "./db/GuildBan";
import Character from "./db/Character";
import HallOfFame from "./db/HallOfFame";
import ChallengeGameObject from "./ChallengeGameObject";
import { Date, dateToTimestamp, timestampToDate } from "./date";
import { allChallengeModes, EChallengeMode } from "./EChallengeMode";

const AIO = require("AIO") as Aio;

class ChallengeModes {
	private readonly addonVersion = "1.0.4";

	// Constants
	private readonly ACHIEVEMENT_CRITERIA_DEATHS = 111;
	private readonly MSG_AUCTION_HELLO = 0x255;
	private readonly CMSG_AUCTION_SELL_ITEM = 0x256;
	private readonly CMSG_AUCTION_PLACE_BID = 0x25A;
	private readonly CMSG_GUILD_BANKER_ACTIVATE = 0x3E6;
	private readonly CMSG_GUILD_BANK_SWAP_ITEMS = 0x3E9;
	private readonly CMSG_GUILD_BANK_DEPOSIT_MONEY = 0x3EC;
	private readonly CMSG_GUILD_BANK_WITHDRAW_MONEY = 0x3ED;
	private readonly CMSG_PET_LEARN_TALENT = 0x47A;
	private readonly CMSG_LEARN_PREVIEW_TALENTS_PET = 0x4C2;
	private readonly CMSG_ACCEPT_TRADE = 0x11A;
	private readonly PLAYER_FIELD_VENDORBUYBACK_SLOT_1 = 472;
	private readonly PLAYER_FIELD_BUYBACK_PRICE_1 = 1201;
	private readonly PLAYER_FIELD_BUYBACK_TIMESTAMP_1 = 1213;

	private readonly settingsWeekendXpSource = "mod-double-xp-weekend";
	private readonly settingsWeekendXpDisable = 1;

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
	private characters: PlayerMap<Character>;
	private guildBans: GuidSet;
	private mobTaggingCounter: PlayerMap<{ value: number; taggers: string[]; cancelId?: number; }>;
	private shrineBuff: number;
	private broadcastIdx: number;

	public constructor() {
		AIO.AddHandlers(Config.instance.channelName, {
			/** @noSelf **/ enlist: (...args: [Player, EChallengeMode]) => this.enlist(...args),
			/** @noSelf **/ openBannerUI: (...args: [Player]) => this.openBannerUI(...args),
			/** @noSelf **/ closeBannerUI: (...args: [Player]) => this.closeBannerUI(...args),
			/** @noSelf **/ openHallOfFameUI: (...args: [Player]) => this.openHallOfFameUI(...args),
			/** @noSelf **/ closeHallOfFameUI: (...args: [Player]) => this.closeHallOfFameUI(...args),
			/** @noSelf **/ notifyInstallAddon: (...args: [Player, boolean]) => Utils.notifyInstallAddon(...args),
			/** @noSelf **/ hallOfFameData: (...args: [Player, number, boolean, boolean, boolean, boolean, boolean, number[], number]) => this.hallOfFameData(...args),
		});

		this.pickRandomShrineBuff(true);
		this.broadcastIdx = 0;
		CreateLuaEvent(() => this.broadcast(), Config.instance.broadcastFrequency * 1000, 0);

		this.hallOfFame = new HallOfFame();
		this.bannerGobj = new ChallengeGameObject(15, "CloseBannerUI");
		this.hallOfFameGobj = new ChallengeGameObject(15, "CloseHallOfFameUI");
		this.mobTaggingCounter = new PlayerMap();
		this.loadCharacters();
		this.registerBannerEvents();
		this.registerPlayerEvents();
		this.registerPacketEvents();

		_G.ChallengeModes = this;
	}

	private checkEligible(player: Player, cb: (eligible: true | "Exp" | "Items" | "Money" | "Deaths" | "Mail" | "Range") => void): void {
		// Check level and xp
		if (player.GetLevel() > 1 || player.GetXP() > 0) {
			return cb("Exp");
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

					for (let enchSlot = 0; enchSlot <= 6; ++enchSlot) {
						if (item.GetEnchantmentId(enchSlot) !== 0) {
							return false;
						}
					}

					items[entry] = count;
				}
			}
			return true;
		};
		if (!checkItems(255, 0, 117)) {
			// Check equipment, bag slots, items in backpack, bank slots, keyring
			return cb("Items");
		}
		for (let bag = 19; bag <= 22; ++bag) {
			// Check for items in equipped bags
			if (!checkItems(bag, 0, 35)) {
				return cb("Items");
			}
		}

		// Check for money
		if (player.GetCoinage() > 0) {
			return cb("Money");
		}

		// Check for previous deaths from the achievements' stats
		const deaths = player.GetAchievementCriteriaProgress(this.ACHIEVEMENT_CRITERIA_DEATHS);
		if (deaths !== undefined && deaths > 0) {
			return cb("Deaths");
		}

		// Check for pending mails
		if (player.GetMailCount() > 0) {
			return cb("Mail");
		}

		const guid = player.GetGUID();
		// Prevent getting money from COD mails
		CharDBQueryAsync(`SELECT COUNT(id) AS c FROM mail WHERE sender = ${player.GetGUID()}`, (res) => {
			const player = GetPlayerByGUID(guid);
			if (!player) {
				return;
			}

			const rows = Database.getRowsFromQuery(res);
			if (rows.length > 0 && rows[0].c > 0) {
				return cb("Mail");
			}

			// Make sure the player is still in range from the banner
			if (!this.bannerGobj.isPlayerInRange(player)) {
				return cb("Range");
			}

			cb(true);
		});
	}

	private loadCharacters() {
		this.characters = new PlayerMap<Character>();
		this.guildBans = new GuidSet();

		for (const char of Character.getAllActive()) {
			this.characters.set(char.guid, char);
		}
		for (const ban of GuildBan.getAll()) {
			this.guildBans.add(ban.account);
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
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_SPELL_CAST, (...args) => this.onPlayerCastSpell(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_COMMAND, (...args) => this.onCommand(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_CHARACTER_DELETE, (...args) => this.onCharacterDeleted(...args));
	}

	private registerPacketEvents() {
		const opcodes = [
			this.MSG_AUCTION_HELLO, this.CMSG_AUCTION_SELL_ITEM, this.CMSG_AUCTION_PLACE_BID,
			this.CMSG_GUILD_BANKER_ACTIVATE, this.CMSG_GUILD_BANK_SWAP_ITEMS, this.CMSG_GUILD_BANK_DEPOSIT_MONEY, this.CMSG_GUILD_BANK_WITHDRAW_MONEY,
		];
		for (const opcode of opcodes) {
			RegisterPacketEvent(opcode, PacketEvents.PACKET_EVENT_ON_PACKET_RECEIVE, (...args) => this.cancelPacket(...args));
		}
		RegisterPacketEvent(this.CMSG_PET_LEARN_TALENT, PacketEvents.PACKET_EVENT_ON_PACKET_RECEIVE, (...args) => this.onPetLearnTalent(...args));
		RegisterPacketEvent(this.CMSG_LEARN_PREVIEW_TALENTS_PET, PacketEvents.PACKET_EVENT_ON_PACKET_RECEIVE, (...args) => this.onPetLearnTalent(...args));
		RegisterPacketEvent(this.CMSG_ACCEPT_TRADE, PacketEvents.PACKET_EVENT_ON_PACKET_RECEIVE, (...args) => this.onAcceptTrade(...args));
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

		const guid = player.GetGUID();
		this.checkEligible(player, (eligible) => {
			const player = GetPlayerByGUID(guid);
			if (player) {
				const eligibilityArray = allChallengeModes().map(challenge => char?.hasChallenge(challenge) ? "ChallengeActive" : eligible);
				AIO.Handle(player, Config.instance.channelName, "OpenBannerUI", this.addonVersion, eligibilityArray);
			}
		});
	}

	private onShrineUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		player.PerformEmote(16); // Kneel

		if (Config.instance.shrineBuffs?.length > 0 && this.isPlayerEnlisted(player)) {
			const effectAura = 55845;
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

	private pickRandomShrineBuff(firstRun = false) {
		const prevBuff = this.shrineBuff;
		do {
			this.shrineBuff = Config.instance.shrineBuffs[Math.floor(Math.random() * Config.instance.shrineBuffs.length)];
		} while (this.shrineBuff === prevBuff);
		this.log("Changed shrine buff");

		let nextBuffIn = Config.instance.shrineBuffChangeTime;
		if (firstRun) {
			// Find when to run the first switch to a different buff, starting from a "round hour"
			// e.g., if it's 09:15 AM and shrineBuffChangeTime is 600 (= 10 minutes) then the change will happen at 09:20, then 09:30, 09:40, etc
			const now = this.getCurrentDate();
			let t = { ...now }; // Create a copy of the object
			t.min = 0;
			t.sec = 0;
			while (dateToTimestamp(t) <= dateToTimestamp(now)) {
				t = timestampToDate(dateToTimestamp(t) + Config.instance.shrineBuffChangeTime);
			}
			nextBuffIn = dateToTimestamp(t) - dateToTimestamp(now);
		}
		CreateLuaEvent(() => this.pickRandomShrineBuff(), nextBuffIn * 1_000);
	}

	private broadcast() {
		if (Config.instance.broadcasts.length === 0) {
			return;
		}

		const str = Config.instance.broadcasts[this.broadcastIdx];
		++this.broadcastIdx;
		if (this.broadcastIdx >= Config.instance.broadcasts.length) {
			this.broadcastIdx = 0;
		}

		for (const key of this.characters.keys()) {
			const char = this.characters.get(key);
			const player = GetPlayerByGUID(char.guid);
			if (player !== null) {
				player.SendBroadcastMessage(str);
			}
		}
	}

	private onHallOfFameUse(event: GameObjectEvents, gobj: GameObject, player: Player) {
		this.hallOfFameGobj.use(gobj, player);
		AIO.Handle(player, Config.instance.channelName, "OpenHallOfFameUI", this.addonVersion, Config.instance.hallOfFameMaxResults);
		return true;
	}

	private hallOfFameData(player: Player, challenge: EChallengeMode, completed: boolean, failed: boolean, active: boolean, myChars: boolean, solo: boolean, classes: number[], offset: number) {
		if (!this.hallOfFameGobj.isPlayerInRange(player)) {
			return;
		}

		const guid = player.GetGUID();
		this.hallOfFame.fetch({
			player: guid, challenge, completed, failed, active, myChars, solo, classes, account: player.GetAccountId(), offset,
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

			const char = this.getCharacter(player);
			for (const key in Config.instance.markerAuras) {
				const challenge = parseInt(key);
				if (char.hasChallenge(challenge) && !player.HasAura(Config.instance.markerAuras[key])) {
					player.AddAura(Config.instance.markerAuras[key], player);
				}
			}

			if (char.isIronman()) {
				const guid = player.GetGUID();
				CreateLuaEvent(() => {
					const player = GetPlayerByGUID(guid);
					player?.ResetTalents();
					player?.ResetPetTalents();
				}, 10_000);
			}

			player.UpdatePlayerSetting(this.settingsWeekendXpSource, this.settingsWeekendXpDisable, 1);

			if (char.level < player.GetLevel()) {
				// Refresh in case of desync, forces rewards to be sent if a character
				// dinged to max level while the script was disabled
				this.onPlayerChangeLevel(null, player, char.level);
			}
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

		if (!player.IsDead()) {
			// The repop event may be called when the player is not dead, for example
			// when you are teleported to the nearest graveyard when disbanding in a dungeon.
			// Return to prevent deleting characters in these cases.
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

		if (Config.instance.logging.deleting) {
			this.log("Deleting character", player);
		}

		if (player.IsInGuild()) {
			const guild = player.GetGuild();
			guild.DeleteMember(player, false);
		}

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

	private onPlayerGiveXP(event: PlayerEvents, player: Player, amount: number, victim: Unit, source: number): number {
		if (!this.isPlayerEnlisted(player)) {
			return amount;
		}

		if (victim) {
			// Prevent mob-tagging power-leveling
			const attackers = victim.GetAttackers();
			const threatList = victim.GetThreatList() ?? [];
			const units = [...attackers, ...threatList].filter((val, idx, ar) => idx === ar.findIndex(u => u.GetGUID() === val.GetGUID()));
			const getUnitAsPlayer = (unit: Unit) => {
				const asPlayer = unit.ToPlayer();
				if (asPlayer) {
					return asPlayer;
				}
				const owner = unit.GetOwner();
				const ownerAsPlayer = owner?.ToPlayer();
				if (ownerAsPlayer) {
					return ownerAsPlayer;
				}
				return null;
			};
			const isGroupedWithPlayer = (unit: Unit) => {
				const controller = GetPlayerByGUID(unit.GetControllerGUID());
				if (controller && controller.IsInSameRaidWith(player)) {
					return true;
				}
				const asPlayer = getUnitAsPlayer(unit);
				if (asPlayer) {
					return asPlayer.IsInSameRaidWith(player);
				}
				return false;
			};

			if (units.some(unit => !isGroupedWithPlayer(unit))) {
				if (Config.instance.logging.mobTagging !== false && (Config.instance.logging.mobTagging === true || Config.instance.logging.mobTagging > 0)) {
					let counter = this.mobTaggingCounter.get(player);
					if (!counter) {
						counter = { value: 0, taggers: [] };
					}
					counter.value += 1;
					for (const unit of units) {
						const asPlayer = getUnitAsPlayer(unit);
						if (asPlayer && !counter.taggers.includes(asPlayer.GetName())) {
							counter.taggers.push(asPlayer.GetName());
						}
					}
					if (Config.instance.logging.mobTagging === true || counter.value >= Config.instance.logging.mobTagging) {
						counter.value = 0;
						this.log(`Mob-tagging (${Config.instance.logging.mobTagging === true ? 1 : Config.instance.logging.mobTagging} creatures) by ${counter.taggers.join(", ")}`, player);
					}

					if (counter.cancelId != undefined) {
						RemoveEventById(counter.cancelId);
					}
					const guid = player.GetGUID();
					counter.cancelId = CreateLuaEvent(() => { this.mobTaggingCounter.delete(guid) }, 3600000);
					this.mobTaggingCounter.set(guid, counter);
				}

				return 0;
			}
		}

		const char = this.getCharacter(player);
		if (char.isBloodthirsty() && (victim === null || victim.ToPlayer() !== null)) {
			return 0;
		}

		return amount;
	}

	private onPlayerTrade(event: PlayerEvents, player: Player, target: Player): boolean {
		const a = this.getCharacter(player);
		const b = this.getCharacter(target);
		const canTrade = a?.challenge === b?.challenge;
		if (!canTrade) {
			if (a) {
				player.SendNotification(`You can only trade with other ${a.formatChallenges()} players.`);
			} else {
				player.SendNotification(`You cannot trade with ${b.formatChallenges()} players.`);
			}
		}
		return canTrade;
	}

	private onPlayerCanUseItem(event: PlayerEvents, player: Player, itemEntry: number): InventoryResult {
		const character = this.getCharacter(player);
		const itemTemplate = GetItemTemplate(itemEntry);
		const allowedInvTypes = [18, 27, 0];
		if (character?.isIronman() && itemTemplate?.GetQuality() > 1 && !allowedInvTypes.includes(itemTemplate?.GetInventoryType() ?? -1)) {
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

	private onPetLearnTalent(event: PacketEvents, packet: WorldPacket, player: Player) {
		const character = this.getCharacter(player);
		if (character?.isIronman()) {
			// Prevent learning pet talents on Ironman characters
			return false;
		}
		return true;
	}

	private onAcceptTrade(event: PacketEvents, packet: WorldPacket, player: Player) {
		if (this.isPlayerEnlisted(player)) {
			// Prevent finishing a trade when enlisted
			const a = this.getCharacter(player);
			const b = this.getCharacter(player.GetTrader());
			const canTrade = a?.challenge === b?.challenge;
			return canTrade;
		}
		return true;
	}

	private onPlayerChangeLevel(event: PlayerEvents, player: Player, oldLevel: number) {
		if (!this.isPlayerEnlisted(player)) {
			return;
		}

		const char = this.getCharacter(player);
		char.updateCharacterData(player);
		char.playedTime = player.GetTotalPlayedTime();

		if (player.GetLevel() >= Config.instance.maxLevel) {
			if (Config.instance.logging.completed) {
				this.log(`Challenge ${char.formatChallenges()} completed`, GetPlayerByGUID(char.guid));
			}
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
		this.removeMarkerAuras(char);
	}

	private openCompletedUI(char: Character) {
		const player = GetPlayerByGUID(char.guid);
		if (player?.IsInCombat()) {
			CreateLuaEvent(() => this.openCompletedUI(char), 1000);
			return;
		}

		char.getRank((rank) => {
			const player = GetPlayerByGUID(char.guid);
			if (player) {
				AIO.Handle(player, Config.instance.channelName, "OpenCompletedUI", char.getChallengesArray(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), rank);
			}
			if (Config.instance.announceCompletions) {
				SendWorldMessage(`${this.getColoredName(char)} completed the ${char.formatChallenges()} Challenge and was ranked #${rank}!`);
			}
		});
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
					if (Config.instance.logging.rewards) {
						this.log(`Sent rewards for ${Character.formatChallenges(challenge)}`, player);
					}
				}
			}
		}
	}

	private removeMarkerAuras(char: Character) {
		const player = GetPlayerByGUID(char.guid);
		if (!player) {
			return;
		}

		for (const key in Config.instance.markerAuras) {
			player.RemoveAura(Config.instance.markerAuras[key]);
		}
	}

	private onPlayerSendMail(event: PlayerEvents, player: Player, receiverGuid: number, mailbox: number, subject: string, body: string, money: number, cod: number, item: Item): boolean {
		const receiver = this.characters.get(receiverGuid);
		const sender = this.getCharacter(player);
		if (receiver && receiver.challenge !== sender?.challenge && (money > 0 || item !== null)) {
			// Prevent from sending the mail if the target character is running a different challenge and the mail contains money or items
			return false;
		}
		if (sender && cod > 0 && !receiver) {
			// Prevent from getting money from non-challenge players with COD
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

		if (Config.instance.announcePermanentDeaths && player.GetLevel() >= Config.instance.announcePermanentDeathsMinLevel) {
			SendWorldMessage(`${this.getColoredName(player)} was killed by ${killer.GetName()} at level ${player.GetLevel()} in ${this.formatArea(player)} (${char.formatChallenges()} Challenge).`);
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

		if (Config.instance.announcePermanentDeaths && killed.GetLevel() >= Config.instance.announcePermanentDeathsMinLevel) {
			if (killer.GetGUID() === killed.GetGUID()) {
				SendWorldMessage(`${this.getColoredName(killed)} died at level ${killed.GetLevel()} in ${this.formatArea(killed)} (${char.formatChallenges()} Challenge).`);
			} else {
				SendWorldMessage(`${this.getColoredName(killed)} was killed by player ${killer.GetName()} at level ${killed.GetLevel()} in ${this.formatArea(killed)} (${char.formatChallenges()} Challenge).`);
			}
		}

		this.onPlayerDied(killed);
	}

	private onPlayerDied(player: Player) {
		if (Config.instance.logging.died) {
			this.log(`Died (.go xyz ${player.GetX()} ${player.GetY()} ${player.GetZ()} ${player.GetMapId()})`, player);
		}
		const char = this.getCharacter(player);
		char.dead = true;
		char.updateCharacterData(player);
		char.diedOn = GetGameTime();
		char.save();

		char.getRank((rank) => {
			const player = GetPlayerByGUID(char.guid);
			if (player) {
				AIO.Handle(player, Config.instance.channelName, "OpenDeathUI", char.getChallengesArray(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), rank);
			}
		});
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

	private onPlayerCastSpell(event: PlayerEvents, player: Player, spell: Spell, skipCheck: boolean) {
		let target = spell.GetTarget()?.ToPlayer();
		if (!target) {
			const owner = spell.GetTarget()?.ToUnit()?.GetOwner();
			const ownerAsPlayer = owner?.ToPlayer();
			if (ownerAsPlayer) {
				target = ownerAsPlayer;
			}
		}
		if (target && this.isPlayerEnlisted(target) && target.GetTeam() === player.GetTeam() && !player.IsInSameRaidWith(target)) {
			// Prevent power-leveling enlisted players by buffing or healing
			spell.Cancel();
		}
	}

	private onCommand(event: PlayerEvents, player: Player, command: string, chatHandler: ChatHandler) {
		const isGm = chatHandler.IsConsole() || player.GetGMRank() >= 2;
		const args = command.split(" ").filter(arg => arg.trim() !== "");
		if (args.length > 1 && ["challenges", "challenge", "chall", "chal"].includes(args[0].toLowerCase())) {
			args.shift();
			const cmd = args.shift().toLowerCase();
			const char = this.getCharacter(player);

			if (isGm && ["complete", "completion", "completed"].includes(cmd)) {
				char?.getRank((rank) => {
					const player = GetPlayerByGUID(char.guid);
					if (player) {
						AIO.Handle(player, Config.instance.channelName, "OpenCompletedUI", char.getChallengesArray(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), rank);
					}
				});
				return false;
			}
			if (isGm && ["die", "dead", "death"].includes(cmd)) {
				char?.getRank((rank) => {
					const player = GetPlayerByGUID(char.guid);
					if (player) {
						AIO.Handle(player, Config.instance.channelName, "OpenDeathUI", char.getChallengesArray(), Utils.formatPlayedTime(player.GetTotalPlayedTime()), rank);
					}
				});
				return false;
			}
			if (isGm && ["online", "list", "count"].includes(cmd)) {
				const counts = {};
				let total = 0;

				for (const key of this.characters.keys()) {
					const char = this.characters.get(key);
					const player = GetPlayerByGUID(char.guid);
					if (player !== null) {
						++total;
						for (const mode of allChallengeModes()) {
							if (char.hasChallenge(mode)) {
								counts[mode] = (counts[mode] ?? 0) + 1;
							}
						}
					}
				}

				let str = "";
				for (const mode of allChallengeModes()) {
					str += EChallengeMode[mode] + ": " + (counts[mode] ?? 0) + "\n";
				}
				str += "Online: " + total;
				chatHandler.SendSysMessage(str);
				return false;
			}
			if (isGm && ["restore"].includes(cmd)) {
				const nameOrGuid = args.shift();
				if (!nameOrGuid) {
					chatHandler.SendSysMessage(`Syntax: .challenge restore $nameOrGuid`);
					return false;
				}

				const guid = parseInt(nameOrGuid);
				const res = CharDBQuery(`SELECT * FROM ${Character.table()} WHERE name = \"${nameOrGuid}\" OR guid = \"${guid}\"`);
				const rows = Database.getRowsFromQuery(res);
				const chars = rows.map(Character.createFromRow);
				if (chars.length > 1) {
					chatHandler.SendSysMessage("Found multiple characters with this name:\n" + chars.map(c => {
						const date = timestampToDate(c.diedOn);
						return `- ${c.name} / GUID ${c.guid} / Account ${c.account} / ${c.formatChallenges()} / died on ${Utils.formatDate(date)} at level ${c.level}`;
					}).join("\n"));
					return false;
				}
				if (chars.length === 0) {
					chatHandler.SendSysMessage("Could not find character");
					return false;
				}

				const char = chars[0];
				RunCommand(`character deleted restore ${char.guid}`);
				RunCommand(`unban character ${char.name}`);
				char.diedOn = null;
				char.dead = false;
				this.characters.set(char.guid, char);
				char.save();
				chatHandler.SendSysMessage("Character restored");
				return false;
			}
			if (["info", "inspect", "i"].includes(cmd)) {
				let target: Character;
				if (args.length > 0) {
					const name = args.shift().toLowerCase();
					target = this.characters.keys().map(k => this.characters.get(k)).find(char => char.name.toLowerCase() === name);
				} else {
					target = this.getCharacter(chatHandler.GetSelectedPlayer());
				}

				if (target) {
					const name = chatHandler.IsConsole() ? target.name : this.getColoredName(target);
					chatHandler.SendSysMessage(`${name} is enlisted for ${target.formatChallenges()}.`);
				} else {
					chatHandler.SendSysMessage(`Not enlisted for any Challenge Mode.`);
				}
				return false;
			}
			if (player && player.IsInGuild() && ["guild"].includes(cmd) && ["ban"].includes(args[0].toLowerCase())) {
				const name = args[1];
				if (name == null || name == "") {
					chatHandler.SendSysMessage("Usage: .challenge guild ban Playername");
					return false;
				}

				const guild = player.GetGuild();
				if (guild.GetName() === Config.instance.guildName && [0, 1].includes(player.GetGuildRank())) {
					const target = GetPlayerByName(name);
					if (target) {
						if (target.IsInGuild() && target.GetGuild().GetId() === guild.GetId()) {
							if ([0, 1].includes(target.GetGuildRank())) {
								chatHandler.SendSysMessage(`Cannot ban ${this.getColoredName(target)} from the guild.`);
								return false;
							}
							guild.DeleteMember(target, false);
						}

						const ban = new GuildBan(target.GetAccountId());
						ban.save();
						this.guildBans.add(ban.account);

						chatHandler.SendSysMessage(`${this.getColoredName(target)}'s account has been banned from the guild.`);
					} else {
						chatHandler.SendSysMessage(`Player ${name} does not exist or is offline.`);
					}
					return false;
				}
			}
			if (player && ["guild"].includes(cmd)) {
				if (!this.isPlayerEnlisted(player)) {
					chatHandler.SendSysMessage("You need to be enlisted for Challenge Modes to join the guild.");
					return false;
				}

				if (player.IsInGuild()) {
					chatHandler.SendSysMessage("You are already in a guild.");
					return false;
				}

				if (this.guildBans.has(player.GetAccountId())) {
					chatHandler.SendSysMessage("You are banned from this guild.");
					return false;
				}

				RunCommand(`guild invite ${player.GetName()} "${Config.instance.guildName}"`);

				if (Config.instance.guildRanks && Config.instance.guildRanks[char.challenge.toString()] !== undefined) {
					CreateLuaEvent(() => {
						const player = GetPlayerByGUID(char.guid);
						if (player) {
							const guild = player.GetGuild();
							guild?.SetMemberRank(player, Config.instance.guildRanks[char.challenge.toString()]);
						}
					}, 1000);
				}
				return false;
			}

			return true;
		}
	}

	private onCharacterDeleted(event: PlayerEvents, guid: number) {
		if (this.characters.has(guid)) {
			const char = this.characters.get(guid);
			this.characters.delete(char.guid);
			char.delete();
			if (Config.instance.logging.manualDelete) {
				this.log(`Manually deleted (${char.formatChallenges()})`, char);
			}
		}
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

		const guid = player.GetGUID();
		this.checkEligible(player, (eligible) => {
			const player = GetPlayerByGUID(guid);
			if (!player) {
				return;
			}

			if (eligible !== true) {
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
			if (Config.instance.logging.enlisted) {
				this.log(`Enlisted for ${Character.formatChallenges(challenge)}`, player);
			}

			// Clear buyback
			const buybackSlotStart = 74;
			const buybackSlotEnd = 86;
			for (let slot = buybackSlotStart; slot < buybackSlotEnd; ++slot) {
				const eslot = slot - buybackSlotStart;
				player.SetUInt32Value(this.PLAYER_FIELD_VENDORBUYBACK_SLOT_1 + (eslot * 2), 0);
				player.SetUInt32Value(this.PLAYER_FIELD_BUYBACK_PRICE_1 + eslot, 0);
				player.SetUInt32Value(this.PLAYER_FIELD_BUYBACK_TIMESTAMP_1 + eslot, 0);
			}

			AIO.Handle(player, Config.instance.channelName, "Enlisted", EChallengeMode[challenge]);

			if (player.IsInGroup()) {
				// Remove from group
				const group = player.GetGroup();
				group.RemoveMember(player.GetGUID(), RemoveMethod.GROUP_REMOVEMETHOD_LEAVE);
			}

			player.AddAura(Config.instance.markerAuras[challenge.toString()], player);
			player.UpdatePlayerSetting(this.settingsWeekendXpSource, this.settingsWeekendXpDisable, 1);
		});
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
		if (!player) {
			return null;
		}
		return this.characters.get(player);
	}

	private log(text: string, player?: Character | Player) {
		const [scriptDir] = string.match(debug.getinfo(1).source, "@?(.*/)");
		const logDir = Utils.isPathAbsolute(Config.instance.logging.directory)
			? Config.instance.logging.directory
			: scriptDir + Utils.getPathSeparator() + Config.instance.logging.directory;
		const date = this.getCurrentDate();
		const [f, _, __] = io.open(logDir + Utils.getPathSeparator() + `challengemodes_${Utils.formatDate(date, "_")}.log`, "a");
		if (!f) {
			return;
		}

		const playerStr = player == undefined
			? ""
			: (
				player instanceof Character
					? ` [${player.name} (${player.guid})]`
					: ` [${player.GetName()} (${player.GetGUID()})]`
			);
		const line = `[${Utils.formatDate(date)} ${Utils.formatTime(date)} UTC]${playerStr} ${text}`;
		f.write(`${line}\n`);
		f.close();
		print(line);
	}

	private getColoredName(player: Character | Player): string {
		let name: string;
		let classId: number;
		if (player instanceof Character) {
			name = player.name;
			classId = player.class;
		} else {
			name = player.GetName();
			classId = player.GetClass();
		}

		const colors = {
			1: "C69B6D",
			2: "F48CBA",
			3: "AAD372",
			4: "FFF468",
			5: "FFFFFF",
			6: "C41E3A",
			7: "0070DD",
			8: "3FC7EB",
			9: "8788EE",
			11: "FF7C0A",
		};
		return `|CFF${colors[classId]}${name}|r`;
	}

	private formatArea(player: Player): string {
		const area = Areas[player.GetAreaId()];
		if (!area) {
			return "unknown area";
		}

		let result = area.n;
		const parent = area.p ? Areas[area.p] : null;
		if (parent) {
			result += `, ${parent.n}`;
		}

		return result;
	}

	private getCurrentDate(): Date {
		return timestampToDate(parseInt(GetGameTime() + ""));
	}
}

Config.read();
new ChallengeModes();
