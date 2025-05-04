package backend.utils;

typedef DoidoOffsets = {
	var animOffsets:Array<Array<Dynamic>>;
	var globalOffset:Array<Float>;
	var cameraOffset:Array<Float>;
}

typedef DoidoCharacter = {
	var spritesheet:String;
	var anims:Array<Dynamic>;
	var ?extrasheets:Array<String>;
}

enum SpriteType {
	SPARROW;
	PACKER;
	ASEPRITE;
	ATLAS;
	MULTISPARROW;
}

class CharacterUtil
{
	inline public static function defaultOffsets():DoidoOffsets
	{
		return {
			animOffsets: [
				//["idle",0,0],
			],
			globalOffset: [0,0],
			cameraOffset: [0,0]
		};
	}

	inline public static function defaultChar():DoidoCharacter
	{
		return {
			spritesheet: 'characters/',
			anims: [],
		};
	}

	inline public static function formatChar(char:String):String
		return char.substring(0, char.lastIndexOf('-'));

	public static function charList():Array<String>
	{
		return [
			"dad",
			"gf",
			"bf",
			"bf-dead",
			"bf-pixel",
			"bf-pixel-dead",
			"gf-pixel",
			"spooky",
			"spooky-player",
			"luano-day",
			"luano-night",
			"senpai",
			"senpai-angry",
			"spirit",
			"gemamugen",
			"zero",
			"face"
		];
	}
}