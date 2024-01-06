package gameObjects.hud;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.group.FlxGroup;
import states.PlayState;

class HealthBar extends FlxGroup
{
	public var bg:FlxSprite;
	
	public var sideL:FlxSprite;
	public var sideR:FlxSprite;
	
	public var icons:Array<HealthIcon> = [];
	
	public var flipIcons:Bool = false;
	public var percent(default, set):Float = 0;
	
	public function new()
	{
		super();
		bg = new FlxSprite().loadGraphic(Paths.image("hud/base/healthBar"));
		bg.screenCenter();
		add(bg);
		
		var barSize:Array<Int> = [
			Math.floor(bg.width) - 8,
			Math.floor(bg.height) - 8
		];
		
		sideL = new FlxSprite();
		sideL.makeGraphic(barSize[0], barSize[1], 0xFFFFFFFF);
		sideR = new FlxSprite();
		sideR.makeGraphic(barSize[0], barSize[1], 0xFFFFFFFF);
		
		add(sideR);
		add(sideL);
		
		var SONG = PlayState.SONG;
		
		for(i in 0...2)
		{
			var icon = new HealthIcon();
			if(i == 0)
				icon.setIcon(SONG.player2, false);
			else
				icon.setIcon(SONG.player1, true);
			icons.push(icon);
			add(icon);
		}
		
		percent = 50;
		updatePos();
	}
	
	public function updatePos()
	{
		for(side in [sideL, sideR])
			side.setPosition(bg.x + 4, bg.y + 4);
		
		if(flipIcons)
			sideL.x += sideR.width - sideL.width;
		
		updateIconPos();
	}
	
	public function changeIcon(iconID:Int, newChar:String)
	{
		var icon = icons[Math.floor(FlxMath.bound(iconID, 0, icons.length - 1))];
		
		icon.setIcon(newChar, icon.isPlayer);
		
		sideL.color = HealthIcon.getColor(icons[0].curIcon);
		sideR.color = HealthIcon.getColor(icons[1].curIcon);
	}
	
	public function updateIconPos()
	{
		var health = (percent / 50);
		
		var formatHealth = (2 - health);
		if(flipIcons)
			formatHealth = health;

		var barX:Float = (bg.x + (bg.width * (formatHealth) / 2));
		var barY:Float = (bg.y + bg.height / 2);

		for(icon in icons)
		{
			icon.scale.set(
				FlxMath.lerp(icon.scale.x, 1, FlxG.elapsed * 6),
				FlxMath.lerp(icon.scale.y, 1, FlxG.elapsed * 6)
			);
			icon.updateHitbox();

			icon.y = barY - icon.height / 2 - 12;
			icon.x = barX;

			var leftIcon = icons[0];
			if(flipIcons)
				leftIcon = icons[1];

			if(icon == leftIcon)
				icon.x -= icon.width - 24;
			else
				icon.x -= 24;

			if(!icon.isPlayer)
				icon.setAnim(2 - health);
			else
				icon.setAnim(health);

			if(!flipIcons)
				icon.flipX = icon.isPlayer;
			else
				icon.flipX = !icon.isPlayer;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updatePos();
	}
	
	public function set_percent(v:Float)
	{
		percent = v;
		if(sideL != null && sideR != null)
		{
			sideL.scale.x = ((100 - percent) / 100);
			sideL.updateHitbox();
			updatePos();
		}
		return percent;
	}
}