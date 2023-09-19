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
		// cleaning multiple notes at the same place
		var removed:Int = 0;
		for(section in SONG.notes)
		{
			for(songNotes in section.sectionNotes)
			{
				for(doubleNotes in section.sectionNotes)
				{
					if(songNotes 	!= doubleNotes
					&& songNotes[0] == doubleNotes[0]
					&& songNotes[1] == doubleNotes[1]
					&& songNotes[2] == doubleNotes[2]
					&& songNotes[3] == doubleNotes[3])
					{
						section.sectionNotes.remove(doubleNotes);
						removed++;
					}
				}
			}
		}
		trace('removed $removed notes');
		
		// loading for real
		var unspawnNotes:Array<Note> = [];
		var daSection:Int = 0;
		
		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.stepCrochet;
		
		for(section in SONG.notes)
		{
			for(event in Conductor.bpmChangeMap)
				if(event.stepTime == (daSection * 16))
				{
					noteCrochet = Conductor.calcStep(event.bpm);
					trace('changed note bpm ${event.bpm}');
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
					var daParent:Note = swagNote;
					
					swagNote.holdLength = susLength;
					swagNote.noteCrochet = noteCrochet;
					
					var holdLoop:Int = Math.floor(susLength / noteCrochet);
					if (holdLoop <= 0)
						holdLoop = 1;
					
					for(j in 0...holdLoop)
					{
						var holdNote:Note = new Note();
						holdNote.isHold = true;
						holdNote.reloadNote(daStrumTime, daNoteData, daNoteType);
						
						holdNote.parentNote = daParent;
						holdNote.strumlineID = swagNote.strumlineID;
						
						// uhhh
						holdNote.holdLength = susLength;
						holdNote.noteCrochet = noteCrochet;
						
						unspawnNotes.push(holdNote);
						
						//holdNote.ID = j + 1;
						/*holdNote.color = flixel.util.FlxColor.fromRGB(
							FlxG.random.int(0,255),
							FlxG.random.int(0,255),
							FlxG.random.int(0,255)
						);*/
						
						daParent = holdNote;
					}
					
					var holdNoteEnd:Note = new Note();
					holdNoteEnd.isHold = holdNoteEnd.isHoldEnd = true;
					holdNoteEnd.reloadNote(daStrumTime, daNoteData, daNoteType);
					
					holdNoteEnd.parentNote = daParent;
					holdNoteEnd.strumlineID = daParent.strumlineID;
					
					holdNoteEnd.holdLength = susLength;
					holdNoteEnd.noteCrochet = noteCrochet;
					
					unspawnNotes.push(holdNoteEnd);
				}
			}
			daSection++;
		}
		
		unspawnNotes.sort(CoolUtil.sortByShit);
		
		return unspawnNotes;
	}
}