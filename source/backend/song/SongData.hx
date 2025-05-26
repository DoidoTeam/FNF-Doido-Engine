package backend.song;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagNote>;
	var speed:Float;
	var bpm:Float;

	var player:String;
	var opponent:String;
	var ?gf:String;

	var ?isDoido:Bool;
}
typedef SwagNote =
{
	var step:Float;
	var holdLength:Float;
	var type:String;
}
/*
*
*	EVENTS
*
*/
typedef SwagEventSong =
{
	var songEvents:Array<SwagEventNote>;
}
typedef SwagEventNote =
{
	var step:Float;
	var events:Array<SwagEvent>;
}
typedef SwagEvent =
{
	var name:String;
	var values:Array<String>;
}

class SongData
{
	// fallback song. if you plan on removing -debug you should consider changing this to a song that does exist
	inline public static function defaultSong():SwagSong
	{
		return
		{
			song: "-debug",
			notes: [],
			bpm: 100,
			speed: 1.0,

			player: "bf",
			opponent: "dad",
			gf: "stage-set",
		};
	}

	inline public static function defaultSongEvents():SwagEventSong
		return {songEvents: []};

	inline public static function defaultEventNote():SwagEventNote
		return {
			step: 0,
			events: [],
		};
	inline public static function defaultEvent():SwagEvent
		return {
			name: "",
			values: ["", "", ""],
		};

	inline public static function loadFromJson(jsonInput:String, ?diff:String = "normal"):SwagSong
	{		
		Logs.print('Chart Loaded: ' + '$jsonInput/$diff');

		if(!Paths.fileExists('songs/$jsonInput/chart/$diff.json'))
			diff = "normal";
		
		var daSong:SwagSong = null;
		try {
			daSong = cast Paths.json('songs/$jsonInput/chart/$diff');
		} catch(e) {
			Logs.print('Json file not supported!! Press "7" on the main menu to convert it.', ERROR);
		}
		
		// formatting it
		daSong = formatSong(daSong);
		
		return daSong;
	}

	inline public static function loadEventsJson(jsonInput:String, diff:String = "normal"):SwagEventSong
	{
		var formatPath = 'events-$diff';

		function checkFile():Bool {
			return Paths.fileExists('songs/$jsonInput/chart/$formatPath.json');
		}
		if(!checkFile())
			formatPath = 'events';
		if(!checkFile()) {
			Logs.print('No Events Loaded');
			return {songEvents: []};
		}

		Logs.print('Events Loaded: ' + '$jsonInput/chart/$formatPath');

		return cast Paths.json('songs/$jsonInput/chart/$formatPath');
	}
	
	inline public static function formatSong(SONG:SwagSong):SwagSong
	{
		// defaults song name to use only lowercases and no spaces
		SONG.song = SONG.song.toLowerCase();
		if(SONG.song.contains(' '))
			SONG.song = SONG.song.replace(' ', '-');

		// removes duplicated notes from a chart.
		var removed:Int = 0;
		/*for(section in SONG.notes)
		{
			if(!Std.isOfType(section.lengthInSteps, Int))
			{
				var steps:Int = 16;
				if(section.sectionBeats != null)
					steps = Math.floor(section.sectionBeats * 4);
				
				section.lengthInSteps = steps;
			}
			
			for(songNotes in section.sectionNotes)
			{
				for(doubleNotes in section.sectionNotes)
				{
					if(songNotes 	!= doubleNotes
					&& songNotes[0] == doubleNotes[0]
					&& songNotes[1] == doubleNotes[1])
					{
						section.sectionNotes.remove(doubleNotes);
						removed++;
					}
				}
			}
		}
		if(removed > 0)
			Logs.print('removed $removed duplicated notes');
		*/

		if(SONG.gf == null)
			SONG.gf = "stage-set";
		
		return SONG;
	}
}
