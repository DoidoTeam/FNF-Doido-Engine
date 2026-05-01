package doido.utils;

import flixel.input.keyboard.FlxKey;
import hscript.iris.Iris;
import flixel.text.FlxText.FlxTextAlign;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class DoidoIris extends Iris
{
	public function new(path:String, ?parent:Dynamic, ?execute:Bool = true)
	{
		super(Assets.script(path), parent, {name: path, autoRun: execute, autoPreset: true});
		if (execute)
			call("new");
	}

	// ???????????
	override public function call(fun:String, ?args:Null<Array<Dynamic>>)
	{
		var ny:Dynamic = interp.variables.get(fun);
		try
		{
			if (ny != null && Reflect.isFunction(ny))
				return super.call(fun, args);
		}
		catch (e)
		{
			Logs.print('error parsing script: ' + e, ERROR);
		}
		return null;
	}

	override public function preset()
	{
		super.preset();

		// import.hx
		set("FlxG", FlxG);
		set("Assets", Assets);
		set("Paths", Assets);
		set("Controls", Controls);
		set("MusicBeat", MusicBeat);
		set("Save", Save);
		set("Logs", Logs);
		set("MathUtil", MathUtil);
		set("ZIndex", ZIndex);

		// abstracts
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxTextAlign", ScriptedTextAlign);
		set("FlxAxes", ScriptedAxes);
		set("FlxKey", ScriptedKeys);
		set("FlxTweenType", ScriptedTweenType);

		// extras
		set("FlxSprite", FlxSprite);
		set("FlxGroup", FlxGroup);
	}
}

// Some manual fixes for abstracts n stuff

class ScriptedTextAlign
{
	public static var LEFT = FlxTextAlign.LEFT;
	public static var CENTER = FlxTextAlign.CENTER;
	public static var RIGHT = FlxTextAlign.RIGHT;
	public static var JUSTIFY = FlxTextAlign.JUSTIFY;
}

class ScriptedAxes
{
	public static var X = 1;
	public static var Y = 2;
	public static var XY = 3;
	public static var NONE = 0;
}

class ScriptedTweenType
{
	public static var PERSIST = 1;
	public static var LOOPING = 2;
	public static var PINGPONG = 4;
	public static var ONESHOT = 8;
	public static var BACKWARD = 16;
}

class ScriptedKeys
{
	public static inline function fromString(s:String):Int
		return FlxKey.fromString(s);

	public static inline function toString(k:FlxKey):String
		return k.toString();
}
