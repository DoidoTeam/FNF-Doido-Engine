package data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

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
	//var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	//var altAnim:Bool;
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

	// stuff from fnf
	inline public static function loadFromJson(jsonInput:String, ?diff:String = "normal"):SwagSong
	{
		var formatPath = jsonInput + '-' + diff;
		
		if(!FileSystem.exists(Paths.getPath('songs/$jsonInput/$formatPath.json')))
			formatPath = '$jsonInput';
			
		trace('$jsonInput/$formatPath');
		
		var daSong:SwagSong = cast Paths.json('songs/$jsonInput/$formatPath').song;
		
		daSong.song = daSong.song.toLowerCase();
		if(daSong.song.contains(' '))
			daSong.song.replace(' ', '-');
		
		return daSong;
	}
}