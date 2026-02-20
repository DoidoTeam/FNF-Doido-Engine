package doido.song;

import doido.song.SongDataOld.SwagSong;

typedef DoidoSong =
{
	var song:String;
	var notes:Array<NoteData>;
	var bpm:Float;
	//var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
}
typedef NoteData = {
	var stepTime:Float;
	var lane:Int;
	var strumline:Int;
    var type:String;
	var length:Float;
}
/*typedef EventSong = {
	// [0] = section // [1] = strumTime // [2] events
	var songEvents:Array<Dynamic>;
}*/

class SongData
{
    inline public static function loadFromJson(jsonInput:String, ?diff:String = "normal"):DoidoSong
	{		
		Logs.print('Chart Loaded: ' + '$jsonInput/$diff');

		if(!Assets.fileExists('songs/$jsonInput/chart/$diff.json'))
			diff = "normal";

        var rawSong:Dynamic = cast Assets.json('songs/$jsonInput/chart/$diff');

        if (!Std.isOfType(rawSong.song, String))
        {
            var SONG:DoidoSong = fnf2Doido(rawSong.song);
            return formatSong(SONG);
        }

        var SONG:DoidoSong = cast rawSong;
        return formatSong(SONG);
	}

    

    inline public static function fnf2Doido(swagSong:SwagSong):DoidoSong
    {
        var SONG:DoidoSong = {
            song: swagSong.song,
            notes: [],
            bpm: swagSong.bpm,
            speed: swagSong.speed,

            player1: swagSong.player1,
            player2: swagSong.player2,
        };

        var unspawnNotes:Array<NoteData> = [];
		var daSection:Int = 0;
		var daSteps:Int = 0;
		
		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.stepCrochet;
        var bpmChangeMap = SongDataOld.getOldBPMChanges(swagSong);
		
		for(section in swagSong.notes)
		{
			for(event in bpmChangeMap)
				if(event.stepTime == daSteps)
				{
					noteCrochet = Conductor.calcStep(event.bpm);
					Logs.print('changed note bpm ${event.bpm}');
				}
			
			for (songNotes in section.sectionNotes)
			{
				/* - late || + early */
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = 'none';
				// very stupid but I'm lazy
				if(songNotes.length > 2)
					daNoteType = songNotes[3];
				
				// psych event notes come on
				if(songNotes[1] < 0) continue;

                var isPlayer = (songNotes[1] >= 4);
				if(section.mustHitSection)
					isPlayer = (songNotes[1] <  4);

                var swagNote:NoteData = {
                    stepTime: daStrumTime / noteCrochet,
                    lane: daNoteData,
                    strumline: isPlayer ? 1 : 0,
                    type: daNoteType,
                    length: 0
                };
				
                unspawnNotes.push(swagNote);
				
				var susLength:Float = songNotes[2];
				if(susLength > 0)
				{
					var rawLoop:Float = (susLength / noteCrochet);
					var holdLoop:Int = (
						(rawLoop - Math.floor(rawLoop) <= 0.8) ?
						Math.floor(rawLoop) : Math.round(rawLoop)
					);
					if (holdLoop <= 0) holdLoop = 1;

                    swagNote.length = holdLoop;
				}
			}
			daSteps += section.lengthInSteps;
			daSection++;
		}
		
		//unspawnNotes.sort(CoolUtil.sortByShit);

        return SONG;
    }

    // Removes duplicated notes from a chart.
	inline public static function formatSong(SONG:DoidoSong):DoidoSong
	{
		// Normalize song name to use only lowercases and no spaces
		SONG.song = SONG.song.toLowerCase();
		if(SONG.song.contains(' '))
			SONG.song = SONG.song.replace(' ', '-');

		// cleaning multiple notes at the same place
		var removed:Int = 0;
		for(note in SONG.notes)
		{
			for(doubleNote in SONG.notes)
			{
				if(note != doubleNote
                && note.stepTime == doubleNote.stepTime
                && note.lane == doubleNote.lane)
				{
					SONG.notes.remove(doubleNote);
					removed++;
				}
			}
		}
		if(removed > 0)
			Logs.print('removed $removed duplicated notes');

		/*if(SONG.gfVersion == null)
			SONG.gfVersion = "stage-set";*/
		
		return SONG;
	}
}