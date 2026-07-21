package doido.utils;

import flixel.sound.FlxSound;
import doido.song.SongHandler.EventData;
import doido.song.SongHandler.NoteData;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

class NoteUtil
{
	public static var noteTypes:Array<String> = ['none', 'no animation', 'gf note', 'hurt note', 'warn note',];

	public static var directions:Array<String> = [];

	public static function setUpDirections(howMany:Int = 4)
	{
		if (howMany < 1)
			howMany = 1;
		if (howMany > 9)
			howMany = 9;
		directions = switch (howMany)
		{
			case 1: ["middle"];
			case 2: ["left", "right"];
			case 3: ["left", "middle", "right"];
			case 4: ["left", "down", "up", "right"];
			case 5: ["left", "down", "middle", "up", "right"];
			case 6: ["left", "down", "right", "left-alt", "up", "right-alt"];
			case 7: ["left", "down", "right", "middle", "left-alt", "up", "right-alt"];
			case 8: ["left", "down", "up", "right", "left-alt", "down-alt", "up-alt", "right-alt"];
			case 9: [
					"left",
					"down",
					"up",
					"right",
					"middle",
					"left-alt",
					"down-alt",
					"up-alt",
					"right-alt"
				];
			default: ["how???"];
		}
	}

	public static function getSingAnims(howMany:Int = 4):Array<String>
	{
		if (howMany < 1)
			howMany = 1;
		if (howMany > 9)
			howMany = 9;
		return switch (howMany)
		{
			case 1: ["singUP"];
			case 2: ["singLEFT", "singRIGHT"];
			case 3: ["singLEFT", "singUP", "singRIGHT"];
			case 4: ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
			case 5: ["singLEFT", "singDOWN", "singUP", "singUP", "singRIGHT"];
			case 6: ["singLEFT", "singDOWN", "singRIGHT", "singLEFT", "singUP", "singRIGHT"];
			case 7: ["singLEFT", "singDOWN", "singRIGHT", "singUP", "singLEFT", "singUP", "singRIGHT"];
			case 8: [
					"singLEFT",
					"singDOWN",
					"singUP",
					"singRIGHT",
					"singLEFT",
					"singDOWN",
					"singUP",
					"singRIGHT"
				];
			case 9: [
					"singLEFT",
					"singDOWN",
					"singUP",
					"singRIGHT",
					"singUP",
					"singLEFT",
					"singDOWN",
					"singUP",
					"singRIGHT"
				];
			default: ["how???"];
		}
	}

	public static function intToString(data:Int):String
		return directions[data] ?? "left";

	public static function stringToInt(direction:String):Int
		return directions.indexOf(direction) ?? 0;

	inline public static function getHitsounds():Array<String>
	{
		var hits = Assets.textToArray('sounds/hitsounds/hitsound-order');
		hits.push("OFF");
		return hits;
	}

	inline public static function playHitsound(?key:String, ?volume:Float):FlxSound
	{
		if (key == null)
			key = Save.data.hitsound;
		if (key == "OFF")
			return null;
		if (!Assets.fileExists("sounds/hitsounds/" + key, SOUND))
			return null;

		var hitsound = FlxG.sound.load(Assets.sound("hitsounds/" + key));
		hitsound.volume = volume ?? Save.data.hitsoundVolume;
		hitsound.play();
		return hitsound;
	}

	public static var missSoundList:Array<String> = [];

	public static function loadMissSounds()
	{
		missSoundList = Assets.list("sounds/miss", true, SOUND);
		for (i in 0...missSoundList.length)
		{
			missSoundList[i] = 'miss/${missSoundList[i]}';
			FlxG.sound.play(Assets.sound(missSoundList[i]), 0.0);
		}
	}

	inline public static function playMissSound(?preload:Bool = false)
	{
		FlxG.sound.play(Assets.sound(FlxG.random.getObject(missSoundList)), 0.6);
	}

	public static var loadedQuantColors:Map<String, Array<Array<FlxColor>>> = [];

	public static function getQuantColors(skin:String):Array<Array<FlxColor>>
	{
		if (!loadedQuantColors.exists(skin))
			switch (skin)
			{
				default:
					loadedQuantColors.set(skin, Assets.loadPaletteFromFile("ui/notes/base/quant/palette"));
					// if you'd rather use a hardcoded array
					// instead of an image palette, here you go
					/*loadedQuantColors.set(
							skin,
							[
								[0xFFff3535, 0xFFFFFFFF, 0xFF651038], // red
								[0xFF536bef, 0xFFFFFFFF, 0xFF0f1c54], // blue
								[0xFFc24b99, 0xFFFFFFFF, 0xFF3c1f56], // magenta
								[0xFF00e550, 0xFFFFFFFF, 0xFF0a4447], // lime
								[0xFF606789, 0xFFFFFFFF, 0xFF232a4c], // gray
								[0xFFff7ad7, 0xFFFFFFFF, 0xFF4d0954], // pink
								[0xFFffe83d, 0xFFFFFFFF, 0xFF514100], // yellow
								[0xFFae36e6, 0xFFFFFFFF, 0xFF19246a], // purple
								[0xFF0fe7ff, 0xFFFFFFFF, 0xFF153e72], // cyan
								[0xFF606789, 0xFFFFFFFF, 0xFF232a4c], // light gray
							];
						); */
			}

		return loadedQuantColors.get(skin);
	}

	public static final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192];

	public static function calcQuant(data:NoteData)
	{
		var stepInMeasure:Float = data.stepTime % 16;

		var bestError:Float = 9999;
		var bestIndex:Int = 0;

		for (i in 0...NoteUtil.quantArray.length)
		{
			var division:Int = NoteUtil.quantArray[i];

			var spacing:Float = 16 / division;
			var snapped:Float = Math.round(stepInMeasure / spacing) * spacing;
			var error:Float = Math.abs(stepInMeasure - snapped);

			if (error < bestError)
			{
				bestError = error;
				bestIndex = i;
			}
		}

		// tolerance
		if (bestError <= 0.05)
			return bestIndex;
		else
			return 0;
	}

	inline public static function noteWidth(wide:Bool = false)
		return (160 * 0.7) + (wide ? 70 : 0); // 112

	public static function setNotePos(note:FlxSprite, strum:FlxSprite, angle:Float, offsetX:Float, offsetY:Float)
	{
		var radAngle = FlxAngle.asRadians(angle);
		var cosAngle = Math.cos(radAngle);
		var sinAngle = Math.sin(radAngle);

		note.x = strum.x + (cosAngle * offsetX) + (sinAngle * offsetY);
		note.y = strum.y + (cosAngle * offsetY) + (sinAngle * offsetX);
	}

	public static function sortNotes(Obj1:NoteData, Obj2:NoteData):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.stepTime, Obj2.stepTime);

	public static function getNoteSprite(name:String):String
	{
		var num = name.split(". ");
		var noteName:String = num[1].toLowerCase().replace(' ', '_');

		if (!Assets.fileExists('images/editors/charting/notetypes/$noteName', IMAGE))
			noteName = "unknown_notetype";

		return 'editors/charting/notetypes/$noteName';
	}
}
