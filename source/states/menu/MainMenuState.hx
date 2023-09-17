package states.menu;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import data.GameData.MusicBeatState;
import data.SongData;
import gameObjects.menu.Alphabet;
import gameObjects.menu.Alphabet.AlphabetAlign;

using StringTools;

class MainMenuState extends MusicBeatState
{
	/*static */var optionShit:Array<String> = ["story mode", "freeplay", "donate", "options"];
	static var curSelected:Int = 0;
	
	var grpOptions:FlxTypedGroup<FlxSprite>;
	
	var bg:FlxSprite;
	var bgMag:FlxSprite;
	var bgPosY:Float = 0;
	
	var flickMag:Float = 1;
	var flickBtn:Float = 1;
	
	override function create()
	{
		super.create();
		CoolUtil.playMusic("freakyMenu");
		
		#if !desktop
			optionShit.remove('donate');
		#end

		DiscordClient.changePresence("Main Menu", null);
		//persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuBG'));
		bg.scale.set(1.2,1.2);
		bg.updateHitbox();
		bg.screenCenter(X);
		add(bg);
		
		bgMag = new FlxSprite().loadGraphic(Paths.image('menu/backgrounds/menuBGMagenta'));
		bgMag.scale.set(bg.scale.x, bg.scale.y);
		bgMag.updateHitbox();
		bgMag.visible = false;
		add(bgMag);

		grpOptions = new FlxTypedGroup<FlxSprite>();
		add(grpOptions);
		
		var optionSize:Float = 0.9;
		if(optionShit.length > 4)
		{
			for(i in 0...(optionShit.length - 4))
				optionSize -= 0.05;
		}
		
		for(i in 0...optionShit.length)
		{
			var item = new FlxSprite();
			item.frames = Paths.getSparrowAtlas('menu/mainmenu/${optionShit[i].replace(' ', '-')}');
			item.animation.addByPrefix('idle',  '${optionShit[i]} basic', 24, true);
			item.animation.addByPrefix('hover', '${optionShit[i]} white', 24, true);
			item.animation.play('idle');
			grpOptions.add(item);
			
			item.scale.set(optionSize, optionSize);
			item.updateHitbox();
			
			item.x = FlxG.width / 2;
			item.y = FlxMath.lerp(
				10 + (90 * optionSize),
				FlxG.height - (90 * optionSize) - 10,
				i / (optionShit.length - 1)
			);
			
			item.ID = i;
		}

		changeSelection();
		bg.y = bgPosY;
	}
	
	//var itemSin:Float = 0;
	var selectedSum:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		/*if(FlxG.keys.justPressed.J)
		{
			optionShit.remove('options');
			Main.skipStuff();
			Main.switchState();
		}
		if(FlxG.keys.justPressed.K)
		{
			optionShit.push('options');
			Main.skipStuff();
			Main.switchState();
		}*/
		/*itemSin += elapsed * Math.PI;
		for(item in grpOptions.members)
		{
			item.x = (FlxG.width / 2) + (Math.sin(itemSin + item.ID) * FlxG.width / 4);
		}*/
		
		if(!selectedSum)
		{
			if(Controls.justPressed("UI_UP"))
				changeSelection(-1);
			if(Controls.justPressed("UI_DOWN"))
				changeSelection(1);
			
			if(Controls.justPressed("BACK"))
				Main.switchState(new TitleState());
			
			if(Controls.justPressed("ACCEPT"))
			{
				if(["donate"].contains(optionShit[curSelected]))
				{
					switch(optionShit[curSelected])
					{
						case "donate":
							FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
					}
				}
				else
				{
					selectedSum = true;
					FlxG.sound.play(Paths.sound('menu/confirmMenu'));
					
					for(item in grpOptions.members)
					{
						if(item.ID != curSelected)
							FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.cubeOut});
					}
					
					new FlxTimer().start(1.5, function(tmr:FlxTimer)
					{
						switch(optionShit[curSelected])
						{
							case "story mode":
								Main.switchState(new StoryMenuState());
						
							case "freeplay":
								Main.switchState(new FreeplayState());

							case "options":
								Main.switchState(new OptionsState());
						}
					});
				}
			}
		}
		else
		{
			flickMag += elapsed;
			if(flickMag >= 0.15)
			{
				flickMag = 0;
				bgMag.visible = !bgMag.visible;
			}
			
			flickBtn += elapsed;
			if(flickBtn >= 0.15 / 2)
			{
				flickBtn = 0;
				for(item in grpOptions.members)
					if(item.ID == curSelected)
						item.visible = !item.visible;
			}
		}
		
		bg.y = FlxMath.lerp(bg.y, bgPosY, elapsed * 8);
		bgMag.setPosition(bg.x, bg.y);
	}

	public function changeSelection(change:Int = 0)
	{
		if(change != 0) FlxG.sound.play(Paths.sound('menu/scrollMenu'));
		
		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, optionShit.length - 1);
		
		bgPosY = FlxMath.lerp(0, -(bg.height - FlxG.height), curSelected / (optionShit.length - 1));
		
		for(item in grpOptions.members)
		{
			item.animation.play('idle');
			if(curSelected == item.ID)
				item.animation.play('hover');
			
			item.updateHitbox();
			// makes it offset to its middle point
			item.offset.x += (item.frameWidth * item.scale.x) / 2;
			item.offset.y += (item.frameHeight* item.scale.y) / 2;
		}
	}
}
