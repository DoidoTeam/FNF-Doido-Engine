package doido.song.chart;

import doido.song.chart.Handler;

typedef LegacySong =
{
	var song:String;
	var notes:Array<LegacySection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	// Parity with other engines
	var ?gfVersion:String;
}

typedef LegacySection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	
	// psych suport
	var ?sectionBeats:Float;
}

typedef LegacyBPMChange =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Legacy
{
	inline public static function fromLegacy(LegacySong:LegacySong):DoidoSong
    {
        var SONG:DoidoSong = {
            song: LegacySong.song,
            notes: [],
            bpm: LegacySong.bpm,
            speed: LegacySong.speed,

            player1: LegacySong.player1,
            player2: LegacySong.player2,
        };

        var unspawnNotes:Array<NoteData> = [];
		var daSection:Int = 0;
		var daSteps:Int = 0;
		
		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.stepCrochet;
        var bpmChangeMap = getLegacyBPMChanges(LegacySong);
		
		for(section in LegacySong.notes)
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

                var LegacyNote:NoteData = {
                    stepTime: daStrumTime / noteCrochet,
                    lane: daNoteData,
                    strumline: isPlayer ? 1 : 0,
                    type: daNoteType,
                    length: 0
                };
				
                unspawnNotes.push(LegacyNote);
				
				var susLength:Float = songNotes[2];
				if(susLength > 0)
				{
					var rawLoop:Float = (susLength / noteCrochet);
					var holdLoop:Int = (
						(rawLoop - Math.floor(rawLoop) <= 0.8) ?
						Math.floor(rawLoop) : Math.round(rawLoop)
					);
					if (holdLoop <= 0) holdLoop = 1;

                    LegacyNote.length = holdLoop;
				}
			}
			daSteps += section.lengthInSteps;
			daSection++;
		}
		SONG.notes = unspawnNotes;
        return SONG;
    }

    public static function getLegacyBPMChanges(song:LegacySong):Array<LegacyBPMChange>
    {
        var bpmChangeMap:Array<LegacyBPMChange> = [];

        if (song == null) return [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:LegacyBPMChange = {
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
