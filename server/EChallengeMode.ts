export enum EChallengeMode {
	Hardcore = 1,
	Ironman = 2,
	Bloodthirsty = 4,
}

export function allChallengeModes(): EChallengeMode[] {
	return [EChallengeMode.Hardcore, EChallengeMode.Ironman, EChallengeMode.Bloodthirsty];
}
