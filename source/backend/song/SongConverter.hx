package backend.song;

import backend.song.SongData.SwagNote;
import backend.song.SongData.SwagSong;

typedef OldSwagSong =
{
	var song:String;
	var notes:Array<OldSwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;

	// Parity with other engines
	var ?gfVersion:String;
}
typedef OldSwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var sectionBeats:Float;
}
typedef OldSwagEvent =
{
	var songEvents:Array<Dynamic>;
}

typedef OldBPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class SongConverter
{
    public inline static function updateDoidoChart(oldSONG:OldSwagSong):SwagSong
    {
		var SONG:SwagSong = {
			song: oldSONG.song,
			notes: [],
			speed: oldSONG.speed,
			bpm: oldSONG.bpm,

			player: oldSONG.player1,
			opponent: oldSONG.player2,
			gf: oldSONG.gfVersion == null ? "stage-set" : oldSONG.gfVersion,
		};

		// loading bpm change map
		var bpmChangeMap:Array<OldBPMChangeEvent> = [];
		if(true)
		{
			var curBPM:Float = oldSONG.bpm;
			var totalSteps:Int = 0;
			var totalPos:Float = 0;
			for (i in 0...oldSONG.notes.length)
			{
				if (oldSONG.notes[i].changeBPM && oldSONG.notes[i].bpm != curBPM)
				{
					curBPM = oldSONG.notes[i].bpm;
					var event:OldBPMChangeEvent = {
						stepTime: totalSteps,
						songTime: totalPos,
						bpm: curBPM
					};
					bpmChangeMap.push(event);
				}

				var deltaSteps:Int = oldSONG.notes[i].lengthInSteps;
				totalSteps += deltaSteps;
				totalPos += Conductor.calcStep(curBPM) * deltaSteps;
			}
		}

		var daSection:Int = 0;
		var noteCrochet:Float = Conductor.calcStep(oldSONG.bpm);
		for(section in oldSONG.notes)
		{
			for(event in bpmChangeMap)
				if(event.stepTime == (daSection * section.lengthInSteps))
				{
					noteCrochet = Conductor.calcStep(event.bpm);
					//Logs.print('changed note bpm ${event.bpm}');
				}
			
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = songNotes[1];
				var noteLength:Float = songNotes[2];
				var daNoteType:Null<String> = null; // 'none';
				// very stupid but I'm lazy
				if(songNotes.length > 2)
					daNoteType = songNotes[3];
				
				// psych event notes come on
				if(songNotes[1] < 0) continue;
				
				// create the new note
				var swagNote:SwagNote =
				{
					step: CoolUtil.floatPointFix(daStrumTime / noteCrochet),
					data: section.mustHitSection ? (daNoteData + 4) % 8 : daNoteData,
					holdLength: CoolUtil.floatPointFix(noteLength / noteCrochet),
				};
				if(daNoteType != null)
					swagNote.type = daNoteType;
				SONG.notes.push(swagNote);
			}
			daSection++;
		}
        return SONG;
    }

    public inline static function downgradeDoidoChart():OldSwagSong
    {
        return null;
    }
}

/*
// later
inline public static function baseToDoido()
{

}

inline public static function doidoToBase()
{

}
*/