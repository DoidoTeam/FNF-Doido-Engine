package doido.utils;

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

class AutoSave
{
	public static final maxSaves:Int = 16;
	public static var savedSongs:Array<AutoSaveSong> = [];

	public static function save(?file:DoidoSave)
	{
		file = file ?? new DoidoSave("autosave");
		file.data.savedSongs = savedSongs;
		file.close();
	}

	public static function load()
	{
		var file = new DoidoSave("autosave");
		if (file != null && file.data != null && file.data.savedSongs != null)
			savedSongs = file.data.savedSongs;
		else
			file.data.savedSongs = savedSongs;
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
