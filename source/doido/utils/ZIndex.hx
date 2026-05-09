package doido.utils;

import flixel.FlxBasic;
import flixel.util.FlxSort;

// does this suck?
class ZIndex
{
	public static inline function sort(a:Int, bas1:FlxBasic, bas2:FlxBasic):Int
		return FlxSort.byValues(a, bas1?.zIndex, bas2?.zIndex);

	public static inline function sortAscending(bas1:FlxBasic, bas2:FlxBasic):Int
		return sort(-1, bas1, bas2);

	public static inline function sortDescending(bas1:FlxBasic, bas2:FlxBasic):Int
		return sort(1, bas1, bas2);

	public static final deprecatedWarning:String = "ZIndex functions have been deprecated. Please use the zIndex field in a FlxBasic instead.";

	@:deprecated(deprecatedWarning)
	public static inline function getZ(bas:FlxBasic):Int
	{
		Logs.print(deprecatedWarning, WARNING);
		return bas.zIndex;
	}

	@:deprecated(deprecatedWarning)
	public static inline function setZ(bas:FlxBasic, val:Int):Void
	{
		if (bas == null)
			return;

		Logs.print(deprecatedWarning, WARNING);
		bas.zIndex = val;
	}

	@:deprecated(deprecatedWarning)
	public static inline function removeZ(bas:FlxBasic)
	{
		Logs.print(deprecatedWarning, WARNING);
	}
}
