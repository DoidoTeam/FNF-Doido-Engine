package backend.song;

import backend.song.SongData.SwagSong;
import backend.song.SongData.SwagNote;
import backend.song.SongData.SwagEventSong;
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
		
		// load
		
		unspawnNotes.sort(CoolUtil.sortByShit);
		
		return unspawnNotes;
	}

	public static function getEvents(EVENTS:SwagEventSong):Array<EventNote>
	{
		var unspawnEvents:Array<EventNote> = [];
		/*for(eventList in EVENTS.songEvents)
		{
			/*for(i in 0...eventList[2].length)
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
		}*/
		unspawnEvents.sort(CoolUtil.sortByShit);
		return unspawnEvents;
	}
}