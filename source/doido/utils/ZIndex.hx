package doido.utils;

import flixel.FlxBasic;
import flixel.util.FlxSort;

//does this suck?

class ZIndex
{
    public static var zMap:Map<FlxBasic, Int> = new Map<FlxBasic, Int>();

    public static function getZ(bas:FlxBasic):Int
        return zMap.get(bas) ?? 0; // the double question marks basically check if its null and if it is it sets the second value

    public static function setZ(bas:FlxBasic, val:Int):Void
        zMap.set(bas, val);

    public static function removeZ(bas:FlxBasic)
        zMap.remove(bas);

    public static function sort(a:Int, bas1:FlxBasic, bas2:FlxBasic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, bas1.getZ(), bas2.getZ());
}