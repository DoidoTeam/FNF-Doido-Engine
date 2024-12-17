package backend.song;

import backend.song.SongData.EventSong;
import backend.song.SongData.SwagSection;
import backend.song.SongData.SwagSong;
import objects.note.EventNote;
import objects.note.Note;

using StringTools;

/*
	Class that loads a chart from a SwagSong into an array of Notes
*/

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
			for(event in Conductor.bpmChangeMap)
				if(event.stepTime == (daSection * 16))
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
				
				// create the new note
				var swagNote:Note = new Note();
				swagNote.updateData(daStrumTime, daNoteData, daNoteType);
				
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
					
					var rawLoop:Float = (susLength / noteCrochet);
					var holdLoop:Int = (
						(rawLoop - Math.floor(rawLoop) <= 0.8) ?
						Math.floor(rawLoop) : Math.round(rawLoop)
					);
					if (holdLoop <= 0)
						holdLoop = 1;
					
					var holdID:Int = 0;
					for(j in 0...(holdLoop + 1))
					{
						var isHoldEnd = (j == holdLoop);
						
						var holdNote:Note = new Note();
						holdNote.isHold = true;
						holdNote.isHoldEnd = isHoldEnd;
						holdNote.updateData(daStrumTime, daNoteData, daNoteType);
						
						holdNote.parentNote = daParent;
						holdNote.strumlineID = swagNote.strumlineID;
						holdNote.ID = holdID;
						
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
						swagNote.children.push(holdNote);
						holdID++;
					}
				}
			}
			daSection++;
		}
		
		unspawnNotes.sort(CoolUtil.sortByShit);
		
		return unspawnNotes;
	}

	public static function getEvents(EVENTS:EventSong):Array<EventNote>
	{
		var unspawnEvents:Array<EventNote> = [];
		for(eventList in EVENTS.songEvents)
		{
			for(i in 0...eventList[2].length)
			{
				var event = eventList[2][i];
				if(event == null)
					event = [];
				for(z in 0...4)
					if(event[z] == null)
						event[z] = "";
				
				var eventNote = new EventNote();
				eventNote.updateData(eventList[1], -1);
				eventNote.eventName = event[0];
				eventNote.value1 = event[1];
				eventNote.value2 = event[2];
				eventNote.value3 = event[3];
				unspawnEvents.push(eventNote);
			}
		}
		unspawnEvents.sort(CoolUtil.sortByShit);
		return unspawnEvents;
	}
}