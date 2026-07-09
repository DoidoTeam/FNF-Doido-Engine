package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import doido.song.SongHandler.NoteData;
import objects.ui.notes.Note;
import objects.ui.notes.StrumNote;
import objects.ui.notes.Splash.BaseSplash;
import objects.ui.notes.Splash;
import doido.Cache;
import doido.objects.Alphabet;
import doido.objects.DoidoSprite;
import doido.song.AudioHandler;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.Character;
import objects.Stage;
import objects.ui.HealthIcon;
import objects.ui.HealthIcon.IconData;
import flixel.math.FlxMath;
import doido.song.SongHandler;
#if THREAD_LOADING
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class LoadingState extends MusicBeatState
{
	var threadActive:Bool = true;

	var bgFile:String = "";
	var bg:FlxSprite;
	var loadingTxt:Alphabet;
	var loadingTxtColor:String = "";

	var loadingPercent:Float = 0.0;
	var doingWhat:String = "";
	var loadingBar:FlxSprite;

	override function create()
	{
		super.create();
		persistentUpdate = true;
		hotReload = false;

		loadingTxtColor = (Save.data.darkMode ? "FFFFFF" : "000000");

		bgFile = '${Save.data.darkMode ? "menuInvert" : "menuDesat"}';
		bg = new FlxSprite().loadImage(bgFile);
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), 0.7, 1);
		bg.screenCenter();
		add(bg);

		var splashTxt = new Alphabet(40, 0, '<wave intensity=5 speed=5>LOADING...</wave>', true, LEFT);
		splashTxt.y = FlxG.height - splashTxt.height - 70;
		add(splashTxt);

		loadingTxt = new Alphabet(40, splashTxt.y + splashTxt.height, "", false, LEFT);
		loadingTxt.scale.set(0.5, 0.5);
		add(loadingTxt);

		loadingPercent = 0.0;

		loadingBar = new FlxSprite(-2, FlxG.height - 12).makeColor(0, 16, 0xFFFFFFFF);
		loadingBar.updateHitbox();
		add(loadingBar);

		#if !THREAD_LOADING
		var overlay = new FlxSprite().makeColor(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		overlay.screenCenter();
		add(overlay);
		#end

		doingWhat = "Starting...";

		#if THREAD_LOADING
		var mutex = new Mutex();
		Thread.create(function()
		{
			mutex.acquire();
		#end
			Logs.print("Loading Started!");
			Cache.loading = true;
			NoteUtil.setUpDirections(4);

			doingWhat = "Loading Sounds";
			loadSounds();
			loadingPercent = 0.25;

			doingWhat = "Loading Backgrounds'n'Characters";
			loadGame();
			loadingPercent = 0.75;

			doingWhat = "Loading HUD";
			loadHud();
			loadNotes();
			loadingPercent = 0.9;

			doingWhat = "Finishing...";
			// Add other assets here, if you need
			switch (CHART.song)
			{
				default:
					//
			}
			loadingPercent = 1.0;

			doingWhat = "Done!";
			Logs.print("Loading Ended!");
			Cache.loading = false;
			threadActive = false;
		#if THREAD_LOADING
		mutex.release();
		});
		#end
	}

	function loadGame()
	{
		var dadList:Array<String> = [META.player2];
		var bfList:Array<String> = [META.player1];
		var gfList:Array<String> = [META.gf];

		var stageBuild = new Stage(null);
		stageBuild.reloadStage(META.stage);

		if (!gfList.contains(stageBuild.gfVersion) || stageBuild.gfVersion != "")
			gfList.push(stageBuild.gfVersion);

		for (event in EVENTS.events)
		{
			switch (event.name)
			{
				/*case 'Change Character':
						charList.push(daEvent.value2);
						switch (daEvent.value1)
						{
							case 'bf' | 'boyfriend': playerChars.push(daEvent.value2);
						}
					 */
				case 'Change Stage':
					stageBuild.reloadStage(event.data[0]);

					if (!gfList.contains(stageBuild.gfVersion) || stageBuild.gfVersion != "")
						gfList.push(stageBuild.gfVersion);
			}
		}

		var charList = dadList.concat(bfList).concat(gfList);
		for (char in charList)
		{
			if (gfList.contains(char))
				loadChar(char, "gf");
			else if (bfList.contains(char))
				loadChar(char, "player");
			else
				loadChar(char);
		}
	}

	var loadedChars:Array<String> = [];

	function loadChar(char:String, type:String = "")
	{
		if (loadedChars.contains(char))
			return;
		else
			loadedChars.push(char);

		var data:DoidoCharacter;
		try
		{
			data = cast(Assets.json('data/characters/$char'));
		}
		catch (e)
		{
			Logs.print('CHAR $char LOAD ERROR: $e', ERROR);
			data = Character.defaultCharacter();
		}

		if (type == "player")
		{
			// trace("PRELOADING DEATH CHAR");
			loadChar(data.deathChar ?? "bf-dead");
		}

		var extrasheets:Array<String> = [];
		if ((data.extrasheets ?? []).length > 0)
		{
			for (sheet in (data.extrasheets ?? []))
				extrasheets.push('images/characters/$sheet');
		}

		Assets.framesCollection('characters/${data.spritesheet}', extrasheets, DoidoSprite.stringToSpriteType(data.spriteType));

		if (type != "gf")
		{
			var icon:IconData;
			try
			{
				icon = cast(Assets.json('data/icons/$char'));
			}
			catch (e)
			{
				Logs.print('ICON $char LOAD ERROR: $e', ERROR);
				icon = HealthIcon.defaultIcon();
			}

			Assets.image('icons/${icon.image ?? char}');
		}
	}

	function loadSounds()
	{
		var audio = new AudioHandler(CHART.song, CHART.postfix);
		NoteUtil.loadMissSounds();
		NoteUtil.playHitsound(0.0);

		Assets.music('gameover/${META.assets.gameOverPath}/deathSfx');
		// temporary caching
		for (i in 0...4)
		{
			Assets.sound("countdown/base/intro" + ["3", "2", "1", "Go"][i]);
		}
	}

	function loadHud()
	{
		for (image in Assets.list('images/ui/hud/${META.assets.hudType}/', false, IMAGE))
			Assets.image(formatImage(image));

		for (image in Assets.list('images/ui/ratings/${META.assets.ratings}/', false, IMAGE))
			Assets.image(formatImage(image));

		for (image in Assets.list('images/ui/countdown/${META.assets.countdown}/', false, IMAGE))
			Assets.image(formatImage(image));
	}

	function loadNotes()
	{
		var skins:Array<String> = [META.assets.opponentNotes];
		var types:Array<String> = [];
		if (!skins.contains(META.assets.playerNotes))
			skins.push(META.assets.playerNotes);

		for (note in CHART.notes)
			if (!types.contains(note.type))
				types.push(note.type);

		var notes:FlxTypedGroup<Note>;
		notes = new FlxTypedGroup<Note>();

		var strums:FlxTypedGroup<StrumNote>;
		strums = new FlxTypedGroup<StrumNote>();

		var splashes:FlxTypedGroup<BaseSplash>;
		splashes = new FlxTypedGroup<BaseSplash>();

		for (skin in skins)
		{
			if (Save.data.quantNotes)
				skin += '-quant';

			var strum = cast strums.recycle(StrumNote);
			strum.reloadStrum(0, skin);
			if (!strums.members.contains(strum))
				strums.add(strum);

			for (type in types)
			{
				var noteData:NoteData = {
					stepTime: 0,
					lane: 0,
					strumline: 0,
					type: type,
					length: 4
				};

				var note:Note = cast notes.recycle(Note);
				note.loadData(noteData, skin);
				note.reloadSprite();
				if (!notes.members.contains(note))
					notes.add(note);

				var holdLength:Int = Math.ceil(noteData.length + 1);
				for (i in 0...holdLength)
				{
					var hold:Note = cast notes.recycle(Note);
					hold.loadData(noteData, skin);

					hold.isHold = true;
					hold.isHoldEnd = (i == holdLength - 1);
					note.children.push(hold);

					hold.reloadSprite();
					hold.holdParent = note;
					if (!notes.members.contains(hold))
						notes.add(hold);
				}

				var splash:Splash = cast splashes.recycle(Splash);
				splash.loadData(note, skin);
				splash.reloadSplash();
				if (!splashes.members.contains(splash))
					splashes.add(splash);

				var cover:Cover = cast splashes.recycle(Cover);
				cover.loadData(note, skin);
				cover.reloadSplash();
				if (!splashes.members.contains(cover))
					splashes.add(cover);
			}
		}
	}

	override function destroy()
	{
		Assets.clearImage(bgFile);
		super.destroy();
	}

	function formatImage(image:String)
		return image.replace("assets/images/", "").replace(".png", "");

	var byeLol:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		loadingBar.scale.x = FlxMath.lerp(loadingBar.scale.x, loadingPercent * (FlxG.width + 4), elapsed * 6);
		loadingBar.updateHitbox();

		if (loadingTxt.text != doingWhat)
			loadingTxt.text = '<color value=#${loadingTxtColor}><wave intensity=2 speed=5>${doingWhat}</wave></color>';

		if (!threadActive && !byeLol)
		{
			byeLol = true;
			MusicBeat.skipClearCache = true;
			MusicBeat.switchState(new states.PlayState());
		}
	}

	public static var CHART(get, never):DoidoChart;

	public static function get_CHART():DoidoChart
		return PlayState.SONG.CHART;

	public static var EVENTS(get, never):DoidoEvents;

	public static function get_EVENTS():DoidoEvents
		return PlayState.SONG.EVENTS;

	public static var META(get, never):DoidoMeta;

	public static function get_META():DoidoMeta
		return PlayState.SONG.META;
}
