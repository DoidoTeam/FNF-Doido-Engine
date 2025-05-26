package backend.song;

typedef FunkyWeek = {
	var songs:Array<Array<String>>;
	var ?weekFile:String;
	var ?weekName:String;
	var ?chars:Array<String>;
	var ?freeplayOnly:Bool;
	var ?storyModeOnly:Bool;
	var ?diffs:Array<String>;
}

class WeekData
{
    public static var defaultDiffs:Array<String> = ['easy', 'normal', 'hard'];
	public static var weeks:Array<FunkyWeek> = [
		{
			songs: [
				['tutorial', 'gf'],
			],
			weekFile: 'tutorial',
			weekName: 'funky beginnings',
			chars: ['', 'bf', 'gf'],
		},
		{
			songs: [
				['bopeebo', 	'dad'],
				['fresh', 		'dad'],
				['dadbattle', 	'dad'],
			],
			weekFile: 'week1',
			weekName: 'daddy dearest',
			chars: ['dad', 'bf', 'gf'],
			diffs: ['easy', 'normal', 'hard', 'erect', 'nightmare'],
		},
		{
			songs: [
				['senpai', 	'senpai'],
				['roses', 	'senpai'],
				['thorns', 	'spirit'],
			],
			weekFile: 'week6',
			weekName: 'hating simulator (ft. moawling)',
			chars: ['senpai', 'bf', 'gf'],
			diffs: ['easy', 'normal', 'hard', 'erect', 'nightmare'],
		},
		{
			songs: [
				["bittersweet", 	"spooky"],
				["blam", 			"pico"],
				["-debug", 			"bf-pixel"],
				["useless",			"bf-pixel"],
				["collision", 		"gemamugen"], // CU PINTO BOSTA
				["lunar-odyssey",	"luano-day"],
				["beep-power", 		"dad"],
			],
			freeplayOnly: true,
		},
	];

	inline public static function getWeek(index:Int):FunkyWeek
	{
		var week = weeks[index];
		if(week == null)
			week = {songs: []};
		if(week.weekFile == null)
			week.weekFile = '$index';
		if(week.weekName == null)
			week.weekName = '';
		if(week.chars == null)
			week.chars = ['', '', ''];
		if(week.freeplayOnly == null)
			week.freeplayOnly = false;
		if(week.storyModeOnly == null)
			week.storyModeOnly = false;
		if(week.diffs == null)
			week.diffs = defaultDiffs;
		return week;
	}
}