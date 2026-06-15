package doido.utils;

class MemoryUtil
{
	public static var units:Array<String> = ["B", "KB", "MB", "GB", "TB", "PB"];

	/**
	 * Version of flixel's formatBytes function so a new array isnt created each call.
	 * @param bytes
	 * @return String
	 */
	inline public static function formatMemory(bytes:Float):String
	{
		var curUnit = 0;
		while (bytes >= 1024)
		{
			bytes /= 1024;
			curUnit++;
		}

		return (Math.round(bytes * 100) / 100) + (units[curUnit] ?? "");
	}
}
