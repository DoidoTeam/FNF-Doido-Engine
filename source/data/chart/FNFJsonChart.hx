package data.chart;

import gameObjects.hud.note.Note;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import sys.io.File;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var speed:Float;
}
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
}
class FNFJsonChart
{
	public static function loadFromFNF(file:String):Array<Note>
	{	
		var songData:SwagSong = loadFromJson(file);
		var unspawnNotes:Array<Note> = [];

		Conductor.setBPM(songData.bpm);

		// load fnf style charts (PRE 2.8) but with a few tweaks
		var daSection:Int = 0;
		
		// bpm change stuff for sustain notes
		var noteCrochet:Float = Conductor.stepCrochet;
		
		for(section in songData.notes)
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
				var daNoteType:String = 'default';
				// very stupid but I'm lazy
				if(songNotes.length > 2)
					daNoteType = songNotes[3];
				
				// create the new note
				var swagNote:Note = new Note();
				swagNote.reloadNote(daStrumTime, daNoteData, daNoteType);

				//if(songNotes[1] >= 4) continue;

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

					holdNote.holdLength = susLength;

					unspawnNotes.push(holdNote);
					unspawnNotes.push(holdNoteEnd);
				}

				
				// oh and set the note's must hit section
				//swagNote.mustPress = gottaHitNote;
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
		
		return unspawnNotes;
	}

	inline static public function songJson(song:String)
		return 'assets/songs/${song}/chart.json';

	// stuff from fnf
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = File.getContent(songJson(jsonInput)).trim();

		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		return swagShit;
	}
}