package states.menu;

import backend.song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var optionShit:Array<String> = ["story mode", "freeplay", "donate", "credits", "options"];
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
		
		DiscordIO.changePresence("In the Main Menu");

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
		
		if(FlxG.random.bool(0.001))
		{
			if(Paths.fileExists('images/herobrine.png'))
			{
				var herobrine = new FlxSprite(-300).loadGraphic(Paths.image('herobrine'));
				herobrine.scale.set(4,4);
				herobrine.updateHitbox();
				herobrine.screenCenter(Y);
				add(herobrine);

				new FlxTimer().start(2, function(tmr) {
					if(herobrine != null)
						remove(herobrine);
				});
			}
		}
		
		grpOptions = new FlxTypedGroup<FlxSprite>();
		add(grpOptions);
		
		var optionSize:Float = 0.9;
		if(optionShit.length > 4)
		{
			for(i in 0...(optionShit.length - 4))
				optionSize -= 0.04;
		}
		
		for(i in 0...optionShit.length)
		{
			var item = new FlxSprite();
			item.frames = Paths.getSparrowAtlas('menu/mainmenu/' + optionShit[i].replace(' ', '-'));
			item.animation.addByPrefix('idle',  optionShit[i] + ' basic', 24, true);
			item.animation.addByPrefix('hover', optionShit[i] + ' white', 24, true);
			item.animation.play('idle');
			grpOptions.add(item);
			
			item.scale.set(optionSize, optionSize);
			item.updateHitbox();
			
			var itemSize:Float = (90 * optionSize);
			
			var minY:Float = 40 + itemSize;
			var maxY:Float = FlxG.height - itemSize - 40;
			
			if(optionShit.length < 4)
			for(i in 0...(4 - optionShit.length))
			{
				minY += itemSize;
				maxY -= itemSize;
			}
			
			item.x = FlxG.width / 2;
			item.y = FlxMath.lerp(
				minY, // gets min Y
				maxY, // gets max Y
				i / (optionShit.length - 1) // sorts it according to its ID
			);
			
			item.ID = i;
		}
		
		var doidoSplash:String = 'Doido Engine ${lime.app.Application.current.meta.get('version')}';
		var funkySplash:String = 'Friday Night Funkin\' Rewritten';

		var splashTxt = new FlxText(4, 0, 0, '$doidoSplash\n$funkySplash');
		splashTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF, LEFT);
		splashTxt.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
		splashTxt.y = FlxG.height - splashTxt.height - 4;
		add(splashTxt);

		changeSelection();
		bg.y = bgPosY;

		#if TOUCH_CONTROLS
		createPad("back");
		#end
	}
	
	var selectedSum:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if debug
		// Crash the game. For CrashHandler test purposes
		if(FlxG.keys.justPressed.R)
			null.draw();
		#end

		if(FlxG.keys.justPressed.V)
		{
			persistentUpdate = false;
			openSubState(new subStates.video.VideoPlayerSubState("test"));
		}

		if(FlxG.keys.justPressed.EIGHT)
		{
			FlxG.sound.play(Paths.sound("menu/cancelMenu"));
			Main.switchState(new states.editors.CharacterEditorState("bf", false));
		}
		
		if(!selectedSum)
		{
			if(Controls.justPressed(UI_UP))
				changeSelection(-1);
			if(Controls.justPressed(UI_DOWN))
				changeSelection(1);
			
			if(Controls.justPressed(BACK))
				Main.switchState(new TitleState());
			
			if(Controls.justPressed(ACCEPT))
			{
				if(["donate"].contains(optionShit[curSelected]))
				{
					CoolUtil.openURL("https://ninja-muffin24.itch.io/funkin");
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
							
							case "credits":
								Main.switchState(new CreditsState());

							case "options":
								Main.switchState(new OptionsState());

							default: // avoids freezing
								Main.resetState();
						}
					});
				}
			}
		}
		else
		{
			if(SaveData.data.get('Flashing Lights') != "OFF")
			{
				if(SaveData.data.get('Flashing Lights') != "REDUCED")
				{
					flickMag += elapsed;
					if(flickMag >= 0.15)
					{
						flickMag = 0;
						bgMag.visible = !bgMag.visible;
					}
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
		}
		
		bg.y = FlxMath.lerp(bg.y, bgPosY, elapsed * 6);
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
