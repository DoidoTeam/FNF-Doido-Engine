package doido.objects;

import animate.FlxAnimate;
import flixel.math.FlxAngle;

typedef Animation =
{
	var name:String;
	var prefix:String;
	var ?framerate:Int;
	var ?loop:Bool;
	var ?offset:DoidoPoint;
	var ?indices:Array<Int>;
	var ?flipX:Bool;
	var ?flipY:Bool;
}

enum SpriteType
{
	SPARROW;
	ATLAS;
	PACKER;
	ASEPRITE;
	MULTISPARROW;
	FONT; // ONLY USE FOR FONTS!!!
}

enum AtlasType
{
	SYMBOL;
	FRAMELABEL;
	TIMELINE; // WEIRD AND DANGEROUS
}

class DoidoSprite extends FlxAnimate
{
	public var curAnimName:String = '';
	public var curAnimFrame(get, never):Int;
	public var curAnimFinished(get, never):Bool;
	public var curAnimPaused(get, never):Bool;
	public var animOffsets:Map<String, DoidoPoint> = [];
	public var animList:Array<String> = [];

	public var spriteType:SpriteType = SPARROW;
	public var atlasType:AtlasType = SYMBOL;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
	};

	public function addOffset(animName:String, offset:DoidoPoint)
	{
		animOffsets.set(animName, offset);
	}

	public function getOffset(animName:String):DoidoPoint
	{
		if (!animExists(animName))
			return {x: 0, y: 0};
		return animOffsets.get(animName);
	}

	public function addToOffset(animName:String, x:Float = 0, y:Float = 0)
	{
		if (!animExists(animName))
			return;
		animOffsets.get(animName).x += x;
		animOffsets.get(animName).y += y;
	}

	public function removeOffset(animName:String)
	{
		if (animOffsets.exists(animName))
			animOffsets.remove(animName);
	}

	public function clearOffsets()
	{
		animOffsets = [];
	}

	public function addAnim(animData:Animation, ?index:Int)
	{
		if (spriteType == ATLAS)
		{
			switch (atlasType)
			{
				case TIMELINE:
					if ((animData.indices ?? []).length > 0)
						anim.addByTimelineIndices(animData.name, library.timeline, animData.indices, animData.framerate ?? 24, animData.loop ?? false,
							animData.flipX ?? false, animData.flipY ?? false);
					else
						anim.addByTimeline(animData.name, library.timeline, animData.framerate ?? 24, animData.loop ?? false, animData.flipX ?? false,
							animData.flipY ?? false);
				case FRAMELABEL:
					if ((animData.indices ?? []).length > 0)
						anim.addByFrameLabelIndices(animData.name, animData.prefix, animData.indices, animData.framerate ?? 24, animData.loop ?? false,
							animData.flipX ?? false, animData.flipY ?? false);
					else
						anim.addByFrameLabel(animData.name, animData.prefix, animData.framerate ?? 24, animData.loop ?? false, animData.flipX ?? false,
							animData.flipY ?? false);
				default: // SYMBOL
					if ((animData.indices ?? []).length > 0)
						anim.addBySymbolIndices(animData.name, animData.prefix, animData.indices, animData.framerate ?? 24, animData.loop ?? false,
							animData.flipX ?? false, animData.flipY ?? false);
					else
						anim.addBySymbol(animData.name, animData.prefix, animData.framerate ?? 24, animData.loop ?? false, animData.flipX ?? false,
							animData.flipY ?? false);
			}
		}
		else
		{
			if ((animData.indices ?? []).length > 0)
				anim.addByIndices(animData.name, animData.prefix, animData.indices, "", animData.framerate ?? 24, animData.loop ?? false,
					animData.flipX ?? false, animData.flipY ?? false);
			else
				anim.addByPrefix(animData.name, animData.prefix, animData.framerate ?? 24, animData.loop ?? false, animData.flipX ?? false,
					animData.flipY ?? false);
		}

		if (animData.offset != null)
			addOffset(animData.name, animData.offset);

		if (index != null)
			animList.insert(index, animData.name);
		else
			animList.push(animData.name);
	}

	public function removeAnim(animName:String)
	{
		anim.remove(animName);
		animList.remove(animName);
		animOffsets.remove(animName);
	}

	public function clearAnims()
	{
		if (animList.length <= 0)
			return;

		for (anim in animList)
		{
			this.anim.remove(anim);
			animOffsets.remove(anim);
		}

		animList = [];
	}

	public function playAnim(animName:String, forced:Bool = true, frame:Int = 0)
	{
		if (!animExists(animName))
			return;

		anim.play(animName, forced, false, frame);
		curAnimName = animName;

		updateOffset();
	}

	// use this to modify the sprite's origin
	public function preUpdateOffset()
	{
		offset.set(0, 0);
	}

	public function updateOffset()
	{
		preUpdateOffset();
		if (animOffsets.exists(curAnimName))
		{
			var radAngle = FlxAngle.asRadians(angle);
			var daOffset = animOffsets.get(curAnimName);

			var offsetX = daOffset.x * scale.x;
			var offsetY = daOffset.y * scale.y;

			var cosAngle = Math.cos(radAngle);
			var sinAngle = Math.sin(radAngle);

			offset.x += (offsetX * cosAngle) - (offsetY * sinAngle);
			offset.y += (offsetX * sinAngle) + (offsetY * cosAngle);
		}
	}

	public static function stringToSpriteType(type:Null<String>)
	{
		return switch ((type ?? "").toUpperCase())
		{
			case "ATLAS" | "SPRITEMAP" | "ANIMATE":
				ATLAS;
			case "PACKER":
				PACKER;
			case "ASEPRITE":
				ASEPRITE;
			case "MULTISPARROW":
				MULTISPARROW;
			default:
				SPARROW;
		}
	}

	public static function stringToAtlasType(type:Null<String>)
	{
		return switch ((type ?? "").toUpperCase())
		{
			case "FRAMELABEL": FRAMELABEL;
			case "TIMELINE": TIMELINE;
			default: SYMBOL;
		}
	}

	public function animExists(animName:String):Bool
		return (anim.getByName(animName) != null);

	public function existsInList(animName:String):Bool
		return animList.contains(animName);

	public function get_curAnimFrame():Int
		return anim?.curAnim?.curFrame ?? 0;

	public function get_curAnimFinished():Bool
		return anim?.curAnim?.finished ?? false;

	public function get_curAnimPaused():Bool
		return anim?.curAnim?.paused ?? false;

	public static function copyAnim(anim:Animation):Animation
	{
		return {
			name: anim.name,
			prefix: anim.prefix,
			framerate: anim.framerate,
			loop: anim.loop,
			offset: MathUtil.copyPoint(anim.offset),
			indices: (anim.indices ?? []).copy(),
			flipX: anim.flipX,
			flipY: anim.flipY
		};
	}
}
