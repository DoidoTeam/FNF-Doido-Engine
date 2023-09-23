package states;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import data.ChartLoader;
import data.GameData.MusicBeatState;
import data.SongData.SwagSong;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import sys.thread.Mutex;
import sys.thread.Thread;

/*
*	preloads all the stuff before going into playstate
*	i would advise you to put your custom preloads inside here!!
*/
class LoadSongState extends MusicBeatState
{
	var threadActive:Bool = true;
	var mutex:Mutex;
	
	var behind:FlxGroup;
	var bg:FlxSprite;
	
	var loadBar:FlxSprite;
	var loadPercent:Float = 0;
	
	function addBehind(item:FlxBasic)
	{
		behind.add(item);
		behind.remove(item);
	}
	
	override function create()
	{
		super.create();
		mutex = new Mutex();
		
		behind = new FlxGroup();
		add(behind);
		
		var color = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFCAFF4D);
		color.screenCenter();
		add(color);
		
		// loading image
		bg = new FlxSprite().loadGraphic(Paths.image('funkay'));
		bg.scale.set(0.8,0.8);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
		loadBar = new FlxSprite().makeGraphic(FlxG.width - 16, 20 - 8, 0xFFFF16D2);
		loadBar.y = FlxG.height - loadBar.height - 8;
		changeBarSize(0);
		add(loadBar);
		
		var oldAnti:Bool = FlxSprite.defaultAntialiasing;
		FlxSprite.defaultAntialiasing = false;
		
		PlayState.resetStatics();
		var assetModifier = PlayState.assetModifier;
		var SONG = PlayState.SONG;
		
		var preloadThread = Thread.create(function()
		{
			mutex.acquire();
			Paths.preloadPlayStuff();
			Rating.preload(assetModifier);
			Paths.preloadGraphic('hud/base/healthBar');
			var stageBuild = new Stage();
			addBehind(stageBuild);
			stageBuild.reloadStageFromSong(SONG.song);
			
			trace('preloaded stage and hud');
			loadPercent = 0.2;
			
			var charList:Array<String> = [SONG.player1, SONG.player2, stageBuild.gfVersion];
			for(i in charList)
			{
				var char = new Character();
				char.isPlayer = (i == SONG.player1);
				char.reloadChar(i);
				addBehind(char);
				
				//trace('preloaded $i');
				
				if(i != stageBuild.gfVersion)
				{
					var icon = new HealthIcon();
					icon.setIcon(i, false);
					addBehind(icon);
				}
				loadPercent += (0.6 - 0.2) / charList.length;
			}
			
			trace('preloaded characters');
			loadPercent = 0.6;
			
			Paths.preloadSound('songs/${SONG.song}/Inst');
			if(SONG.needsVoices)
				Paths.preloadSound('songs/${SONG.song}/Voices');
			
			trace('preloaded music');
			loadPercent = 0.75;
			
			var thisStrumline = new Strumline(0, null, false, false, true, assetModifier);
			thisStrumline.ID = 0;
			addBehind(thisStrumline);
			
			var noteList:Array<Note> = ChartLoader.getChart(SONG);
			for(note in noteList)
			{
				note.reloadNote(note.songTime, note.noteData, note.noteType, assetModifier);
				addBehind(note);
				
				thisStrumline.addSplash(note);
				
				loadPercent += (0.9 - 0.75) / noteList.length;
			}
			
			trace('preloaded notes');
			loadPercent = 0.9;
			
			// add custom preloads here!!
			switch(SONG.song)
			{
				default:
					//trace('loaded lol');
			}
			
			loadPercent = 1.0;
			trace('finished loading');
			threadActive = false;
			FlxSprite.defaultAntialiasing = oldAnti;
			mutex.release();
		});
	}
	
	var byeLol:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(!threadActive && !byeLol && loadBar.scale.x >= 0.98)
		{
			byeLol = true;
			changeBarSize(1);
			Main.skipClearMemory = true;
			Main.switchState(new PlayState());
		}
		
		if(Controls.justPressed("ACCEPT"))
		{
			bg.scale.x += 0.04;
			bg.scale.y += 0.04;
		}
		
		var bgCalc = FlxMath.lerp(bg.scale.x, 0.75, elapsed * 6);
		bg.scale.set(bgCalc, bgCalc);
		bg.updateHitbox();
		
		changeBarSize(FlxMath.lerp(loadBar.scale.x, loadPercent, elapsed * 6));
	}
	
	function changeBarSize(newSize:Float)
	{
		loadBar.scale.x = newSize;
		loadBar.updateHitbox();
		loadBar.screenCenter(X);
	}
}