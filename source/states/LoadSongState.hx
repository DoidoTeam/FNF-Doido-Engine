package states;

import flixel.FlxG;
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
	
	//var behind:FlxGroup;
	var bg:FlxSprite;
	
	override function create()
	{
		super.create();
		mutex = new Mutex();
		
		//behind = new FlxGroup();
		//add(behind);
		
		var color = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFCAFF4D);
		color.screenCenter();
		add(color);
		
		// loading image
		bg = new FlxSprite().loadGraphic(Paths.image('funkay'));
		bg.scale.set(0.8,0.8);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		
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
			var stageBuild = new Stage();
			//behind.add(stageBuild);
			stageBuild.reloadStageFromSong(SONG.song);
			
			trace('preloaded stage and hud');
			
			for(i in [SONG.player1, SONG.player2, stageBuild.gfVersion])
			{
				var char = new Character();
				char.isPlayer == (i == SONG.player1);
				char.reloadChar(i);
				//behind.add(char);
				
				//trace('preloaded $i');
				
				if(i != stageBuild.gfVersion)
				{
					var icon = new HealthIcon();
					icon.setIcon(i, false);
				}
			}
			
			trace('preloaded characters');
			
			Paths.preloadSound('songs/${SONG.song}/Inst');
			if(SONG.needsVoices)
				Paths.preloadSound('songs/${SONG.song}/Voices');
			
			trace('preloaded music');
			
			var thisStrumline = new Strumline(0, null, false, false, true, assetModifier);
			thisStrumline.ID = 0;
			//behind.add(thisStrumline);
			
			var unsNoteAll:Array<Note> = ChartLoader.getChart(SONG);
			for(note in unsNoteAll)
			{
				note.reloadNote(note.songTime, note.noteData, note.noteType, assetModifier);
				//behind.add(note);
				
				thisStrumline.addSplash(note);
			}
			
			trace('preloaded notes');
			
			// add custom preloads here!!
			switch(SONG.song)
			{
				default:
					//trace('loaded lol');
			}
			
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
		if(!threadActive && !byeLol)
		{
			byeLol = true;
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
	}
}