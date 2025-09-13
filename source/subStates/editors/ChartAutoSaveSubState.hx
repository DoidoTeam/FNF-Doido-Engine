package subStates.editors;

import backend.game.GameData.MusicBeatSubState;
import backend.song.SongData;
import backend.song.SongData.EventSong;
import backend.song.SongData.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSave;
import objects.hud.HealthIcon;
import states.editors.ChartingState;

typedef AutoSaveData = {
	var SONG:SwagSong;
	var ?EVENTS:EventSong;
	var diff:String;
	var date:String;
}
class ChartAutoSaveSubState extends MusicBeatSubState
{
	public static var saveFile:FlxSave;
	public static var autoSaveArray:Array<AutoSaveData> = [];
	
	public static function load()
	{
		saveFile = new FlxSave();
		saveFile.bind("autosave");
		
		if (saveFile.data.autoSaveArray == null)
			saveFile.data.autoSaveArray = autoSaveArray;
		
		autoSaveArray = saveFile.data.autoSaveArray;
		save();
	}
	public static function save()
	{
		saveFile.data.autoSaveArray = autoSaveArray;
		saveFile.flush();
	}
	
	public function new()
	{
		super();
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.screenCenter();
		add(bg);
		
		var mainTxt = new FlxText(0,8,0,"AutoSaved Charts Station",36);
		mainTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, CENTER);
		mainTxt.screenCenter(X);
		add(mainTxt);
		
		var guideTxt = new FlxText(0,0,FlxG.width,"Here you can load your autosaves,\nyou can only have 5 slots, so dont count on it that much\n(press the icon on the left to load the autosave)",24);
		guideTxt.setFormat(Main.gFont, 26, 0xFFFFFFFF, CENTER);
		guideTxt.screenCenter(X);
		guideTxt.y = FlxG.height - guideTxt.height - 8;
		add(guideTxt);
		
		var count:Int = autoSaveArray.length - 1;
		for(autosave in autoSaveArray)
		{
			var dumbass = new AutoSaveWindow(autosave, count);
			add(dumbass);
			
			count--;
		}
		
		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.7}, 0.4, {ease: FlxEase.cubeOut});
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		for(item in members)
			if(Std.isOfType(item, FlxSprite))
				cast(item,FlxSprite).scrollFactor.set();
		
		if(FlxG.keys.justPressed.ESCAPE)
			close();
	}
	
	public static function addSave(SONG:SwagSong, EVENTS:EventSong, diff:String)
	{
		// not sure why, but autosave acts weird if i dont do this
		var songClone = {
			song: SONG.song,
			notes: [],
			bpm: SONG.bpm,
			needsVoices: SONG.needsVoices,
			speed: SONG.speed,
			player1: SONG.player1,
			player2: SONG.player2,
		};
		for(section in SONG.notes)
		{
			var sectionClone = {
				sectionNotes: [],
				lengthInSteps: section.lengthInSteps,
				mustHitSection: section.mustHitSection,
				bpm: section.bpm,
				changeBPM: section.changeBPM,
				// null stuff
				sectionBeats: section.sectionBeats,
			};
			for(note in section.sectionNotes)
			{
				var cloneNote = [];
				for(i in 0...note.length)
					cloneNote.push(note[i]);
				sectionClone.sectionNotes.push(cloneNote);
			}
			songClone.notes.push(sectionClone);
		}
		var eventsClone = SongData.defaultSongEvents();
		for(note in EVENTS.songEvents)
		{
			var cloneNote = [note[0], note[1], []];
			for(i in 0...note[2].length)
			{
				var cloneEvent = [];
				for(j in 0...note[2][i].length)
					cloneEvent.push(note[2][i][j]);
				cloneNote[2].push(cloneEvent);
			}
			eventsClone.songEvents.push(cloneNote);
		}
		
		// adding it (max is 5 so watch out!!)
		autoSaveArray.push({
			SONG: songClone,
			EVENTS: eventsClone,
			diff: diff,
			date: Date.now().toString(),
		});
		if (autoSaveArray.length > 5)
			autoSaveArray.remove(autoSaveArray[0]);
		save();
	}
}
class AutoSaveWindow extends FlxGroup
{
	public var bg:FlxSprite;
	var icon:HealthIcon;
	var nameTxt:FlxText;
	var dateTxt:FlxText;
	
	var data:AutoSaveData;
	
	public function new(data:AutoSaveData, daID:Int = 0)
	{
		super();
		ID = daID;
		this.data = data;
		bg = new FlxSprite().makeGraphic(FlxG.width - 400, Math.floor(FlxG.height / 7), 0xFFFFFFFF);
		add(bg);
		
		bg.color = HealthIcon.getColor(data.SONG.player2);
		
		icon = new HealthIcon();
		icon.setIcon(data.SONG.player2, false);
		icon.scale.set(0.7,0.7);
		icon.updateHitbox();
		add(icon);
		
		nameTxt = new FlxText(0,8,0, data.SONG.song.toUpperCase() + ' - ' + data.diff, 36);
		nameTxt.setFormat(Main.gFont, 36, 0xFF000000, LEFT);
		add(nameTxt);
		
		dateTxt = new FlxText(0,8,0, data.date, 24);
		dateTxt.setFormat(Main.gFont, 24, 0xFF000000, LEFT);
		add(dateTxt);
		
		for(item in members)
			if(Std.isOfType(item, FlxSprite))
				cast(item,FlxSprite).scrollFactor.set();
		
		updateHitbox();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		var iconSize:Float = 0.7;
		if(FlxG.mouse.overlaps(icon))
		{
			iconSize = 1.0;
			if(FlxG.mouse.justPressed)
			{
				if(ChartingState.SONG.song != data.SONG.song)
					ChartingState.curSection = 0;
				
				ChartingState.songDiff = data.diff;

				ChartingState.SONG = data.SONG;
				if(data.EVENTS != null)
					ChartingState.EVENTS = data.EVENTS;
				else
					ChartingState.EVENTS = SongData.defaultSongEvents();
				Main.switchState(new ChartingState());
			}
		}
		
		icon.scale.set(
			FlxMath.lerp(icon.scale.x, iconSize, elapsed * 8),
			FlxMath.lerp(icon.scale.y, iconSize, elapsed * 4)
		);
	}
	
	public function updateHitbox()
	{
		bg.x = FlxG.width / 2 - bg.width / 2;
		bg.y = 50 + (bg.height + 15) * ID;
		
		icon.x = bg.x + 20;
		icon.y = bg.y + bg.height / 2 - icon.height / 2;
		
		nameTxt.y = bg.y + 10;
		nameTxt.x = bg.x + 130;
		
		// adjusting the size
		while(nameTxt.x + nameTxt.width >= bg.x + bg.width - 20)
		{
			nameTxt.scale.x -= 0.02;
			nameTxt.updateHitbox();
		}
		
		dateTxt.x = nameTxt.x;
		dateTxt.y = nameTxt.y + nameTxt.height + 10;
	}
}