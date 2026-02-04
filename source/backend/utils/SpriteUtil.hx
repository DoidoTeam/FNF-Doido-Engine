package backend.utils;

import flixel.FlxSprite;

class SpriteUtil
{
	public static function centerSpriteOffset(spr:FlxSprite)
	{
		spr.updateHitbox();
		spr.offset.x += spr.frameWidth * spr.scale.x / 2;
		spr.offset.y += spr.frameHeight * spr.scale.y / 2;
	}
}