package data;

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

	inline static public function songJson(song:String)
		return 'assets/songs/${song}/${song}.json';

	// stuff from fnf
	inline public static function loadFromJson(jsonInput:String):SwagSong
	{
		var rawJson = File.getContent(songJson(jsonInput)).trim();

		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		return parseJSONshit(rawJson);
	}

	inline public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		return swagShit;
	}
}