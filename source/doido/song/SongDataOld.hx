package doido.song;

/*
THIS CLASS IS USED TO CONVERT OLD CHART FORMATS INTO THE NEW ONE
*/

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	// Parity with other engines
	var ?gfVersion:String;
}
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	
	// psych suport
	var ?sectionBeats:Float;
}
typedef EventSong = {
	// [0] = section // [1] = strumTime // [2] events
	var songEvents:Array<Dynamic>;
}

typedef OldBPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class SongDataOld
{
	// fallback song. if you plan on removing -debug you should consider changing this to a song that does exist
	inline public static function defaultSong():SwagSong
	{
		return
		{
			song: "-debug",
			notes: [],
			bpm: 100,
			needsVoices: true,
			speed: 1.0,

			player1: "bf",
			player2: "dad",
			gfVersion: "stage-set",
		};
	}

	inline public static function defaultSection():SwagSection
	{
		return
		{
			sectionNotes: [],
			lengthInSteps: 16,
			mustHitSection: true,
			bpm: 100,
			changeBPM: false,
		};
	}
	inline public static function defaultSongEvents():EventSong
		return {songEvents: []};

	// [0] = section // [1] = strumTime // [2] events
	inline public static function defaultEventNote():Array<Dynamic>
		return [0, 0, []];
	inline public static function defaultEvent():Array<Dynamic>
		return ["name", "value1", "value2", "value3"];

	inline public static function loadFromJson(jsonInput:String, ?diff:String = "normal"):SwagSong
	{		
		Logs.print('Chart Loaded: ' + '$jsonInput/$diff');

		if(!Assets.fileExists('songs/$jsonInput/chart/$diff.json'))
			diff = "normal";
		
		var daSong:SwagSong = cast Assets.json('songs/$jsonInput/chart/$diff').song;
		
		// formatting it
		daSong = formatSong(daSong);
		
		return daSong;
	}

	inline public static function loadEventsJson(jsonInput:String, diff:String = "normal"):EventSong
	{
		var formatPath = 'events-$diff';

		function checkFile():Bool {
			return Assets.fileExists('songs/$jsonInput/chart/$formatPath.json');
		}
		if(!checkFile())
			formatPath = 'events';
		if(!checkFile()) {
			Logs.print('No Events Loaded');
			return {songEvents: []};
		}

		Logs.print('Events Loaded: ' + '$jsonInput/chart/$formatPath');

		var daEvents:EventSong = cast Assets.json('songs/$jsonInput/chart/$formatPath');
		return daEvents;
	}
	
	// Removes duplicated notes from a chart.
	inline public static function formatSong(SONG:SwagSong):SwagSong
	{
		// Normalize song name to use only lowercases and no spaces
		SONG.song = SONG.song.toLowerCase();
		if(SONG.song.contains(' '))
			SONG.song = SONG.song.replace(' ', '-');

		// cleaning multiple notes at the same place
		var removed:Int = 0;
		for(section in SONG.notes)
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

		if(SONG.gfVersion == null)
			SONG.gfVersion = "stage-set";
		
		return SONG;
	}

    public static function getOldBPMChanges(song:SwagSong):Array<OldBPMChangeEvent>
    {
        var bpmChangeMap:Array<OldBPMChangeEvent> = [];

        if (song == null) return [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:OldBPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += Conductor.calcStep(curBPM) * deltaSteps;
		}
		return bpmChangeMap;
    }
}
