const AIO = require("AIO") as Aio;

interface IPlayerUsingBanner {
	bannerGobj: number;
	player: number;
	map: number;
}

enum EChallengeMode {
	Hardcore = 0,
	Ironman = 1,
	Bloodthirsty = 2,
}

class ChallengeModes {
	// Constants
	private readonly ACHIEVEMENT_CRITERIA_DEATHS = 111;

	// Ids
	private readonly allianceGobjEntry = 2000000;
	private readonly hordeGobjEntry = 2000001;
	private readonly startingGear = [38, 39, 40, 49778, 6948, 45, 43, 44, 2361, 49, 47, 48, 28979, 2092, 50055, 6098, 52, 53, 51, 35, 34652, 34655, 34659, 34650, 34653, 34649, 34651, 34656, 34648, 34657, 34658, 38145, 38147, 41751, 40582, 56, 1395, 55, 6096, 57, 6097, 1396, 59, 6125, 139, 140, 12282, 127, 6126, 6127, 2101, 2504, 2512, 2105, 120, 121, 25861, 154, 153, 36, 2362, 6129, 6117, 6118, 148, 147, 129, 2102, 2508, 2516, 6116, 159, 4540, 6120, 6121, 6122, 3661, 6119, 6123, 6124, 6144, 6140, 6139, 6136, 6137, 6138, 6134, 6135, 24143, 24145, 24146, 23346, 20901, 20899, 20900, 20980, 20982, 20897, 20896, 20898, 50057, 20891, 20978, 20893, 20894, 20895, 20892, 23473, 23474, 23475, 23476, 23477, 23345, 23344, 23348, 23347, 23322, 23478, 23479];
	private readonly startingGearQuantities = { 2512: 200, 2516: 200, 38145: 4, 41751: 10 };

	private readonly channelName = "ChallengeModes";
	private playersUsingBanner: IPlayerUsingBanner[];
	private enlistedPlayers: { [key: string]: EChallengeMode }; // The key is the character's GUID

	public constructor() {
		AIO.AddHandlers(this.channelName, {
			/** @noSelf **/ enlist: (...args: [Player, EChallengeMode]) => this.enlist(...args),
			/** @noSelf **/ closeBannerUI: (...args: [Player]) => this.closeBannerUI(...args),
		});

		this.playersUsingBanner = [];
		this.enlistedPlayers = {};
		this.registerBannerEvents();
		this.registerPlayerEvents();
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

		// Check if a challenge is already active
		if (this.isPlayerEnlisted(player)) {
			return "CHALLENGEACTIVE";
		}

		// Make sure the player is still in range from the banner
		if (!this.isPlayerInRangeFromBanner(player)) {
			return "RANGE";
		}

		return true;
	}

	private registerBannerEvents() {
		CreateLuaEvent(() => {
			for (let i = this.playersUsingBanner.length - 1; i >= 0; --i) {
				const bannerUse = this.playersUsingBanner[i];
				const player = GetPlayerByGUID(bannerUse.player);
				if (player === undefined || !this.isPlayerInRangeFromBanner(player)) {
					this.playersUsingBanner.splice(i, 1);
					if (player !== undefined) {
						AIO.Handle(player, this.channelName, "CloseBannerUI");
					}
				}
			}
		}, 5000, 0);

		RegisterGameObjectEvent(this.allianceGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onAllianceBannerUse(...args));
		RegisterGameObjectEvent(this.hordeGobjEntry, GameObjectEvents.GAMEOBJECT_EVENT_ON_USE, (...args) => this.onHordeBannerUse(...args));
	}

	private registerPlayerEvents() {
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_REPOP, (...args) => this.onPlayerRepop(...args));
		RegisterPlayerEvent(PlayerEvents.PLAYER_EVENT_ON_RESURRECT, (...args) => this.onPlayerResurrect(...args));
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
		this.playersUsingBanner.push({
			bannerGobj: gobj.GetGUID(),
			player: player.GetGUID(),
			map: gobj.GetMapId(),
		});

		AIO.Handle(player, this.channelName, "OpenBannerUI", this.checkEligible(player));
	}

	private onPlayerRepop(event: PlayerEvents, player: Player) {
		if (!this.isPlayerEnlisted(player)) {
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

		RunCommand(`character erase ${player.GetName()}`);
	}

	private enlist(player: Player, challenge: EChallengeMode) {
		AIO.Handle(player, this.channelName, "CloseBannerUI");

		if (![EChallengeMode.Hardcore, EChallengeMode.Ironman, EChallengeMode.Bloodthirsty].includes(challenge)) {
			// Invalid challenge id
			return;
		}

		if (this.checkEligible(player) !== true) {
			player.SendChatMessageToPlayer(ChatMsg.CHAT_MSG_SYSTEM, Language.LANG_UNIVERSAL, `Could not enable the ${EChallengeMode[challenge]} challenge.`, player);
			return;
		}

		this.enlistedPlayers[player.GetGUID().toString()] = challenge;
		AIO.Handle(player, this.channelName, "Enlisted", EChallengeMode[challenge]);

		// TODO: remove from group if members are not in the same challenge
	}

	private closeBannerUI(player: Player) {
		const idx = this.playersUsingBanner.findIndex(obj => obj.player === player.GetGUID());
		if (idx !== -1) {
			this.playersUsingBanner.splice(idx, 1);
		}
	}

	private isPlayerInRangeFromBanner(player: Player): boolean {
		const bannerUse = this.playersUsingBanner.find(obj => obj.player === player.GetGUID());
		if (bannerUse === undefined) {
			return false;
		}

		const map = GetMapById(bannerUse.map);
		const banner = map?.GetWorldObject(bannerUse.bannerGobj);
		if (banner === undefined) {
			return false;
		}
		return player.IsInRange(banner, 0, 15);
	}

	private isPlayerEnlisted(player: Player): boolean {
		return player.GetGUID().toString() in this.enlistedPlayers;
	}
}

new ChallengeModes();
