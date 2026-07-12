package objects;

import doido.objects.DoidoSprite;

typedef DoidoCharacter =
{
	var spritesheet:String;
	var ?extrasheets:Array<String>;
	var ?spriteType:String;
	var ?atlasType:String;

	var anims:Array<Animation>;
	var ?idleAnims:Array<String>;
	var ?quickDancer:Bool;
	var ?deathChar:String;

	var ?globalOffset:DoidoPoint;
	var ?cameraOffset:DoidoPoint;

	var ?singLength:Float;
	var ?singType:String;

	var ?alpha:Float;
	var ?angle:Float;
	var ?scale:DoidoPoint;
	var ?pixel:Bool;
	var ?flipX:Bool;
	var ?flipY:Bool;
}

enum SingType
{
	FIRST;
	LAST;
	LOOP;
}

class Character extends DoidoSprite
{
	public var curChar:String = "bf";
	public var isPlayer:Bool = false;

	public var dataPath:String = "data/characters/";
	public var spritePath:String = "characters/";

	public var data:DoidoCharacter;

	public function new(curChar:String = "bf", isPlayer:Bool = false)
	{
		super(0, 0);
		this.curChar = curChar;
		this.isPlayer = isPlayer;
		loadCharacter();
	}

	public var debugMode:Bool = false;
	public var forceLoop:Bool = false;

	public var idleAnims(default, set):Array<String> = ["idle"];
	public var quickDancer:Bool = false;
	public var deathChar:String = "bf-dead";

	public var singType:SingType = LAST;
	public var singLength:Float = 0.7;
	public var singStep:Float = 0.0;
	public var singLoop:Int = 4;

	public var globalOffset:DoidoPoint = {x: 0, y: 0};
	public var cameraOffset:DoidoPoint = {x: 0, y: 0};
	public var scaleOffset:DoidoPoint = {x: 0, y: 0};

	public function loadCharacter(reload:Bool = false)
	{
		if (!reload)
		{
			try
			{
				data = cast(Assets.json('$dataPath$curChar'));
			}
			catch (e)
			{
				Logs.print('CHAR $curChar LOAD ERROR: $e', ERROR);
				data = defaultCharacter();
			}
		}

		spriteType = DoidoSprite.stringToSpriteType(data.spriteType);
		atlasType = DoidoSprite.stringToAtlasType(data.atlasType);

		var extrasheets:Array<String> = [];
		if ((data.extrasheets ?? []).length > 0)
		{
			for (sheet in (data.extrasheets ?? []))
				extrasheets.push('images/$spritePath$sheet');
		}

		frames = cast Assets.framesCollection('$spritePath${data.spritesheet}', extrasheets, spriteType);
		for (animData in data.anims)
			addAnim(animData);

		idleAnims = data.idleAnims ?? idleAnims;
		quickDancer = data.quickDancer ?? quickDancer;
		deathChar = data.deathChar ?? deathChar;

		singLength = data.singLength ?? singLength;
		singTypeFromString(data.singType);

		for (i in 0...idleAnims.length)
		{
			if (!animExists(idleAnims[i]))
				idleAnims[i] = "idle"; // ill fix this later?????
		}

		globalOffset = data.globalOffset ?? globalOffset;
		cameraOffset = data.cameraOffset ?? cameraOffset;

		angle = data.angle ?? 0.0;
		alpha = data.alpha ?? 1.0;
		data.scale ??= {x: 1, y: 1};
		scale.set(data.scale.x, data.scale.y);
		antialiasing = ((data.pixel == true) ? false : flixel.FlxSprite.defaultAntialiasing);
		flipX = data.flipX ?? false;
		flipY = data.flipY ?? false;

		if (isPlayer)
			flipX = !flipX;

		updateHitbox();

		playAnim(idleAnims[0], true, idleFrames);
	}

	public function singTypeFromString(type:Null<String>)
	{
		singType = switch ((type ?? "").toUpperCase())
		{
			case "LOOP": LOOP;
			case "FIRST": FIRST;
			default: LAST;
		}
	}

	private var curDance:Int = 0;

	public function dance(forced:Bool = false)
	{
		playAnim(idleAnims[curDance]);
		curDance++;
		if (curDance >= idleAnims.length)
			curDance = 0;
	}

	override function updateHitbox()
	{
		var prevAnim = {name: "", frame: 0};
		if (animation?.curAnim == null)
			prevAnim = null;
		else
			prevAnim = {
				name: animation.curAnim.name,
				frame: animation.curAnim.curFrame
			};

		if (idleAnims.length > 0)
			playAnim(idleAnims[0]);
		super.updateHitbox();
		scaleOffset = {x: offset.x, y: offset.y};

		if (prevAnim != null)
			playAnim(prevAnim.name, true, prevAnim.frame);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!debugMode)
		{
			if (animExists(curAnimName + '-loop') && curAnimFinished)
				playAnim(curAnimName + '-loop');
		}
		else
		{
			if (forceLoop && curAnimFinished)
				playAnim(curAnimName);
		}

		if (singStep > 0)
			singStep -= elapsed;
	}

	override public function updateOffset()
	{
		super.updateOffset();
		offset.x += scaleOffset.x;
		offset.y += scaleOffset.y;
	}

	public static function defaultCharacter():DoidoCharacter
	{
		return {
			spritesheet: "face",
			spriteType: "ATLAS",
			singType: "LAST",
			anims: [
				{
					name: "idle",
					prefix: "idle-alive",
					offset: {x: 0, y: 0}
				},
				{
					name: "singLEFT",
					prefix: "left-alive",
					offset: {x: 42, y: 0}
				},
				{
					name: "singDOWN",
					prefix: "down-alive",
					offset: {x: 0, y: 8}
				},
				{
					name: "singUP",
					prefix: "up-alive",
					offset: {x: 19, y: 40}
				},
				{
					name: "singRIGHT",
					prefix: "right-alive",
					offset: {x: -23, y: 13}
				}
			]
		};
	}

	override public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
	{
		if (!existsInList(animName))
			return;

		anim.play(animName, forced, false, frame);
		curAnimName = animName;

		updateOffset();
	}

	public var idleFrames(get, never):Int;

	public function get_idleFrames():Int
		return (anim.getByName(idleAnims[0]) == null) ? 0 : anim.getByName(idleAnims[0]).numFrames;

	public function set_idleAnims(a:Array<String>)
	{
		if (a.length >= 1)
			idleAnims = a;
		else
			idleAnims = ["idle"];

		return idleAnims;
	}
}
