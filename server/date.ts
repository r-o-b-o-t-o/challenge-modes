export interface Date {
	sec: number,
	min: number,
	hour: number,
	mday: number,
	month: number,
	year: number,
	wday: number,
	yday: number,
}

export function timestampToDate(timestamp: number): Date {
	// https://stackoverflow.com/a/11197532

	let sec: number;
	let centennials: number;
	let quadrennials: number;
	let annuals: number;
	let month: number;
	let mday: number;
	const daysSinceJan1st = [
		[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365], // 365 days, non-leap
		[0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366], // 366 days, leap
	];

	// Re-bias from 1970 to 1601:
	// 1970 - 1601 = 369 = 3*100 + 17*4 + 1 years (incl. 89 leap days) =
	// (3*100*(365+24/100) + 17*4*(365+1/4) + 1*365)*24*3600 seconds
	sec = timestamp + 11644473600;

	const wday = Math.floor(sec / 86400 + 1) % 7; // day of week

	// Remove multiples of 400 years (incl. 97 leap days)
	const quadricentennials = Math.floor(sec / 12622780800); // 400*365.2425*24*3600
	sec %= 12622780800;

	// Remove multiples of 100 years (incl. 24 leap days), can't be more than 3
	// (because multiples of 4*100=400 years (incl. leap days) have been removed)
	centennials = Math.floor(sec / 3155673600); // 100*(365+24/100)*24*3600
	if (centennials > 3) {
		centennials = 3;
	}
	sec -= centennials * 3155673600;

	// Remove multiples of 4 years (incl. 1 leap day), can't be more than 24
	// (because multiples of 25*4=100 years (incl. leap days) have been removed)
	quadrennials = Math.floor(sec / 126230400); // 4*(365+1/4)*24*3600
	if (quadrennials > 24) {
		quadrennials = 24;
	}
	sec -= quadrennials * 126230400;

	// Remove multiples of years (incl. 0 leap days), can't be more than 3
	// (because multiples of 4 years (incl. leap days) have been removed)
	annuals = Math.floor(sec / 31536000); // 365*24*3600
	if (annuals > 3) {
		annuals = 3;
	}
	sec -= annuals * 31536000;

	// Calculate the year and find out if it's leap
	const year = 1601 + quadricentennials * 400 + centennials * 100 + quadrennials * 4 + annuals;
	const leap = isLeapYear(year);

	// Calculate the day of the year and the time
	const yday = Math.floor(sec / 86400);
	sec %= 86400;
	const hour = Math.floor(sec / 3600);
	sec %= 3600;
	const min = Math.floor(sec / 60);
	sec %= 60;

	// Calculate the month
	for (mday = month = 1; month < 13; month++) {
		if (yday < daysSinceJan1st[leap ? 1 : 0][month]) {
			mday += yday - daysSinceJan1st[leap ? 1 : 0][month - 1];
			break;
		}
	}

	return {
		sec, // [0,59]
		min, // [0,59]
		hour, // [0,23]
		mday, // [1,31] (day of month)
		month: month - 1, // [0,11] (month)
		year, // year
		wday, // [0,6] (day since Sunday AKA day of week)
		yday, // [0,365] (day since January 1st AKA day of year)
	};
}

export function dateToTimestamp(date: Date): number {
	// https://www.oryx-embedded.com/doc/date__time_8c_source.html#l00258

	// Year
	let y = date.year;
	// Month of year
	let m = date.month + 1;
	// Day of month
	const d = date.mday;

	// January and February are counted as months 13 and 14 of the previous year
	if (m <= 2) {
		m += 12;
		y -= 1;
	}

	// Convert years to days
	let t = (365 * y) + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400);
	// Convert months to days
	t += (30 * m) + Math.floor(3 * (m + 1) / 5) + d;
	// Unix time starts on January 1st, 1970
	t -= 719561;
	// Convert days to seconds
	t *= 86400;
	// Add hours, minutes and seconds
	t += (3600 * date.hour) + (60 * date.min) + date.sec;

	return t;
}

export function isLeapYear(year: number): boolean {
	return (!(year % 4) && (year % 100 || !(year % 400))) === 1;
}
