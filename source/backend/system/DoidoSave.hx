package backend.system;

import flixel.util.FlxSave;

class DoidoSave extends FlxSave
{
	public function new(name:String)
	{
		super();
		bind(name, Main.savePath);
	}
}