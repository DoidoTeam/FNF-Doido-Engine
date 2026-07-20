package doido.song;

import doido.utils.Order;

typedef WeekData =
{
	var songs:Array<WeekSong>;
	var ?weekFile:String;
	var ?weekName:String;
	var ?freeplayName:String;
	var ?chars:Array<String>;
	var ?diffs:Array<String>;
	var ?storyDiffs:Array<String>;
	var ?storyColor:String;
	var ?freeplayOnly:Bool;
	var ?storyModeOnly:Bool;
}

typedef WeekSong =
{
	var song:String;
	var ?icon:String;
}

class Week
{
	public static function defaultWeek():WeekData
	{
		return {
			songs: [],
			weekFile: "week1",
			weekName: "unknown",
			freeplayName: "unknown",
			chars: ["", "", ""],
			freeplayOnly: false,
			storyModeOnly: false,
			diffs: ['easy', 'normal', 'hard'],
			storyDiffs: ['easy', 'normal', 'hard'],
			storyColor: "0xFFF9CF51"
		};
	}

	public static function weekList(storyMode:Bool = false, freeplay:Bool = true):Array<WeekData>
	{
		var order:Array<String> = Order.getOrder('data/weeks');
		var list:Array<WeekData> = [];
		for (week in order)
		{
			var rawWeek:WeekData = loadWeek(week);
			if ((!rawWeek.storyModeOnly || storyMode) && (!rawWeek.freeplayOnly || freeplay) && rawWeek.songs.length > 0)
				list.push(rawWeek);
		}
		return list;
	}

	public static function loadWeek(week:String):WeekData
	{
		var newWeek:WeekData;
		var DEFAULT = defaultWeek();
		try
		{
			newWeek = cast(Assets.json('data/weeks/$week'));
		}
		catch (e)
		{
			Logs.print('WEEK $week LOAD ERROR: $e', ERROR);
			newWeek = DEFAULT;
		}

		newWeek.weekFile = newWeek.weekFile ?? DEFAULT.weekFile;
		newWeek.weekName = newWeek.weekName ?? DEFAULT.weekName;
		newWeek.freeplayName = newWeek.freeplayName ?? newWeek.weekName;

		newWeek.chars = newWeek.chars ?? DEFAULT.chars;
		newWeek.diffs = newWeek.diffs ?? DEFAULT.diffs;
		newWeek.storyDiffs = newWeek.storyDiffs ?? newWeek.diffs;
		newWeek.storyColor = newWeek.storyColor ?? DEFAULT.storyColor;

		newWeek.freeplayOnly = newWeek.freeplayOnly ?? DEFAULT.freeplayOnly;
		newWeek.storyModeOnly = newWeek.storyModeOnly ?? DEFAULT.storyModeOnly;

		return newWeek;
	}
}
