package doido.utils;

import objects.Character.DoidoCharacter;
import doido.song.Conductor;
import doido.objects.DoidoSprite;
import flixel.util.FlxColor;

typedef PsychCharacter =
{
	var animations:Array<PsychAnim>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
}

typedef PsychAnim =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class CharacterUtil
{
	public static final DEFAULT_BPM:Int = 100; // bpm used for converting characters from engines with bpm dependant singing animations
	public static final DEFAULT_COLOR:FlxColor = FlxColor.GRAY; // default healthbar color

	public static function fromPsych(char:PsychCharacter):DoidoCharacter
	{
		// animations
		var anims:Array<Animation> = [];
		var danceIdle:Int = 0;
		for (anim in char.animations)
		{
			if (["danceLeft", "danceRight"].contains(anim.anim))
				danceIdle++;

			var offset = arrayToOffset(anim.offsets);
			offset.x /= char.scale;
			offset.y /= char.scale;

			anims.push({
				name: anim.anim,
				prefix: anim.name,
				framerate: anim.fps,
				loop: anim.loop,
				indices: anim.indices,
				offset: offset,
				flipX: false,
				flipY: false
			});
		}

		return {
			spritesheet: char.image.replace("characters/", ""),
			extrasheets: [],
			spriteType: "SPARROW",

			anims: anims,
			idleAnims: danceIdle >= 2 ? ["danceLeft", "danceRight"] : ["idle"],
			quickDancer: danceIdle >= 2,
			deathChar: "bf-dead",

			globalOffset: arrayToOffset(char.position),
			cameraOffset: arrayToOffset(char.camera_position),

			singLength: char.sing_duration * Conductor.calcStep(DEFAULT_BPM) * 0.0011,
			singType: "LAST",

			scale: {
				x: char.scale,
				y: char.scale
			},
			pixel: char.no_antialiasing,
			flipX: char.flip_x,
			flipY: false,
		};
	}

	public static function toPsych(char:DoidoCharacter, name:String = "face"):PsychCharacter
	{
		var scale:Float = char.scale?.x ?? 1.0;
		var anims:Array<PsychAnim> = [];
		for (anim in char.anims)
		{
			var offset = anim.offset ?? {x: 0.0, y: 0.0};
			anims.push({
				anim: anim.name,
				name: anim.prefix,
				fps: anim.framerate ?? 24,
				loop: anim.loop ?? false,
				indices: anim.indices ?? [],
				offsets: [Std.int(offset.x * scale), Std.int(offset.y * scale)]
			});
		}

		return {
			image: 'characters/${char.spritesheet}',
			animations: anims,
			scale: scale,
			sing_duration: (char.singLength ?? 0.7) / (Conductor.calcStep(DEFAULT_BPM) * 0.0011),
			healthicon: name,
			position: [char.globalOffset?.x ?? 0, char.globalOffset?.y ?? 0],
			camera_position: [char.cameraOffset?.x ?? 0, char.cameraOffset?.y ?? 0],
			flip_x: char.flipX ?? false,
			no_antialiasing: char.pixel ?? false,
			healthbar_colors: [DEFAULT_COLOR.red, DEFAULT_COLOR.green, DEFAULT_COLOR.blue],
			vocals_file: ""
		};
	}

	public static function arrayToOffset(off:Array<Dynamic>):DoidoPoint
		return {x: off[0] ?? 0, y: off[1] ?? 0};
}
