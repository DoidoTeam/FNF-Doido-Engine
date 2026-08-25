package doido.utils;

import flixel.text.FlxInputText;
import lime.app.Application;
import lime.ui.MouseCursor;
import haxe.Json;
import doido.song.SongHandler;

typedef AutoSaveSong =
{
	var CHART:String;
	var EVENTS:String;
	var META:String;
	var song:String;
	var diff:String;
	var date:String;
}

@:keep
@:structInit
class EditorVariables
{
	public var reducedAnimations:Bool = false;
	public var soundEffects:Bool = true;
	public var centerEvents:Bool = true;
	public var oldTimer:Bool = false;
	public var quantNotes:Bool = false;
	public var darkMode:Bool = false;
	public var quickCamSection:Bool = false;
}

class EditorSave
{
	public static final maxSaves:Int = 16;
	public static var savedSongs:Array<AutoSaveSong> = [];
	public static var data:EditorVariables = {};

	public static function save(?file:DoidoSave)
	{
		file = file ?? new DoidoSave("editors");
		file.data.savedSongs = savedSongs;
		for (key in Reflect.fields(data))
			Reflect.setField(file.data, key, Reflect.field(data, key));
		file.close();
	}

	public static function load()
	{
		var file = new DoidoSave("editors");
		if (file != null && file.data.savedSongs != null)
			savedSongs = file.data.savedSongs;
		else
			file.data.savedSongs = savedSongs;

		for (key in Reflect.fields(data))
		{
			if (Reflect.hasField(file.data, key))
				Reflect.setField(data, key, Reflect.field(file.data, key));
		}

		save(file);
	}

	// doido 3.x used to clone everything in order to save...
	// i dont have the patience to do all that so we save a
	// bunch of strings instead :fire:
	public static function addSong(SONG:DoidoSong, diff:String)
	{
		savedSongs.push({
			CHART: Json.stringify(SONG.CHART),
			EVENTS: Json.stringify(SONG.EVENTS),
			META: Json.stringify(SONG.META),
			song: SONG.CHART.song,
			diff: diff,
			date: Date.now().toString()
		});

		if (savedSongs.length > maxSaves)
			savedSongs.remove(savedSongs[0]);
		save();
	}
}

class EditorUtil
{
	/*
		ARROW
		CROSSHAIR
		DEFAULT
		MOVE
		POINTER
		RESIZE_NESW
		RESIZE_NS
		RESIZE_NWSE
		RESIZE_WE
		TEXT
		WAIT
		WAIT_ARROW
		CUSTOM
	 */
	public static function setCursor(newCursor:MouseCursor)
	{
		if (Application.current.window.cursor != newCursor)
			Application.current.window.cursor = newCursor;
	}

	public static function doidoSearch(arr:Array<String>, filter:String):Array<String>
	{
		var filtered:Array<String> = [];

		for (str in arr)
			if (str.toLowerCase().indexOf(filter.toLowerCase()) != -1)
				filtered.push(str);

		filtered.sort(function(a, b) return a.toLowerCase().indexOf(filter.toLowerCase()) - b.toLowerCase().indexOf(filter.toLowerCase()));

		return filtered;
	}

	public static var isTyping(get, never):Bool;

	public static function get_isTyping()
		return FlxInputText.globalManager.isTyping;
}
