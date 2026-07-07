package doido.song;

import doido.utils.EventUtil;
import objects.Character.DoidoCharacter;
import doido.utils.NoteUtil;
import doido.song.compat.Legacy;
import haxe.Json;

typedef DoidoSong =
{
	var CHART:DoidoChart;
	var EVENTS:DoidoEvents;
	var META:DoidoMeta;
}

typedef DoidoChart =
{
	var song:String;
	var notes:Array<NoteData>;
	var bpm:Float;
	var speed:Float;
}

typedef DoidoEvents =
{
	var events:Array<EventData>;
}

typedef DoidoMeta =
{
	var ?player1:String;
	var ?player2:String;
	var ?gf:String;
	var ?stage:String;
	var ?composer:String;
	var ?charter:String;
	var ?assets:AssetModifiers;
}

typedef AssetModifiers =
{
	var ?playerNotes:String;
	var ?opponentNotes:String;
	var ?hudType:String;
	var ?ratings:String;
	var ?countdown:String;
	var ?gameOverPath:String;
}

typedef NoteData =
{
	var stepTime:Float;
	var lane:Int;
	var strumline:Int;
	var type:String;
	var length:Float;
}

typedef EventData =
{
	var name:String;
	var stepTime:Float;
	var data:Array<Dynamic>;
	// var isCamera:Bool;
}

class SongHandler
{
	public static function loadSong(input:String, ?diff:String = "normal")
	{
		var converted:DoidoSong = convertChart(input, diff);
		return {
			CHART: converted.CHART,
			EVENTS: mergeEvents(loadEvents(input, diff), converted.EVENTS),
			META: mergeMetas(loadMeta(input, diff), converted.META)
		}
	}

	/* --- CHARTS --- */
	public static function loadChart(input:String, ?diff:String = "normal"):DoidoChart
		return convertChart(input, diff).CHART;

	public static function convertChart(input:String, diff:String):DoidoSong
	{
		var path:String = getPath(input, diff);
		var rawChart:Dynamic = cast Assets.json(path);

		var CHART:DoidoChart = null;
		var EVENTS:DoidoEvents = null;
		var META:DoidoMeta = null;

		switch (checkFormat(rawChart))
		{
			case "LEGACY":
				CHART = Legacy.getChartFromLegacy(rawChart.song);
				EVENTS = Legacy.getEventsFromLegacy(rawChart.song);
				META = Legacy.getMetaFromLegacy(rawChart.song);
			default:
				CHART = cast rawChart;
		}

		return {
			CHART: formatChart(CHART),
			EVENTS: EVENTS,
			META: META
		};
	}

	private static function formatChart(CHART:DoidoChart):DoidoChart
	{
		// Normalize song name to use only lowercases and no spaces
		CHART.song = formatName(CHART.song);

		// cleaning multiple notes at the same place
		var removed:Int = 0;
		for (note in CHART.notes)
		{
			if (note.type == null || note.type == "")
				note.type = "none";

			for (doubleNote in CHART.notes)
			{
				if (note != doubleNote
					&& note.strumline == doubleNote.strumline
					&& note.stepTime == doubleNote.stepTime
					&& note.lane == doubleNote.lane)
				{
					CHART.notes.remove(doubleNote);
					removed++;
				}
			}
		}
		if (removed > 0)
			Logs.print('removed $removed duplicated notes');

		CHART.notes.sort(NoteUtil.sortNotes);
		return CHART;
	}

	// to do later
	// maybe using filter?
	// private static function removeDuplicates(notes:Array<NoteData>) {}

	static inline function checkFormat(raw:Dynamic):String
		return Std.isOfType(raw.song, String) ? "DOIDO" : "LEGACY";

	/* --- CHARTS --- */
	public static function loadEvents(input:String, ?diff:String = "normal"):DoidoEvents
	{
		var path:String = getPath(input, diff, "events-", "events");

		if (!Assets.fileExists(path, JSON))
			return {events: []};

		return formatEvents(cast Assets.json(path));
	}

	private static function formatEvents(EVENTS:DoidoEvents):DoidoEvents
	{
		EVENTS.events.sort(EventUtil.sortEvents);
		return EVENTS;
	}

	// note: make better?
	private static function mergeEvents(a:DoidoEvents, b:DoidoEvents):DoidoEvents
	{
		if (a == null)
			return b;
		if (b == null)
			return a;

		return formatEvents({events: a.events.concat(b.events)});
	}

	public static function defaultMeta():DoidoMeta
	{
		return {
			player1: "bf",
			player2: "face",
			gf: "gf",
			stage: "stage",
			composer: "Unknown",
			charter: "Unknown",
			assets: {
				playerNotes: "base",
				opponentNotes: "base",
				hudType: "base",
				ratings: "base",
				countdown: "base",
				gameOverPath: "base",
			}
		};
	}

	/* --- METAS --- */
	public static function loadMeta(jsonInput:String, ?diff:String = "normal"):DoidoMeta
	{
		// default
		var meta:DoidoMeta = defaultMeta();
		var metaPath:String = 'songs/$jsonInput/meta';
		if (Assets.fileExists(metaPath, JSON))
			meta = mergeMetas(meta, cast Assets.json(metaPath));
		if (Assets.fileExists('$metaPath-$diff', JSON))
			meta = mergeMetas(meta, cast Assets.json('$metaPath-$diff'));

		return meta;
	}

	// B takes priority over A
	private static function mergeMetas(a:DoidoMeta, b:DoidoMeta):DoidoMeta
	{
		if (a == null)
			return b;
		if (b == null)
			return a;

		var meta:DoidoMeta = {};
		meta.player1 = (b.player1 ?? a.player1);
		meta.player2 = (b.player2 ?? a.player2);
		meta.gf = (b.gf ?? a.gf);
		meta.stage = (b.stage ?? a.stage);
		meta.composer = (b.composer ?? a.composer);
		meta.charter = (b.charter ?? a.charter);
		meta.assets = mergeAssets(a.assets, b.assets);

		/* -- INVESTIGATE LATER...
			for (key in Reflect.fields(a))
				Reflect.setField(meta, key, Reflect.field(Reflect.getProperty(b, key) ?? Reflect.getProperty(a, key), key));
		 */

		return meta;
	}

	private static function mergeAssets(a:AssetModifiers, b:AssetModifiers):AssetModifiers
	{
		if (a == null)
			return b;
		if (b == null)
			return a;

		var mod:AssetModifiers = {};
		mod.playerNotes = (b.playerNotes ?? a.playerNotes);
		mod.opponentNotes = (b.opponentNotes ?? a.opponentNotes);
		mod.hudType = (b.hudType ?? a.hudType);
		mod.ratings = (b.ratings ?? a.ratings);
		mod.countdown = (b.countdown ?? a.countdown);
		mod.gameOverPath = (b.gameOverPath ?? a.gameOverPath);

		return mod;
	}

	/* --- OTHER --- */
	public static function getPath(input:String, diff:String, prefix:String = "", fallback:String = "normal"):String
	{
		var path:String = 'songs/$input/chart/$prefix$diff';
		if (!Assets.fileExists(path, JSON))
			path = 'songs/$input/chart/$fallback';

		return path;
	}

	public static function formatName(name:String)
		return name.toLowerCase().replace(" ", "-");

	inline public static function parseChart(str:String):DoidoChart
		return formatChart(cast Json.parse(str));

	inline public static function parseEvents(str:String):DoidoEvents
		return formatEvents(cast Json.parse(str));

	inline public static function parseMeta(str:String):DoidoMeta
		return mergeMetas(cast Json.parse(str), defaultMeta());
}
