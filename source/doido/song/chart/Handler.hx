package doido.song.chart;

import doido.utils.NoteUtil;
import doido.song.chart.Legacy;

typedef DoidoSong =
{
	var song:String;
	var notes:Array<NoteData>;
	var bpm:Float;
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

class Handler
{
    inline public static function loadSong(jsonInput:String, ?diff:String = "normal"):DoidoSong
	{		
		Logs.print('Chart Loaded: ' + '$jsonInput/$diff');

		if(!Assets.fileExists('songs/$jsonInput/chart/$diff.json'))
			diff = "normal";

		return parseSong(Assets.json('songs/$jsonInput/chart/$diff'));
	}

	inline public static function parseSong(content:Dynamic):DoidoSong
	{
		var rawSong:Dynamic = cast content;
		var SONG:DoidoSong = null;
		
        if (!Std.isOfType(rawSong.song, String))
            SONG = Legacy.fromLegacy(rawSong.song);
		else
        	SONG = cast rawSong;

        return formatSong(SONG);
	}

    // Removes duplicated notes from a chart.
	inline private static function formatSong(SONG:DoidoSong):DoidoSong
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
				&& note.strumline == doubleNote.strumline
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

		SONG.notes.sort(NoteUtil.sortByStep);
		
		return SONG;
	}
}