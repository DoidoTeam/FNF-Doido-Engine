package backend.objects;

typedef DoidoOffsets = {
	var animOffsets:Array<Array<Dynamic>>;
	var globalOffset:Array<Float>;
	var cameraOffset:Array<Float>;
	var ratingsOffset:Array<Float>;
}
typedef DoidoCharacter = {
	var spritesheet:String;
	var anims:Array<Dynamic>;
	var ?extrasheets:Array<String>;
}

enum SpriteType
{
	SPARROW;
	PACKER;
	ASEPRITE;
	ATLAS;
	MULTISPARROW;
}

class CharacterData
{
	inline public static function defaultOffsets():DoidoOffsets
	{
		return {
			animOffsets: [
				//["idle",0,0],
			],
			globalOffset: [0,0],
			cameraOffset: [0,0],
			ratingsOffset:[0,0]
		};
	}
	inline public static function defaultChar():DoidoCharacter
	{
		return {
			spritesheet: 'characters/',
			anims: [],
		};
	}
}