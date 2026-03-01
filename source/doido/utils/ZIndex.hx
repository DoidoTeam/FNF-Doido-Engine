package doido.utils;

import flixel.FlxBasic;
import flixel.util.FlxSort;

//does this suck?

class ZIndex
{
    public static var zMap:Map<FlxBasic, Int> = new Map<FlxBasic, Int>();

    public static inline function getZ(bas:FlxBasic):Int
        return zMap.get(bas) ?? 0; // the double question marks basically check if its null and if it is it sets the second value

    public static inline function setZ(bas:FlxBasic, val:Int):Void
        zMap.set(bas, val);

    public static inline function removeZ(bas:FlxBasic)
        zMap.remove(bas);

    public static inline function sort(a:Int, bas1:FlxBasic, bas2:FlxBasic):Int
		return FlxSort.byValues(a, bas1.getZ(), bas2.getZ());

    public static inline function sortAscending(bas1:FlxBasic, bas2:FlxBasic):Int
		return sort(-1, bas1, bas2);

    public static inline function sortDescending(bas1:FlxBasic, bas2:FlxBasic):Int
		return sort(1, bas1, bas2);
}