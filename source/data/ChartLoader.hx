package data;

import flixel.util.FlxSort;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import gameObjects.hud.note.Note;

using StringTools;

class ChartLoader
{
	public static function getChart(SONG:SwagSong):Array<Note>
	{
		var unspawnNotes:Array<Note> = [];

		var daSection:Int = 0;
		
		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.stepCrochet;
		
		for(section in SONG.notes)
		{
			/*for(event in Conductor.bpmChangeMap)
				if(event.stepTime == (daSection * 16))
				{
					noteCrochet = Conductor.calcStep(event.bpm);
					trace('changed note bpm ${event.bpm}');
				}*/
			
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
				
				// create the new note
				var swagNote:Note = new Note();
				swagNote.reloadNote(daStrumTime, daNoteData, daNoteType);

				unspawnNotes.push(swagNote);

				var isPlayer = (songNotes[1] >= 4);
				if(section.mustHitSection)
					isPlayer = (songNotes[1] <  4);

				swagNote.strumlineID = isPlayer ? 1 : 0;

				var susLength:Float = songNotes[2];
				if(susLength > 0)
				{
					var holdNote:Note = new Note();
					holdNote.isHold = true;
					holdNote.reloadNote(daStrumTime, daNoteData, daNoteType);

					var holdNoteEnd:Note = new Note();
					holdNoteEnd.isHold = holdNoteEnd.isHoldEnd = true;
					holdNoteEnd.reloadNote(daStrumTime, daNoteData, daNoteType);

					holdNote.parentNote = swagNote;
					holdNoteEnd.parentNote = holdNote;

					holdNote.strumlineID = holdNoteEnd.strumlineID = swagNote.strumlineID;

					swagNote.holdLength = susLength;
					holdNote.holdLength = susLength;
					holdNoteEnd.holdLength = susLength;

					unspawnNotes.push(holdNote);
					unspawnNotes.push(holdNoteEnd);
				}
			}
			daSection++;
		}

		/*for(note in unspawnNotes)
		{
			for(doubleNote in unspawnNotes)
			{
				if(doubleNote.songTime == note.songTime
				&& doubleNote.noteData == note.noteData
				&& !doubleNote.isHold && !note.isHold
				&& doubleNote != note)
					unspawnNotes.remove(doubleNote);
			}
		}*/

		unspawnNotes.sort(NoteUtil.sortByShit);

		return unspawnNotes;
	}
}