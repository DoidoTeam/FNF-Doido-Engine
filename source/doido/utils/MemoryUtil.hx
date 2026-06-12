package doido.utils;
import flixel.math.FlxMath;
class MemoryUtil 
{
	/**
	 * Version of flixel's formatBytes function so a new array isnt created each call.
	 * @param Bytes 
	 * @param Precision 
	 * @return String
	 */
	inline public static function formatMemory(Bytes:Float, Precision:Int = 2):String
	{
		var curUnit = 0;
		while (Bytes >= 1024)
		{
			Bytes /= 1024;
			curUnit++;
		}
	   
	    return FlxMath.roundDecimal(Bytes, Precision) + getUnits(curUnit);
	}

    inline private static function getUnits(unit:Int)
    {
        switch(unit)
		{
			case 0:  return "Bytes";
			case 1: return  "KB";
			case 2: return  "MB";
			default: return  "GB";
		};
    }
}