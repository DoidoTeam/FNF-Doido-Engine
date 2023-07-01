package;

class NoteUtil
{
	public static function getDirection(i:Int)
		return ["left", "down", "up", "right"][i];

	public static function noteWidth()
	{
		return (160 * 0.7); // 112
	}
}