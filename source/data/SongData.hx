package data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

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
	//var assetModifier:String;
}
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	//var typeOfSection:Int;
	//var altAnim:Bool;
	
	// psych suport
	var ?sectionBeats:Float;
}
typedef EventSong = {
	// [0] = section // [1] = strumTime // [2] events
	var songEvents:Array<Dynamic>;
}

class SongData
{
	// use these to whatever
	inline public static function defaultSong():SwagSong
	{
		return
		{
			song: "test",
			notes: [],
			bpm: 100,
			needsVoices: true,
			speed: 1.0,

			player1: "bf",
			player2: "dad",
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
	// [0] = section // [1] = strumTime // [2] = label // [3] = values
	inline public static function defaultEventNote():Array<Dynamic>
		return [0, 0, []];
	inline public static function defaultEvent():Array<Dynamic>
		return ["name", "value1", "value2", "value3"];

	// stuff from fnf
	inline public static function loadFromJson(jsonInput:String, ?diff:String = "normal"):SwagSong
	{
		var formatPath = '$jsonInput-$diff';
		
		if(!Paths.fileExists('songs/$jsonInput/$formatPath.json'))
			formatPath = '$jsonInput';
			
		trace('Chart Loaded: ' + '$jsonInput/$formatPath');
		
		var daSong:SwagSong = cast Paths.json('songs/$jsonInput/$formatPath').song;
		
		// no need for SONG.song.toLowerCase() every time
		// the game auto-lowercases it now
		daSong.song = daSong.song.toLowerCase();
		if(daSong.song.contains(' '))
			daSong.song = daSong.song.replace(' ', '-');
		
		// formatting it
		daSong = formatSong(daSong);
		
		return daSong;
	}
	
	// 
	inline public static function formatSong(SONG:SwagSong):SwagSong
	{
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
			trace('removed $removed duplicated notes');
		
		return SONG;
	}

	inline public static function loadEventsJson(jsonInput:String, diff:String = "normal"):EventSong
	{
		var formatPath = 'events-$diff';

		function checkFile():Bool {
			return Paths.fileExists('songs/$jsonInput/$formatPath.json');
		}
		if(!checkFile())
			formatPath = 'events';
		if(!checkFile()) {
			trace('No Events Loaded');
			return {songEvents: []};
		}

		trace('Events Loaded: ' + '$jsonInput/$formatPath');

		var daEvents:EventSong = cast Paths.json('songs/$jsonInput/$formatPath');
		return daEvents;
	}
}