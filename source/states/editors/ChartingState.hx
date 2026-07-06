package states.editors;

import openfl.events.RenderEvent;
import substates.editors.ChartTestSubState;
import substates.editors.PopupSubState;
import doido.Cache;
import flixel.graphics.frames.FlxFramesCollection;
import openfl.geom.Rectangle;
import flixel.graphics.FlxGraphic;
import objects.ui.HealthIcon;
import doido.objects.ui.window.DoidoChooser;
import doido.objects.ui.DoidoCheckmark;
import doido.objects.ui.PsychUINumericStepper;
import doido.objects.ui.window.DoidoWindow;
import doido.objects.ui.window.DoidoMenu;
import doido.objects.ui.window.DoidoBox;
import doido.objects.ui.buttons.DoidoButton;
import doido.objects.ui.*;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import doido.utils.EditorUtil;
import doido.song.SongHandler.NoteData;
import doido.song.AudioHandler;
import doido.song.Conductor;
import doido.song.SongHandler.DoidoSong;
import doido.song.SongHandler.DoidoChart;
import doido.song.SongHandler.DoidoEvents;
import doido.song.SongHandler.DoidoMeta;
import doido.utils.NoteUtil;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxTween;
import objects.ui.DebugInfo;
import objects.ui.notes.Note;
import shaders.MultiplyShader;
import haxe.Json;
import flixel.util.FlxColor;
import doido.objects.ui.buttons.DoidoTextButton;
import flixel.graphics.frames.FlxFrame;
import doido.song.SongHandler;
import doido.utils.EventUtil;

class ChartingNote extends Note
{
	public var selected:Bool = false;

	public var typeTxt:FlxBitmapText;
	public var typeIndex:Int = 0;

	public function new()
	{
		super();

		typeTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		typeTxt.setOutline(0xFF000000, 2);
		typeTxt.alignment = LEFT;
		typeTxt.scale.set(0.7, 0.7);
		typeTxt.updateHitbox();
	}

	override function draw()
	{
		super.draw();

		if (typeIndex != 0 && !isHold)
		{
			typeTxt.x = x;
			typeTxt.y = y;
			typeTxt.draw();
		}
	}

	public override function loadData(data:NoteData, skin:String)
	{
		super.loadData(data, skin);
		typeIndex = NoteUtil.noteTypes.indexOf(data.type);
		typeTxt.text = typeIndex == -1 ? '?' : Std.string(typeIndex);
	}
}

class ChartingEvent extends FlxSprite
{
	public var selected:Bool = false;
	public var event:EventData;
	public var isHold:Bool = false;

	public function new()
	{
		super();
	}

	public function resetEvent()
	{
		scale.set(1, 1);
		antialiasing = true;
		updateHitbox();
	}

	public function reloadEvent(event:EventData)
	{
		resetEvent();
		isHold = false;
		this.event = event;
		this.loadImage(EventUtil.getEventSprite(event.name));
		this.setHitbox(ChartingState.EVENT_SIZE, ChartingState.EVENT_SIZE);
	}

	public function reloadHold(length:Float)
	{
		resetEvent();
		isHold = true;
		this.makeColor(ChartingState.GRID_SIZE * 0.25, ChartingState.GRID_SIZE * ChartingState.GRID_ZOOM * length);
	}
}

class ChartingState extends MusicBeatState
{
	public static var GRID_SIZE:Int = 40;
	public static var GRID_LANES:Int = 8;

	public static var GRID_SNAP:Int = 16;
	public static var GRID_ZOOM:Float = 1.0;

	public static var EVENT_SIZE:Float = 40;
	public static var EVENT_PADDING:Int = 10;

	// settings
	public static var centerEvents:Bool = true;
	public static var noFunAllowed:Bool = false; // reduced animations
	public static var quantNotes:Bool = Save.data.quantNotes;

	public var audio:AudioHandler;
	public var playingSong:Bool = false;

	public var SONG:DoidoSong;

	public var cursorTxt:FlxBitmapText;
	public var scrollBall:FlxSprite;

	public var grid:ChartingGrid;
	public var timeBar:FlxSprite;
	public var renderNotes:FlxTypedGroup<ChartingNote>;
	public var renderEvents:FlxTypedGroup<ChartingEvent>;
	public var selectedColor:FlxColor = FlxColor.BLACK;

	// editor stuff
	public var selectedNotes:Array<NoteData> = [];
	public var selectedEvents:Array<EventData> = [];
	public var noteClipboard:Array<NoteData> = [];
	public var draggingSelectedNotes:Bool = false;
	public var hoverSquare:FlxSprite;
	public var selectSquare:FlxSprite;
	public var addEvent:ChartingEvent;

	public var curNoteType:String = "none";
	public var lastEdited:EventData;
	public var eventAmounts:Map<String, Int> = []; // how many events are in each step

	public var lastClicked:DoidoPoint = {x: 0, y: 0};
	public var lastClickedOffset:Float = 0.0;
	public var lastMouseStep:Null<Float>;
	public var lastMouseLane:Null<Int>;
	public var heldOnNote:Bool = false;
	public var heldOnNoteHold:Bool = false;

	// windows!!
	public var timeWindow:TimeWindow;
	public var gridWindow:GridWindow;
	public var menuBox:DoidoBox;
	public var menuMain:DoidoBox;

	// border
	public var borderLeft:FlxSprite;
	public var borderRight:FlxSprite;
	public var cameraIcon:FlxSprite;
	public var iconBf:HealthIcon;
	public var iconDad:HealthIcon;

	var characters:Array<String> = [];

	public function new(SONG:DoidoSong)
	{
		super();
		this.SONG = SONG;
	}

	override function create()
	{
		super.create();
		hotReload = false;
		setFpsPos(18, FlxG.height - 125 - Main.fpsHeight);
		FlxG.mouse.visible = true;
		Conductor.initialBPM = CHART.bpm;
		Conductor.mapBPMChanges(EVENTS.events);
		Conductor.songPos = 0;
		persistentDraw = true;
		persistentUpdate = false;
		MusicBeat.stopMusic();

		characters = Assets.list("data/characters/", true, JSON).concat(["face"]);

		audio = new AudioHandler(CHART.song, PlayState.songDiff);

		if (NoteUtil.directions.length == 0)
			NoteUtil.setUpDirections(4);

		var bg = new FlxSprite().loadGraphic(Assets.image('editors/charting/bg/light'));
		bg.screenCenter();
		add(bg);

		hoverSquare = new FlxSprite().makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
		hoverSquare.visible = false;
		hoverSquare.alpha = 0.7;
		// add(hoverSquare);

		grid = new ChartingGrid(358, audio.length, hoverSquare);
		add(grid);

		renderNotes = new FlxTypedGroup<ChartingNote>();
		add(renderNotes);

		renderEvents = new FlxTypedGroup<ChartingEvent>();
		add(renderEvents);

		addEvent = new ChartingEvent();
		addEvent.reloadEvent({name: "add", stepTime: 0, data: []});
		addEvent.visible = false;
		add(addEvent);

		timeBar = new FlxSprite(grid.gridX).makeColor(GRID_SIZE * GRID_LANES, 4, 0xFFFF0000);
		timeBar.screenCenter(Y);
		add(timeBar);

		selectSquare = new FlxSprite().makeColor(1, 1, 0xFF0078D4);
		selectSquare.visible = false;
		selectSquare.alpha = 0.5;
		add(selectSquare);

		addMenu();
		addMain();

		timeWindow = new TimeWindow(this);
		add(timeWindow);

		gridWindow = new GridWindow(this);
		add(gridWindow);

		var debugInfo = new DebugInfo(this);
		// debugInfo.visible = true;
		add(debugInfo);

		cursorTxt = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		cursorTxt.setOutline(0xFF000000, 2);
		cursorTxt.alignment = LEFT;
		cursorTxt.scale.set(0.7, 0.7);
		cursorTxt.updateHitbox();

		scrollBall = new FlxSprite(0, 0).loadImage("editors/charting/scrollBall");

		// preload icons
		for (char in characters)
		{
			var icon:HealthIcon = new HealthIcon();
			icon.setIcon(char, false);
			icon.destroy();
		}

		borderLeft = new FlxSprite().loadGraphic(Assets.image('editors/charting/border_left'));
		borderLeft.x -= 2;
		add(borderLeft);

		borderRight = new FlxSprite().loadGraphic(Assets.image('editors/charting/border_right'));
		borderRight.x = FlxG.width - borderRight.width + 2;
		add(borderRight);

		cameraIcon = new FlxSprite().loadGraphic(Assets.image('editors/charting/camera'));
		cameraIcon.scale.set(0.38, 0.38);
		cameraIcon.updateHitbox();
		cameraIcon.x = 518 - (cameraIcon.width / 2);
		cameraIcon.y = 1;
		add(cameraIcon);

		iconBf = new HealthIcon();
		iconDad = new HealthIcon();
		add(iconBf);
		add(iconDad);
		reloadIcons();
	}

	function reloadIcons()
	{
		iconBf.setIcon(META.player1, true);
		iconDad.setIcon(META.player2, false);

		borderLeft.color = iconDad.barColor;
		borderRight.color = iconBf.barColor;

		for (icon in [iconBf, iconDad])
		{
			icon.setGraphicSize(82, 82);
			icon.updateHitbox();
			icon.scrollFactor.set();
			icon.y = 35 - (icon.height / 2);
		}

		iconDad.x = 518 - iconDad.width - 15;
		iconBf.x = 518 + 15;
	}

	function addMenu()
	{
		var x = 20;
		var y = 20;
		var width = 318;
		var height = 22;

		var fileWindow = new MenuWindow(x, y + 30, width, this);
		fileWindow.title = "File";
		fileWindow.addButton("New", "Ctrl + N", () ->
		{
			var newSong:String = CHART.song;
			var newDiff:String = PlayState.songDiff;

			var openStuff:Array<FlxSprite> = [];
			openStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22, "Song:", 0xFFD8DAF6));
			openStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22, "Diff:", 0xFFD8DAF6));

			var songField:PsychUIInputText;
			songField = new PsychUIInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2), 145, newSong, 14);
			songField.onChange.add((old, cur, input) -> newSong = cur);
			openStuff.push(songField);

			var diffField:PsychUIInputText;
			diffField = new PsychUIInputText((FlxG.width / 2) + 5, (FlxG.height / 2), 145, newDiff, 14);
			diffField.onChange.add((old, cur, input) -> newDiff = cur);
			openStuff.push(diffField);

			var ok = new DoidoTextButton("Ok", "small");
			ok.screenCenter();
			ok.y += 50;
			openStuff.push(ok);

			var popup = new PopupSubState("New Song:", 320, 150, openStuff);
			openSubState(popup);

			ok.button.onUp.add(() ->
			{
				PlayState.SONG = {
					CHART: {
						song: newSong,
						notes: [],
						bpm: 100,
						speed: 2
					},
					EVENTS: {events: []},
					META: {
						player1: "bf",
						player2: "face",
						gf: "gf",
						stage: "stage",
						composer: "Unknown",
						charter: "Unknown",
						assets: {
							playerNotes: "base",
							opponentNotes: "base",
							hudType: "base",
							ratings: "base",
							countdown: "base",
							gameOverPath: "base",
						}
					}
				};
				PlayState.songDiff = newDiff;
				PlayState.isStoryMode = false;
				MusicBeat.switchState(new ChartingState(PlayState.SONG));
			});
		});
		fileWindow.addSeparator();

		// fileWindow.addButton("Open Events", "Ctrl + Alt + O");
		// fileWindow.addSeparator();
		fileWindow.addButton("Open Song", () ->
		{
			var newSong:String = CHART.song;
			var newDiff:String = PlayState.songDiff;

			var openStuff:Array<FlxSprite> = [];
			openStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22, "Song:", 0xFFD8DAF6));
			openStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22, "Diff:", 0xFFD8DAF6));

			var songField:PsychUIInputText;
			songField = new PsychUIInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2), 145, newSong, 14);
			songField.onChange.add((old, cur, input) -> newSong = cur);
			openStuff.push(songField);

			var diffField:PsychUIInputText;
			diffField = new PsychUIInputText((FlxG.width / 2) + 5, (FlxG.height / 2), 145, newDiff, 14);
			diffField.onChange.add((old, cur, input) -> newDiff = cur);
			openStuff.push(diffField);

			var ok = new DoidoTextButton("Ok", "small");
			ok.screenCenter();
			ok.y += 50;
			openStuff.push(ok);

			var popup = new PopupSubState("Open Song:", 320, 150, openStuff);
			openSubState(popup);

			ok.button.onUp.add(() ->
			{
				try
				{
					PlayState.loadSong(newSong, newDiff);
					MusicBeat.switchState(new ChartingState(PlayState.SONG));
				}
				catch (e)
				{
					FlxG.sound.play(Assets.sound('beep'));
					Logs.print(e);
				}

				// popup.close();
			});
		});
		fileWindow.addButton("Save Song", "Ctrl + S", () ->
		{
			save(CHART, PlayState.songDiff);
			save(EVENTS, "events");
			save(META, "meta");
		});
		fileWindow.addSeparator();
		fileWindow.addButton("Save Chart", "Ctrl + Shift + S", () -> save(CHART, PlayState.songDiff));
		fileWindow.addButton("Save Events", "Ctrl + Alt + S", () -> save(EVENTS, "events"));
		fileWindow.addButton("Save Meta", "Ctrl + Tab + S", () -> save(META, "meta"));
		fileWindow.addSeparator();
		// fileWindow.addButton("Reload Chart", "Ctrl + Shift + Alt + R");
		// fileWindow.addSeparator();
		// fileWindow.addButton("Preview", "ESC");
		fileWindow.addButton("Play Song", "Enter", () -> play());
		fileWindow.addButton("Play from Here", "Shift + Enter", () -> play(true));
		fileWindow.addButton("Test Song", "ESC", () -> openTester());
		fileWindow.updateBg();

		var editWindow = new MenuWindow(x, y + 30, width, this);
		editWindow.title = "Edit";
		// editWindow.addButton("Undo", "Ctrl + Z");
		// editWindow.addButton("Redo", "Ctrl + Y");
		// editWindow.addSeparator();
		editWindow.addButton("Copy", "Ctrl + C", () -> copy(false));
		editWindow.addButton("Paste", "Ctrl + V", () -> paste());
		editWindow.addSeparator();
		editWindow.addButton("Cut", "Ctrl + X", () -> copy(true));
		editWindow.addButton("Delete", "Delete", () -> delete());
		editWindow.addSeparator();
		editWindow.addButton("Select Section", "Ctrl + A", () -> selectSection());
		editWindow.addButton("Select All", "Ctrl + Shift + A", () -> selectAll());
		editWindow.addButton("Deselect", "Ctrl + D", () -> deselect());
		editWindow.addSeparator();
		editWindow.addButton("Chart Converter", () ->
		{
			var newSong:String = CHART.song;
			var newDiff:String = PlayState.songDiff;

			var openStuff:Array<FlxSprite> = [];
			openStuff.push(createText((FlxG.width / 2) - (245) - 5, (FlxG.height / 2) - 22, "Songs:", 0xFFD8DAF6));
			openStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22, "Diffs:", 0xFFD8DAF6));

			var songField:PsychUIInputText;
			songField = new PsychUIInputText((FlxG.width / 2) - (245) - 5, (FlxG.height / 2), 245, newSong, 14);
			songField.onChange.add((old, cur, input) -> newSong = cur);
			openStuff.push(songField);

			var diffField:PsychUIInputText;
			diffField = new PsychUIInputText((FlxG.width / 2) + 5, (FlxG.height / 2), 245, newDiff, 14);
			diffField.onChange.add((old, cur, input) -> newDiff = cur);
			openStuff.push(diffField);

			var ok = new DoidoTextButton("Convert", "small");
			ok.screenCenter();
			ok.y += 50;
			openStuff.push(ok);

			var popup = new PopupSubState("Chart Converter", 520, 150, openStuff);
			openSubState(popup);

			ok.button.onUp.add(() ->
			{
				var songs:Array<String> = newSong.split(",").map(s -> s.trim());
				var diffs:Array<String> = newDiff.split(",").map(s -> s.trim());

				for (input in songs)
				{
					for (diff in diffs)
					{
						trace(diff);
						var song = SongHandler.loadSong(input, diff);
						var export:Array<Dynamic> = [song.CHART, song.EVENTS, song.META];
						var names = ["", "events-", "meta-"];
						for (i in 0...export.length)
						{
							var data:String = Json.stringify(export[i], "\t");
							if (data != null && data.length > 0)
							{
								Assets.fileSave(data.trim(), '$input-${names[i]}$diff.json');
							}
						}
					}
				}
			});
		});
		editWindow.updateBg();

		var viewWindow = new MenuWindow(x, y + 30, width, this);
		viewWindow.title = "View";
		// viewWindow.addButton("Go to Section...");
		// viewWindow.addSeparator();
		viewWindow.addButton("Go to Song Start", "Ctrl + R", () -> goToSong(0));
		viewWindow.addButton("Go to Song End", "Ctrl + Shift + R", () -> goToSong(audio.length - 1));
		viewWindow.addSeparator();
		viewWindow.addCheck("Reduced Animations", noFunAllowed, (b) -> noFunAllowed = b);
		viewWindow.addCheck("Center Events", centerEvents, (b) -> centerEvents = b);
		viewWindow.addCheck("Old Timer", TimeWindow.oldTimer, (b) -> TimeWindow.oldTimer = b);
		viewWindow.addCheck("Quant Notes", quantNotes, (b) -> quantNotes = b);
		// viewWindow.addButton("Go to...");
		viewWindow.updateBg();

		menuBox = new DoidoBox(x, y, width, height, 0, false, [fileWindow, editWindow, viewWindow], this);
		add(menuBox);
	}

	function createBasic(title:String = "test"):DoidoWindow
	{
		var newWindow:DoidoWindow = new DoidoWindow(this);
		newWindow.title = title;
		newWindow.bg.scale.set(458, 501);
		newWindow.bg.updateHitbox();
		newWindow.bg.setPosition(FlxG.width - newWindow.bg.width - 18, 57);
		return newWindow;
	}

	function createText(x:Float = 0, y:Float = 0, text:String = "", color:FlxColor = 0xFFFFFFFF):FlxBitmapText
	{
		var newText = new FlxBitmapText(x, y, Assets.bitmapFont("phantommuff"));
		newText.alignment = LEFT;
		newText.text = text;
		newText.color = color;
		newText.scale.set(0.625, 0.625);
		newText.updateHitbox();
		return newText;
	}

	var spacingH:Float = 30;

	function createChartingTab():DoidoWindow
	{
		var tab = createBasic("Charting");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 138;
				case "margin_first_small": tab.bg.x + 76;
				case "margin_second": tab.bg.x + 178;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		tab.add(createText(getX(), getY(0) + 3, "Volume:"));
		tab.add(createText(getX(), getY(1) + 3, "Player:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(2) + 3, "Opponent:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(3) + 3, "Instrumental:", 0xFFD8DAF6));

		var playerVol:DoidoCheckmark = new DoidoCheckmark(true);
		playerVol.onUp.add(() ->
		{
			audio.muteVoices = !playerVol.value;
		});
		playerVol.x = getX("margin_first");
		playerVol.y = getY(1) - 1;
		tab.add(playerVol);

		var playerStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(1), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(playerStepper);

		var oppVol:DoidoCheckmark = new DoidoCheckmark(true);
		oppVol.onUp.add(() ->
		{
			audio.muteOpponent = !oppVol.value;
		});
		oppVol.x = getX("margin_first");
		oppVol.y = getY(2) - 1;
		tab.add(oppVol);

		var oppStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(2), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(oppStepper);

		var instVol:DoidoCheckmark = new DoidoCheckmark(true);
		instVol.onUp.add(() ->
		{
			audio.muteInst = !instVol.value;
		});
		instVol.x = getX("margin_first");
		instVol.y = getY(3) - 1;
		tab.add(instVol);

		var instStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(3), 0.01, 1, 0, 1.0, 2, 100, true);
		tab.add(instStepper);

		var playerSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(1) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		playerSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			playerVol.value = true;
			playerStepper.value = playerSlider.value;
			if (audio.voicesGlobal != null)
				audio.voicesGlobal.volume = playerSlider.value;
		});
		tab.add(playerSlider);

		var oppSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(2) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		oppSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			oppVol.value = true;
			oppStepper.value = oppSlider.value;
			if (audio.voicesOpp != null)
				audio.voicesOpp.volume = oppSlider.value;
		});
		tab.add(oppSlider);

		var instSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(3) + 9, 160, 6, 1, 0, 1, 3, 0.02);
		instSlider.onScrub.add((sld) ->
		{
			@:bypassAccessor audio.muteVoices = false;
			instVol.value = true;
			instStepper.value = instSlider.value;
			audio.inst.volume = instSlider.value;
		});
		tab.add(instSlider);

		playerStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteVoices = false;
			playerVol.value = true;
			playerSlider.value = playerStepper.value;
			if (audio.voicesGlobal != null)
				audio.voicesGlobal.volume = playerStepper.value;
		});

		oppStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteOpponent = false;
			oppVol.value = true;
			oppSlider.value = oppStepper.value;
			if (audio.voicesOpp != null)
				audio.voicesOpp.volume = oppStepper.value;
		});

		instStepper.onValueChange = (() ->
		{
			@:bypassAccessor audio.muteInst = false;
			instVol.value = true;
			instSlider.value = instStepper.value;
			audio.inst.volume = instStepper.value;
		});

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(4) + 5);
		tab.add(balls);

		tab.add(createText(getX(), getY(5) + 3, "Hitsounds:"));
		tab.add(createText(getX(), getY(6) + 3, "Player:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(7) + 3, "Opponent:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(8) + 3, "Metronome:", 0xFFD8DAF6));

		var playerHitVol:DoidoCheckmark = new DoidoCheckmark(playerHitSounds);
		playerHitVol.onUp.add(() ->
		{
			playerHitSounds = playerHitVol.value;
		});
		playerHitVol.x = getX("margin_first");
		playerHitVol.y = getY(6) - 1;
		tab.add(playerHitVol);

		var playerHitStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(6), 0.01, playerHitVolume, 0, 1.0, 2, 100, true);
		tab.add(playerHitStepper);

		var oppHitVol:DoidoCheckmark = new DoidoCheckmark(oppHitSounds);
		oppHitVol.onUp.add(() ->
		{
			oppHitSounds = oppHitVol.value;
		});
		oppHitVol.x = getX("margin_first");
		oppHitVol.y = getY(7) - 1;
		tab.add(oppHitVol);

		var oppHitStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(7), 0.01, oppHitVolume, 0, 1.0, 2, 100, true);
		tab.add(oppHitStepper);

		var metVol:DoidoCheckmark = new DoidoCheckmark(metronome);
		metVol.onUp.add(() ->
		{
			metronome = metVol.value;
		});
		metVol.x = getX("margin_first");
		metVol.y = getY(8) - 1;
		tab.add(metVol);

		var metStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(8), 0.01, metronomeVolume, 0, 1.0, 2, 100, true);
		tab.add(metStepper);

		var playerHitSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(6) + 9, 160, 6, playerHitVolume, 0, 1, 3, 0.02);
		playerHitSlider.onScrub.add((sld) ->
		{
			playerHitSounds = true;
			playerHitVol.value = true;
			playerHitStepper.value = playerHitSlider.value;
			playerHitVolume = playerHitSlider.value;
		});
		tab.add(playerHitSlider);

		var oppHitSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(7) + 9, 160, 6, oppHitVolume, 0, 1, 3, 0.02);
		oppHitSlider.onScrub.add((sld) ->
		{
			oppHitSounds = true;
			oppHitVol.value = true;
			oppHitStepper.value = oppHitSlider.value;
			oppHitVolume = oppHitSlider.value;
		});
		tab.add(oppHitSlider);

		var metSlider:DoidoSlider = new DoidoSlider(getX("margin_second"), getY(8) + 9, 160, 6, metronomeVolume, 0, 1, 3, 0.02);
		metSlider.onScrub.add((sld) ->
		{
			metronome = true;
			metVol.value = true;
			metStepper.value = metSlider.value;
			metronomeVolume = metSlider.value;
		});
		tab.add(metSlider);

		playerHitStepper.onValueChange = (() ->
		{
			playerHitSounds = true;
			playerHitVol.value = true;
			playerHitSlider.value = playerHitStepper.value;
			playerHitVolume = playerHitStepper.value;
		});

		oppHitStepper.onValueChange = (() ->
		{
			oppHitSounds = true;
			oppHitVol.value = true;
			oppHitSlider.value = oppHitStepper.value;
			oppHitVolume = oppHitStepper.value;
		});

		metStepper.onValueChange = (() ->
		{
			metronome = true;
			metVol.value = true;
			metSlider.value = metStepper.value;
			metronomeVolume = metStepper.value;
		});

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(9) + 5);
		tab.add(balls);

		// playback
		tab.add(createText(getX(), getY(10) + 3, "Playback:"));

		tab.add(createText(getX(), getY(11) + 3, "Speed:", 0xFFD8DAF6));

		var playbackStepper = new PsychUINumericStepper(getX("margin_right", 152), getY(11), 0.1, 1, 0, 2.0, 2, 100, false, true);
		tab.add(playbackStepper);

		var playbackSlider:DoidoSlider = new DoidoSlider(getX("margin_first_small"), getY(11) + 9, 210, 6, 1, 0, 2, 5, 0.03);
		playbackSlider.onScrub.add((sld) ->
		{
			if (playbackSlider.value <= 0)
			{
				playingSong = false;
				audio.pause();
			}
			playbackStepper.value = playbackSlider.value;
			audio.speed = playbackSlider.value;
		});
		tab.add(playbackSlider);

		playbackStepper.onValueChange = (() ->
		{
			if (playbackStepper.value <= 0)
			{
				playingSong = false;
				audio.pause();
			}
			playbackSlider.value = playbackStepper.value;
			audio.speed = playbackStepper.value;
		});

		/*
			var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
			balls.setPosition(getX("center", balls.width), getY(12) + 5);
			tab.add(balls);

			// playback
			tab.add(createText(getX(), getY(13) + 3, "Functions:"));
		 */

		return tab;
	}

	function createSongTab():DoidoWindow
	{
		var tab = createBasic("Song");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 110;
				case "margin_first_search": tab.bg.x + 80;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		// chart options
		tab.add(createText(getX(), getY(0) + 3, "Song:"));
		tab.add(createText(getX(), getY(1) + 3, "Name:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(2) + 3, "BPM:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(3) + 3, "Note Speed:", 0xFFD8DAF6));

		var songName:PsychUIInputText;
		songName = new PsychUIInputText(getX("margin_first"), getY(1), 342, CHART.song, 14);
		songName.onChange.add((old, cur, input) -> CHART.song = cur);
		tab.add(songName);

		var bpmStepper = new PsychUINumericStepper(getX("margin_first"), getY(2), 1, CHART.bpm, 1, 339, 0);
		bpmStepper.onValueChange = (() ->
		{
			Conductor.initialBPM = bpmStepper.value;
			CHART.bpm = Conductor.bpm;
			Conductor.mapBPMChanges(EVENTS.events);
		});
		tab.add(bpmStepper);

		var speedStepper = new PsychUINumericStepper(getX("margin_first"), getY(3), 0.1, CHART.speed, 0.1, 10, 1);
		speedStepper.onValueChange = (() ->
		{
			CHART.speed = speedStepper.value;
		});
		tab.add(speedStepper);

		var reloadButton = new DoidoTextButton("Reload Audio", () ->
		{
			playingSong = false;
			audio.pause();
			audio.reload(CHART.song, PlayState.songDiff);
			grid.length = audio.length;
		});
		reloadButton.x = getX("margin_right", reloadButton.width);
		reloadButton.y = getY(3) - 9;
		reloadButton.button.setColorTransform(0.59, 0.78, 1);
		reloadButton.label.color = 0xFFFFFFFF;
		tab.add(reloadButton);

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(4) + 5);
		tab.add(balls);

		// meta options
		// tab.add(createText(getX(), getY(5), "Meta:"));

		tab.add(createText(getX(), getY(5) + 3, "Search:", 0xFFD8DAF6));

		var test:ChooserWindow = new ChooserWindow(getX("center", 440), getY(6) + 5, 440, 170, [], this);
		tab.add(test);

		var filter:PsychUIInputText;
		filter = new PsychUIInputText(getX("margin_first_search"), getY(5), 372, "", 14);
		filter.onChange.add((old, cur, input) -> test.filter = cur);
		filter.behindText.color = 0xFFD8DAF6;
		tab.add(filter);

		var glass:FlxSprite = new FlxSprite().loadImage("editors/charting/glass");
		glass.setGraphicSize(filter.behindText.height - 2, filter.behindText.height - 2);
		glass.x = filter.behindText.x + 1;
		glass.y = filter.behindText.y + 1;
		tab.add(glass);

		filter.textObj.x += glass.width + 2;
		filter.fieldWidth -= Std.int(glass.width + 2);

		tab.add(createText(getX(), getY(12) + 10, "Opponent:", 0xFFD8DAF6));
		tab.add(createText(getX("center", 145), getY(12) + 10, "Girlfriend:", 0xFFD8DAF6));
		tab.add(createText(getX("margin_right", 145), getY(12) + 10, "Player:", 0xFFD8DAF6));

		var bfIcon = new HealthIcon();
		bfIcon.setIcon(META.player1, false);
		bfIcon.globalScale = 0.33;
		bfIcon.setPosition(getX("margin_right", 145) + 145 - bfIcon.width, getY(12) - 10);
		tab.add(bfIcon);

		var bfButton = new DoidoTextButton("");
		bfButton.button.onUp.add(() ->
		{
			if (test.buttonId == "bf")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "bf";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					bfButton.text = name;
					bfIcon.setIcon(name, false);
					bfButton.button.setColorTransform(bfIcon.barColor.redFloat, bfIcon.barColor.greenFloat, bfIcon.barColor.blueFloat);
					META.player1 = name;
					reloadIcons();
					test.buttonId = "";
				};
			}
		});
		bfButton.x = getX("margin_right", bfButton.width); // bfButton.width
		bfButton.y = getY(12) + 32;
		bfButton.button.setColorTransform(bfIcon.barColor.redFloat, bfIcon.barColor.greenFloat, bfIcon.barColor.blueFloat);
		bfButton.text = META.player1;
		bfButton.label.color = 0xFFFFFFFF;
		tab.add(bfButton);

		var oppIcon = new HealthIcon();
		oppIcon.setIcon(META.player2, false);
		oppIcon.globalScale = 0.33;
		oppIcon.setPosition(getX() + 145 - oppIcon.width, getY(12) - 10);
		tab.add(oppIcon);

		var oppButton = new DoidoTextButton("",);
		oppButton.button.onUp.add(() ->
		{
			if (test.buttonId == "opp")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "opp";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					oppButton.text = name;
					oppIcon.setIcon(name, false);
					oppButton.button.setColorTransform(oppIcon.barColor.redFloat, oppIcon.barColor.greenFloat, oppIcon.barColor.blueFloat);
					META.player2 = name;
					reloadIcons();
					test.buttonId = "";
				};
			}
		});
		oppButton.x = getX(); // bfButton.width
		oppButton.y = getY(12) + 32;
		oppButton.button.setColorTransform(oppIcon.barColor.redFloat, oppIcon.barColor.greenFloat, oppIcon.barColor.blueFloat);
		oppButton.text = META.player2;
		oppButton.label.color = 0xFFFFFFFF;
		tab.add(oppButton);

		var gfIcon = new HealthIcon();
		gfIcon.setIcon(META.gf, false);
		gfIcon.globalScale = 0.33;
		gfIcon.setPosition(getX("center", 145) + 145 - gfIcon.width, getY(12) - 10);
		tab.add(gfIcon);

		var gfButton = new DoidoTextButton("");
		gfButton.button.onUp.add(() ->
		{
			if (test.buttonId == "gf")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "gf";
				test.view = GRID;
				test.type = CHARACTER;
				test.options = characters;
				test.onClick = (name) ->
				{
					test.options = [];
					gfButton.text = name;
					gfIcon.setIcon(name, false);
					gfButton.button.setColorTransform(gfIcon.barColor.redFloat, gfIcon.barColor.greenFloat, gfIcon.barColor.blueFloat);
					META.gf = name;
					test.buttonId = "";
				};
			}
		});

		gfButton.x = getX("center", gfButton.width); // bfButton.width
		gfButton.y = getY(12) + 32;
		gfButton.button.setColorTransform(gfIcon.barColor.redFloat, gfIcon.barColor.greenFloat, gfIcon.barColor.blueFloat);
		gfButton.text = META.gf;
		gfButton.label.color = 0xFFFFFFFF;
		tab.add(gfButton);

		tab.add(createText(getX(), getY(14) + 10, "Stage:", 0xFFD8DAF6));

		var stages:Array<String> = Assets.list("data/scripts/stages/", true, SCRIPT);
		// stages = stages.concat(stages);
		var stageButton = new DoidoTextButton("");
		stageButton.button.onUp.add(() ->
		{
			if (test.buttonId == "stages")
			{
				test.options = [];
				test.onClick = null;
				test.buttonId = "";
			}
			else
			{
				test.buttonId = "stages";
				test.view = LIST;
				test.type = NONE;
				test.options = stages;
				test.onClick = (name) ->
				{
					test.options = [];
					stageButton.text = name;
					META.stage = name;
					test.buttonId = "";
				};
			}
		});
		stageButton.x = getX(); // bfButton.width
		stageButton.y = getY(14) + 32;
		stageButton.text = META.stage;
		// stageButton.text.color = 0xFFFFFFFF;
		tab.add(stageButton);

		tab.add(createText(getX("center", 145), getY(14) + 10, "Meta:", 0xFFD8DAF6));
		tab.add(createText(getX("margin_right", 145), getY(14) + 10, "Assets:", 0xFFD8DAF6));

		var metaButton = new DoidoTextButton("Edit");
		metaButton.button.onUp.add(() ->
		{
			var metaComposer:String = META.composer;
			var metaCharter:String = META.charter;

			var metaStuff:Array<FlxSprite> = [];
			metaStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22, "Composer:", 0xFFD8DAF6));
			metaStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22, "Charter:", 0xFFD8DAF6));

			var composer:PsychUIInputText;
			composer = new PsychUIInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2), 145, metaComposer, 14);
			composer.onChange.add((old, cur, input) -> metaComposer = cur);
			metaStuff.push(composer);

			var charter:PsychUIInputText;
			charter = new PsychUIInputText((FlxG.width / 2) + 5, (FlxG.height / 2), 145, metaCharter, 14);
			charter.onChange.add((old, cur, input) -> metaCharter = cur);
			metaStuff.push(charter);

			var ok = new DoidoTextButton("Ok", "small");
			ok.screenCenter();
			ok.y += 50;
			metaStuff.push(ok);

			var popup = new PopupSubState("Editing Meta:", 320, 150, metaStuff);
			openSubState(popup);

			ok.button.onUp.add(() ->
			{
				META.composer = metaComposer;
				META.charter = metaCharter;
				popup.close();
			});
		});
		metaButton.x = getX("center", metaButton.width);
		metaButton.y = getY(14) + 32;
		tab.add(metaButton);

		var skinsButton = new DoidoTextButton("Edit");
		skinsButton.button.onUp.add(() ->
		{
			var dadSkin:String = META.assets.opponentNotes;
			var bfSkin:String = META.assets.playerNotes;

			var metaStuff:Array<FlxSprite> = [];
			metaStuff.push(createText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2) - 22, "Opp Notes:", 0xFFD8DAF6));
			metaStuff.push(createText((FlxG.width / 2) + 5, (FlxG.height / 2) - 22, "Player Notes:", 0xFFD8DAF6));

			var dadnotes:PsychUIInputText;
			dadnotes = new PsychUIInputText((FlxG.width / 2) - (145) - 5, (FlxG.height / 2), 145, dadSkin, 14);
			dadnotes.onChange.add((old, cur, input) -> dadSkin = cur);
			metaStuff.push(dadnotes);

			var bfnotes:PsychUIInputText;
			bfnotes = new PsychUIInputText((FlxG.width / 2) + 5, (FlxG.height / 2), 145, bfSkin, 14);
			bfnotes.onChange.add((old, cur, input) -> bfSkin = cur);
			metaStuff.push(bfnotes);

			var ok = new DoidoTextButton("Ok", "small");
			ok.screenCenter();
			ok.y += 50;
			metaStuff.push(ok);

			var popup = new PopupSubState("Editing Assets:", 320, 150, metaStuff);
			openSubState(popup);

			ok.button.onUp.add(() ->
			{
				META.assets.opponentNotes = dadSkin;
				META.assets.playerNotes = bfSkin;
				popup.close();
			});
		});
		skinsButton.x = getX("margin_right", skinsButton.width);
		skinsButton.y = getY(14) + 32;
		tab.add(skinsButton);

		return tab;
	}

	function createNotesTab()
	{
		var tab = createBasic("Notes");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 120;
				case "margin_first_search": tab.bg.x + 80;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		tab.add(createText(getX(), getY(0), "Timings:"));
		tab.add(createText(getX(), getY(1) + 3, "Note Step:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(2) + 3, "Note Length:", 0xFFD8DAF6));

		var noteSteps = new PsychUINumericStepper(getX("margin_first"), getY(1), 1, 0, 0, 999999, 2);
		noteSteps.onValueChange = (() ->
		{
			if (selectedNotes.length == 1)
				selectedNotes[0].stepTime = noteSteps.value;
		});
		noteSteps.onValueStep = ((step) ->
		{
			if (selectedNotes.length > 1)
				for (note in selectedNotes)
					note.stepTime += step;
		});
		tab.add(noteSteps);

		var noteLength = new PsychUINumericStepper(getX("margin_first"), getY(2), 1, 0, 0, 999999, 1);
		noteLength.onValueChange = (() ->
		{
			if (selectedNotes.length == 1)
				selectedNotes[0].length = noteLength.value;
			else if (selectedNotes.length > 1) {}
		});
		noteLength.onValueStep = ((step) ->
		{
			if (selectedNotes.length > 1)
				for (note in selectedNotes)
					note.length += step;
		});
		tab.add(noteLength);

		var curTypeTxt:FlxBitmapText;
		tab.add(curTypeTxt = createText(0, 0, 'Current Type: $curNoteType'));
		curTypeTxt.x = getX();
		curTypeTxt.y = tab.bg.y + tab.bg.height - curTypeTxt.height - 8;

		tab.updateCallback.add(() ->
		{
			curTypeTxt.text = 'Current Type: ${TextUtil.titleCase(curNoteType)}';

			if (selectedNotes.length == 0)
			{
				for (stepper in [noteSteps, noteLength])
				{
					stepper.disableInput = true;
					stepper.disableSteppers = true;
					stepper.value = 0;
				}
			}
			else if (selectedNotes.length == 1)
			{
				for (stepper in [noteSteps, noteLength])
				{
					stepper.disableInput = false;
					stepper.disableSteppers = false;
				}

				noteSteps.value = selectedNotes[0].stepTime;
				noteLength.value = selectedNotes[0].length;
			}
			else
			{
				for (stepper in [noteSteps, noteLength])
				{
					stepper.disableInput = true;
					stepper.disableSteppers = false;
					stepper.value = 0;
				}
			}
		});
		tab.updateCallback.dispatch();

		var bottomY = 4;

		var notes = new ChooserWindow(getX("center", 440), getY(bottomY + 1) + 5, 440, 300, [], null);
		notes.view = LIST;
		notes.type = NOTETYPE;
		notes.descOnly = true;
		notes.align = LEFT;
		notes.options = NoteUtil.noteTypes;
		notes.descs = [
			for (i in 0...NoteUtil.noteTypes.length)
				'$i. ${TextUtil.titleCase(NoteUtil.noteTypes[i])}'
		];
		notes.onClick = (str) ->
		{
			curNoteType = str;
			for (note in selectedNotes)
				note.type = str;
			tab.updateCallback.dispatch();
		};
		tab.add(notes);

		var search = tab.add(createText(getX(), getY(bottomY) + 3, "Search:", 0xFFD8DAF6));

		var filter:PsychUIInputText;
		filter = new PsychUIInputText(getX("margin_first_search"), getY(bottomY), 372, "", 14);
		filter.onChange.add((old, cur, input) -> notes.filter = cur);
		filter.behindText.color = 0xFFD8DAF6;
		tab.add(filter);

		var glass:FlxSprite = new FlxSprite().loadImage("editors/charting/glass");
		glass.setGraphicSize(filter.behindText.height - 2, filter.behindText.height - 2);
		glass.x = filter.behindText.x + 1;
		glass.y = filter.behindText.y + 1;
		tab.add(glass);

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(bottomY - 1) + 3);
		tab.add(balls);

		return tab;
	}

	function createEventsTab()
	{
		var tab = createBasic("Events");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first_search": tab.bg.x + 80;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				case "margin_first": tab.bg.x + 110;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				default: tab.bg.x + 8;
			}
		}

		var spacingE = spacingH - 3;
		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingE * i);

		var valueTabs:FlxGroup = new FlxGroup();
		tab.add(valueTabs);

		var bottomY = 12;

		var warnSpr = new FlxSprite();
		warnSpr.loadImage("editors/charting/events/warning");
		warnSpr.x = getX("center", warnSpr.width);
		warnSpr.y = getY(6);
		tab.add(warnSpr);

		var warnTxt = createText(0, 0, "Select an event to edit.", 0xFFD8DAF6);
		warnTxt.x = getX("center", warnTxt.width);
		warnTxt.y = warnSpr.y + warnSpr.height + 10;
		warnTxt.scale.set(0.8, 0.8);
		tab.add(warnTxt);

		var events = new ChooserWindow(getX("center", 440), getY(1) + 5, 440, 200, [], null);
		events.view = GRID;
		events.type = EVENT;
		events.options = EventUtil.eventLists.get("Main");
		var list:Bool = true;
		events.onClick = (str) ->
		{
			if (list)
			{
				events.view = LIST;
				events.options = ["Back"].concat(EventUtil.eventLists.get(str));
				list = false;
			}
			else
			{
				if (str == "Back")
				{
					events.view = GRID;
					events.options = EventUtil.eventLists.get("Main");
					list = true;
				}
				else
				{
					if (lastEdited != null)
					{
						lastEdited.name = str;
						lastEdited.data = [for (v in EventUtil.getEvent(str).values) v.defaultValue];
					}
					tab.updateCallback.dispatch();
				}
			}
		};
		events.active = false;
		tab.add(events);

		var search = tab.add(createText(getX(), getY(0) + 3, "Search:", 0xFFD8DAF6));

		var filter:PsychUIInputText;
		filter = new PsychUIInputText(getX("margin_first_search"), getY(0), 372, "", 14);
		filter.onChange.add((old, cur, input) -> events.filter = cur);
		filter.behindText.color = 0xFFD8DAF6;
		tab.add(filter);

		var glass:FlxSprite = new FlxSprite().loadImage("editors/charting/glass");
		glass.setGraphicSize(filter.behindText.height - 2, filter.behindText.height - 2);
		glass.x = filter.behindText.x + 1;
		glass.y = filter.behindText.y + 1;
		tab.add(glass);

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(bottomY - 3) + 3);
		tab.add(balls);

		function toggleStuff(b:Bool)
		{
			for (obj in [events, filter, glass, balls, search])
			{
				obj.active = b;
				obj.visible = b;
			}
			for (obj in [warnSpr, warnTxt])
			{
				obj.active = !b;
				obj.visible = !b;
			}
		}
		toggleStuff(false);

		tab.updateCallback.add(() ->
		{
			valueTabs.clear();

			if (lastEdited == null)
			{
				toggleStuff(false);
				return;
			}

			toggleStuff(true);

			var event = EventUtil.getEvent(lastEdited.name);
			if (event == null)
				return;

			valueTabs.add(createText(getX(), getY(bottomY - 2), "Editing: " + event.name, 0xFFFFFFFF));
			for (i in 0...event.values.length)
			{
				var value = event.values[i];
				var index = event.values.length - i;

				var x = getX((i % 2 == 0) ? "" : "center");
				var y = getY((bottomY) + (Math.floor(i / 2) * 2));

				var current:Dynamic = (lastEdited.data != null && lastEdited.data[i] != null) ? lastEdited.data[i] : value.defaultValue;

				valueTabs.add(createText(x, y - spacingE + 3, value.name + ":", 0xFFD8DAF6));
				if (Std.isOfType(value.defaultValue, String))
				{
					if (value.options != null)
					{
						// drop down
						var dropdown = new PsychUIDropDownMenu(x, y, cast value.options, (i2, s) ->
						{
							lastEdited.data[i] = s;
						}, 100, false);
						dropdown.selectedLabel = current;
						dropdown.zIndex = index;
						valueTabs.add(dropdown);
					}
					else
					{
						var textfield = new PsychUIInputText(x, y, 145, current, 14);
						textfield.onChange.add((old, cur, input) -> lastEdited.data[i] = cur);
						textfield.zIndex = index;
						valueTabs.add(textfield);
					}
				}
				else if (Std.isOfType(value.defaultValue, Float) || Std.isOfType(value.defaultValue, Int))
				{
					var stepper = new PsychUINumericStepper(x, y, value.step ?? 0.25, current, value.min ?? 0, value.max ?? 4, value.decimals ?? 2, 100, false);
					stepper.onValueChange = () -> lastEdited.data[i] = stepper.value;
					stepper.zIndex = index;
					valueTabs.add(stepper);
				}
				else if (Std.isOfType(value.defaultValue, Bool))
				{
					var checkmark = new DoidoCheckmark(current);
					checkmark.onUp.add(() -> lastEdited.data[i] = checkmark.value);
					checkmark.x = x;
					checkmark.y = y;
					checkmark.zIndex = index;
					valueTabs.add(checkmark);
				}
			}

			valueTabs.sort(ZIndex.sort);
		});

		return tab;
	}

	var eventsTab:DoidoWindow;
	var notesTab:DoidoWindow;

	function addMain()
	{
		menuMain = new DoidoBox(803, 19, 458, 32, 3, [
			createChartingTab(),
			eventsTab = createEventsTab(),
			notesTab = createNotesTab(),
			// createBasic("Functions"),
			createSongTab()
		], this);
		add(menuMain);
	}

	public var playerHitSounds:Bool = true;
	public var oppHitSounds:Bool = true;
	public var metronome:Bool = false;

	public var playerHitVolume:Float = 1;
	public var oppHitVolume:Float = 1;
	public var metronomeVolume:Float = 1;

	public function onNoteHit(note:NoteData)
	{
		if (note.strumline == 0 && oppHitSounds || note.strumline == 1 && playerHitSounds)
		{
			var key = Save.data.hitsound;
			if (key == "OFF")
				key = "OSU";
			NoteUtil.playHitsound(key, note.strumline == 0 ? oppHitVolume : playerHitVolume);
		}
	}

	public var tweeningSongPos:Bool = false;
	public var curCursor:lime.ui.MouseCursor = DEFAULT;

	var autoScrolling:Bool = false;
	var scrollAutoY:Float = 0;

	var typing(get, never):Bool;

	function get_typing():Bool
		return PsychUIInputText.focusOn != null;

	override function update(elapsed:Float)
	{
		// debug camera lol
		if (FlxG.keys.justPressed.NINE || FlxG.keys.justPressed.NUMPADNINE)
			FlxG.camera.zoom = (FlxG.camera.zoom == 1.0 ? 0.8 : 1.0);

		curCursor = DEFAULT;
		if (tweeningSongPos)
			playingSong = false;
		else
		{
			if (FlxG.keys.justPressed.SPACE && !typing && audio.speed > 0)
				playingSong = !playingSong;
		}

		for (event in EVENTS.events)
		{
			if (event.name == "BPM Change" || event.name == "Linear BPM Change")
			{
				Conductor.mapBPMChanges(EVENTS.events);
				break;
			}
		}

		var overlapsWindow:Bool = false;

		for (basic in members)
		{
			if (Std.isOfType(basic, IWindow))
			{
				if (cast(basic, IWindow).overlapping)
				{
					overlapsWindow = true;
				}
			}
		}

		if (selectedNotes.length > 0 || selectedEvents.length > 0)
		{
			var selColor:Float = 0.8 + Math.sin(FlxG.game.ticks / 100) * 2;
			selectedColor.redFloat = selColor;
			selectedColor.greenFloat = selColor;
			selectedColor.blueFloat = selColor;

			renderNotes.forEachAlive((note) ->
			{
				if (note.selected)
					note.color = selectedColor;
			});

			renderEvents.forEachAlive((event) ->
			{
				if (event.selected)
					event.color = selectedColor;
			});
		}

		var cursorText:String = "";

		if (!overlapsWindow && !typing)
		{
			if (FlxG.keys.pressed.SHIFT)
				cursorText = "4x";

			if (FlxG.mouse.pressedRight)
				cursorText = "X";

			if (FlxG.mouse.justPressed)
			{
				lastClicked = {x: FlxG.mouse.x, y: FlxG.mouse.y};
				lastClickedOffset = grid.gridY;
			}

			if (FlxG.mouse.justReleased)
			{
				heldOnNote = false;
				// heldOnNoteHold = false;
			}

			if (lastClickedOffset != grid.gridY)
			{
				lastClicked.y -= (lastClickedOffset - grid.gridY);
				lastClickedOffset = grid.gridY;
			}

			if (FlxG.mouse.pressed)
			{
				// if you moved 10 pixels from it
				if (Math.abs(FlxG.mouse.x - lastClicked.x) >= 10 || Math.abs(FlxG.mouse.y - lastClicked.y) >= 10)
				{
					if (selectedNotes.length > 0)
					{
						if (heldOnNote)
							draggingSelectedNotes = true;
						else if (!heldOnNoteHold)
							selectSquare.visible = true;
					}
					else
						selectSquare.visible = true;
				}

				if (!playingSong)
				{
					var mouseMove:Int = 60;
					if (FlxG.mouse.y < mouseMove || FlxG.mouse.y > FlxG.height - mouseMove)
					{
						var dir:Int = (FlxG.mouse.y < mouseMove) ? -1 : 1;
						if (FlxG.mouse.y < mouseMove / 2 || FlxG.mouse.y > FlxG.height - mouseMove / 2)
							dir *= 4;

						Conductor.songPos += dir * 1000 * elapsed;
					}
				}
			}

			if (selectedEvents.length < 2 && selectedEvents[0] != lastEdited)
			{
				lastEdited = selectedEvents[0];
				eventsTab.updateCallback.dispatch();
				if (lastEdited != null)
					menuMain.setTab("Events");
			}

			if (selectedNotes.length > 0)
			{
				if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
				{
					playSfx("editors/click");
					var dir:Int = FlxG.keys.justPressed.Q ? -1 : 1;
					if (FlxG.keys.pressed.SHIFT)
						dir *= 4;
					for (note in selectedNotes)
					{
						note.length += dir;
						if (note.length < 0)
							note.length = 0;
					}
					notesTab.updateCallback.dispatch();
				}
			}

			if (selectedEvents.length > 0)
			{
				if (FlxG.keys.justPressed.DELETE)
				{
					for (event in selectedEvents)
					{
						playSfx("editors/pop", FlxG.random.float(0.0, 0.4));
						EVENTS.events.remove(event);
					}
					selectedEvents = [];
					sortEvents();
				}
			}

			if (FlxG.mouse.x < grid.gridX)
			{
				var zoomSnap:Float = (GRID_SNAP * GRID_ZOOM);
				var realSnap:Float = (zoomSnap / 16);
				var sizeTimed:Float = (GRID_SIZE / realSnap) * GRID_ZOOM;
				var mouseY:Float = Math.floor((FlxG.mouse.y + (centerEvents ? (EVENT_SIZE / 2) : 0) - grid.gridY) / sizeTimed) * sizeTimed;
				var curStep:Float = mouseY / GRID_SIZE / GRID_ZOOM;
				var eventOrder:Int = eventAmounts.get(Std.string(curStep)) ?? 1;

				addEvent.x = grid.gridX - ((EVENT_SIZE + EVENT_PADDING) * eventOrder) - (EVENT_PADDING / 2);
				addEvent.y = grid.gridY + mouseY;
				addEvent.visible = true;
				if (GRID_SNAP == 0)
					addEvent.y = FlxG.mouse.y;
				if (centerEvents)
					addEvent.y -= (EVENT_SIZE / 2);

				if (FlxG.mouse.overlaps(addEvent))
				{
					addEvent.alpha = 1;
					curCursor = POINTER;

					if (FlxG.mouse.justReleased)
					{
						if (!draggingSelectedNotes && !heldOnNoteHold)
						{
							var multiple:Bool = selectedEvents.length > 0;
							var eventList:Array<EventData> = [
								{
									stepTime: 0,
									name: "New Event",
									data: []
								}
							];
							if (multiple)
								eventList = selectedEvents;

							selectedEvents = [];
							for (event in eventList)
							{
								var newEvent:EventData = {
									stepTime: curStep,
									name: event.name,
									data: event.data.copy()
								};

								EVENTS.events.push(newEvent);
								selectedEvents.push(newEvent);
								playSfx("editors/click", multiple ? FlxG.random.float(0.0, 0.4) : 0);
							}

							sortEvents();
						}
					}
				}
				else
				{
					addEvent.alpha = 0.5;

					var removed:Bool = false;
					renderEvents.forEachAlive((event) ->
					{
						if (event.isHold)
							return;

						if (FlxG.mouse.overlaps(event))
						{
							curCursor = POINTER;
							if (FlxG.mouse.justPressed)
							{
								var exists = selectedEvents.contains(event.event);
								if (!FlxG.keys.pressed.CONTROL)
									selectedEvents = [];

								if (selectedEvents.contains(event.event))
									selectedEvents.remove(event.event);
								else if (!exists)
									selectedEvents.push(event.event);
							}
							else if (FlxG.mouse.justPressedRight)
							{
								removed = true;
								EVENTS.events.remove(event.event);
								if (selectedEvents.contains(event.event))
									selectedEvents.remove(event.event);
							}
						}
					});

					if (removed)
					{
						playSfx("editors/pop");
						sortEvents();
					}
				}
			}
			else
				addEvent.visible = false;

			if (selectSquare.visible)
			{
				hoverSquare.visible = false;

				selectSquare.scale.set(Math.abs(FlxG.mouse.x - lastClicked.x), Math.abs(FlxG.mouse.y - lastClicked.y));
				selectSquare.updateHitbox();

				if (FlxG.mouse.x < lastClicked.x)
					selectSquare.x = lastClicked.x - selectSquare.width;
				else
					selectSquare.x = lastClicked.x;

				if (FlxG.mouse.y < lastClicked.y)
					selectSquare.y = lastClicked.y - selectSquare.height;
				else
					selectSquare.y = lastClicked.y;

				if (FlxG.mouse.justReleased)
				{
					if (!FlxG.keys.pressed.CONTROL)
						selectedNotes = [];

					var zoomedGrid:Float = GRID_SIZE * GRID_ZOOM;
					var startY:Float = Math.floor((selectSquare.y - grid.gridY) / zoomedGrid);
					var endY:Float = startY + Math.floor(selectSquare.height / zoomedGrid);
					var startX:Float = Math.floor((selectSquare.x - grid.gridX) / GRID_SIZE);
					var endX:Float = startX + Math.floor(selectSquare.width / GRID_SIZE);

					for (note in CHART.notes)
					{
						var rawLane:Int = note.lane + (4 * note.strumline);

						if (note.stepTime > startY - 1 && note.stepTime < endY + 1 && rawLane > startX - 1 && rawLane < endX + 1)
						{
							if (!selectedNotes.contains(note))
							{
								selectedNotes.push(note);
								curNoteType = note.type;
							}
						}
					}

					selectSquare.visible = false;
					notesTab.updateCallback.dispatch();
				}
			}
			else
			{
				if (FlxG.mouse.x > grid.gridX
					&& FlxG.mouse.x < grid.gridX + GRID_SIZE * GRID_LANES
					&& FlxG.mouse.y > grid.gridY
					&& FlxG.mouse.y < grid.gridY + GRID_SIZE * grid.gridLength)
				{
					var mouseLane:Int = getMouseLane();
					var zoomSnap:Float = (GRID_SNAP * GRID_ZOOM);
					var realSnap:Float = (zoomSnap / 16);
					var sizeTimed:Float = (GRID_SIZE / realSnap) * GRID_ZOOM;

					hoverSquare.visible = true;
					hoverSquare.setPosition(grid.gridX + mouseLane * GRID_SIZE, grid.gridY + Math.floor((FlxG.mouse.y - grid.gridY) / sizeTimed) * sizeTimed);
					if (GRID_SNAP == 0)
						hoverSquare.y = FlxG.mouse.y;

					var mouseStep:Float = (hoverSquare.y - grid.gridY) / GRID_SIZE / GRID_ZOOM;

					if (FlxG.mouse.justPressedRight)
					{
						selectedNotes = [];
						notesTab.updateCallback.dispatch();
					}

					var overlapsNotes:Bool = false;
					renderNotes.forEachAlive((note) ->
					{
						if (overlapsNotes)
							return;

						if (FlxG.mouse.overlaps(note))
							overlapsNotes = true;
					});

					if (overlapsNotes)
					{
						var mightBeHold:Bool = false;
						var noteExists:Bool = false;

						curCursor = POINTER;

						renderNotes.forEachAlive((note) ->
						{
							if (FlxG.mouse.overlaps(note))
							{
								if (CHART.notes.contains(note.data))
									noteExists = true;
								else
									return;

								// hold hitbox
								if ((note.isHold && FlxG.mouse.y > note.y + GRID_SIZE / 2)
									|| (!note.isHold && FlxG.mouse.y > note.y + GRID_SIZE * 0.75))
								{
									curCursor = RESIZE_NS;
									mightBeHold = true;
								}
							}
						});

						if (FlxG.mouse.pressedRight)
						{
							var removed:Bool = false;
							renderNotes.forEachAlive((note) ->
							{
								if (FlxG.mouse.overlaps(note) && noteExists)
								{
									removed = true;
									if (note.isHold)
										CHART.notes[CHART.notes.indexOf(note.data)].length = 0;
									else
										CHART.notes.remove(note.data);
								}
							});
							if (removed)
							{
								playSfx("editors/pop");
								sortNotes();
							}
						}
						if (FlxG.mouse.justPressed)
						{
							if (mightBeHold)
								heldOnNoteHold = true;
							else
								heldOnNote = true;

							var clearNote:NoteData = null;
							renderNotes.forEachAlive((note) ->
							{
								if (FlxG.mouse.overlaps(note) && noteExists)
								{
									if (FlxG.keys.pressed.CONTROL)
									{
										if (!selectedNotes.contains(note.data))
											selectedNotes.push(note.data);
										else
											selectedNotes.remove(note.data);
									}
									else
									{
										if (!selectedNotes.contains(note.data))
											clearNote = note.data;
									}
								}
							});

							lastMouseStep = mouseStep;
							lastMouseLane = mouseLane;

							if (clearNote != null)
								selectedNotes = [clearNote];

							notesTab.updateCallback.dispatch();
							sortNotes();
						}
					}
					else
					{
						if (FlxG.mouse.justReleased)
						{
							if (!draggingSelectedNotes && !heldOnNoteHold)
							{
								playSfx("editors/click");
								var newNote:NoteData = {
									stepTime: mouseStep,
									lane: (mouseLane % 4),
									strumline: (mouseLane >= 4) ? 1 : 0,
									type: curNoteType,
									length: 0.0,
								};
								// trace('added lane ${newNote.lane} to strumline ${newNote.strumline}');
								CHART.notes.push(newNote);
								selectedNotes = [newNote];
								notesTab.updateCallback.dispatch();
								sortNotes();
							}
						}
					}

					if (heldOnNoteHold)
					{
						curCursor = RESIZE_NS;
						if (FlxG.mouse.justReleased)
						{
							playSfx("editors/click");
							heldOnNoteHold = false;
							for (note in selectedNotes)
							{
								note.length -= (lastMouseStep - mouseStep);
								if (note.length < 0)
									note.length = 0;
							}
							notesTab.updateCallback.dispatch();
						}
					}

					if (draggingSelectedNotes)
					{
						curCursor = MOVE;
						if (FlxG.mouse.justReleased)
						{
							playSfx("editors/click");
							draggingSelectedNotes = false;
							for (note in selectedNotes)
							{
								note.stepTime -= (lastMouseStep - mouseStep);
								if (note.stepTime < 0 || note.stepTime > grid.gridLength)
								{
									CHART.notes.remove(note); // BE CAREFUL!!
									continue;
								}

								note.lane -= (lastMouseLane - mouseLane);
								while (note.lane < 0)
								{
									note.lane += 4;
									note.strumline -= 1;
									if (note.strumline < 0)
										note.strumline = 1;
								}
								while (note.lane > 3)
								{
									note.lane %= 4;
									note.strumline += 1;
									if (note.strumline > 1)
										note.strumline = 0;
								}
							}
							notesTab.updateCallback.dispatch();
							sortNotes();
						}
					}
				}
				else
					hoverSquare.visible = false;
			}

			if (FlxG.mouse.wheel != 0)
			{
				playingSong = false;
				stopTweenSongPos();
				Conductor.songPos += -FlxG.mouse.wheel * 10000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1) / GRID_ZOOM;
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				playingSong = false;
				stopTweenSongPos();
				var dir:Int = (FlxG.keys.pressed.S ? 1 : 0) - (FlxG.keys.pressed.W ? 1 : 0);
				Conductor.songPos += dir * 1000 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1) / GRID_ZOOM;
			}

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
			{
				var wasA:Bool = FlxG.keys.justPressed.A;
				if (FlxG.keys.pressed.CONTROL)
				{
					if (wasA)
					{
						if (FlxG.keys.pressed.SHIFT)
							selectAll();
						else
							selectSection();
					}
					else
						deselect();
				}
				else
					changeSection(wasA ? -1 : 1);
			}

			if (FlxG.keys.pressed.CONTROL)
			{
				if ((FlxG.keys.justPressed.C || FlxG.keys.justPressed.X))
					copy(FlxG.keys.justPressed.X);
				if (FlxG.keys.justPressed.V)
					paste();
			}

			if (FlxG.keys.justPressed.DELETE)
				delete();

			if (FlxG.keys.justPressed.R)
				resetSection();

			if (FlxG.keys.justPressed.ENTER)
				play(FlxG.keys.pressed.SHIFT);

			if (FlxG.keys.justPressed.ESCAPE)
				openTester();

			if (FlxG.keys.justPressed.EIGHT || FlxG.keys.justPressed.NUMPADEIGHT)
				noFunAllowed = !noFunAllowed;

			if (FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
			{
				var pressedNone = !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && !FlxG.keys.pressed.TAB;

				if (FlxG.keys.pressed.SHIFT || pressedNone)
					save(CHART, PlayState.songDiff);
				if (FlxG.keys.pressed.ALT || pressedNone)
					save(EVENTS, "events");
				if (FlxG.keys.pressed.TAB || pressedNone)
					save(META, "meta");
			}
		}

		if (playingSong && audio.speed > 0)
		{
			if (!audio.playing && Conductor.songPos >= 0)
				audio.play(Conductor.songPos);

			var prevPos = Conductor.songPos;
			Conductor.songPos += elapsed * 1000 * audio.speed;

			for (note in CHART.notes)
			{
				var noteTime:Float = Conductor.getTimeAtStep(note.stepTime);
				if (noteTime < prevPos)
					continue;
				else if (noteTime > Conductor.songPos)
					break;
				else
					onNoteHit(note);
			}
		}
		else
		{
			if (audio.playing)
				audio.pause();
		}

		if (Conductor.songPos < 0)
			Conductor.songPos = 0;
		if (Conductor.songPos >= audio.length)
		{
			Conductor.songPos = audio.length;
			playingSong = false;
		}

		if (!playingSong)
		{
			if (FlxG.mouse.pressedMiddle && FlxG.keys.pressed.CONTROL)
				timeBar.y = (FlxG.keys.pressed.SHIFT ? (FlxG.height / 2) - (timeBar.height / 2) : FlxG.mouse.y);
			else if (FlxG.mouse.justPressedMiddle)
			{
				autoScrolling = !autoScrolling;

				if (autoScrolling)
				{
					scrollAutoY = FlxG.mouse.getWorldPosition().y;
					scrollBall.setPosition(FlxG.mouse.getWorldPosition()
						.x - (scrollBall.width / 2), FlxG.mouse.getWorldPosition().y - (scrollBall.height / 2));
				}
			}

			if (autoScrolling)
				Conductor.songPos += (FlxG.mouse.getWorldPosition().y - scrollAutoY) * 10 * elapsed * (FlxG.keys.pressed.SHIFT ? 4 : 1);
		}

		grid.gridY = timeBar.y + (timeBar.height / 2) - (curStepFloat * GRID_SIZE * GRID_ZOOM);

		super.update(elapsed);
		EditorUtil.setCursor(curCursor);
		if (cursorTxt.text != cursorText)
		{
			cursorTxt.text = cursorText;
			cursorTxt.color = (cursorText == "X" ? 0xFFFF0000 : 0xFFFFFFFF);
		}
	}

	public function save(_data:Dynamic, name:String)
	{
		var data:String = Json.stringify(_data, "\t");
		if (data != null && data.length > 0)
		{
			Assets.fileSave(data.trim(), '${name}.json');
		}
	}

	public function play(testHere:Bool = false)
	{
		if (testHere)
			PlayState.startPos = Conductor.songPos;

		PlayState.SONG = SONG;
		MusicBeat.switchState(new LoadingState());
		FlxG.mouse.visible = false;
	}

	public function openTester()
	{
		playingSong = false;
		if (audio.playing)
			audio.pause();

		persistentDraw = false;
		openSubState(new ChartTestSubState(SONG, Conductor.songPos));
	}

	public function selectAll()
	{
		selectedNotes = [];
		for (note in CHART.notes)
			selectedNotes.push(note);
		notesTab.updateCallback.dispatch();
	}

	public function selectSection()
	{
		selectedNotes = [];

		var startStep = Std.int(curBeat / 4) * 16;
		var endStep = startStep + 16;
		for (note in CHART.notes)
		{
			if (note.stepTime < startStep)
				continue;

			if (note.stepTime >= endStep)
				break;

			selectedNotes.push(note);
		}
		notesTab.updateCallback.dispatch();
	}

	public function deselect()
	{
		selectedNotes = [];
		notesTab.updateCallback.dispatch();
	}

	public function delete()
	{
		if (selectedNotes.length < 1)
			return;

		for (note in selectedNotes)
		{
			playSfx("editors/pop", FlxG.random.float(0.0, 0.4));
			CHART.notes.remove(note);
		}
		selectedNotes = [];
		notesTab.updateCallback.dispatch();
		sortNotes();
	}

	public function copy(cut:Bool)
	{
		if (selectedNotes.length < 1)
			return;

		noteClipboard = selectedNotes.copy();
		noteClipboard.sort(NoteUtil.sortNotes);

		if (cut)
			delete();
		else
			playSfx("editors/click");
	}

	public function paste()
	{
		if (noteClipboard.length < 1)
			return;

		playSfx("editors/pop");
		selectedNotes = [];
		var firstStep = noteClipboard[0].stepTime;
		for (note in noteClipboard)
		{
			var newNote = {
				stepTime: curStep + (note.stepTime - firstStep),
				lane: note.lane,
				strumline: note.strumline,
				type: note.type,
				length: note.length
			};
			CHART.notes.push(newNote);
			selectedNotes.push(newNote);
		}
		notesTab.updateCallback.dispatch();
		sortNotes();
	}

	public function getMouseLane():Int
	{
		return Math.floor((FlxG.mouse.x - grid.gridX) / GRID_SIZE);
	}

	public function getSectionStart(?step:Float):Float
	{
		if (step == null)
			step = curStepFloat;

		return Conductor.getTimeAtStep(Math.floor(step / 16) * 16);
	}

	public function stopTweenSongPos()
	{
		if (tweeningSongPos)
			tweenSongPos(getSectionStart());
	}

	public function changeSection(dir:Int)
	{
		var sectionLength:Int = 16;

		dir *= (FlxG.keys.pressed.SHIFT ? 4 : 1);
		tweenSongPos(getSectionStart(curStepFloat + 1 + (sectionLength * dir)));
	}

	public function resetSection()
	{
		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.pressed.SHIFT)
				goToSong(audio.length - 1)
			else
				goToSong(0);
		}
		else
		{
			tweenSongPos(getSectionStart());
		}
	}

	public function goToSong(target:Float)
	{
		if (!tweeningSongPos)
		{
			if (Math.abs(Conductor.songPos - target) <= 10000 || noFunAllowed)
				tweenSongPos(target, 0.25, FlxEase.cubeInOut);
			else
			{
				FlxTween.tween(FlxG.camera, {zoom: 1.3}, 1.6, {ease: FlxEase.cubeIn, startDelay: 0.4});
				tweenSongPos(target, 2, FlxEase.cubeIn, (twn) ->
				{
					playSfx("editors/clank");
					FlxTween.completeTweensOf(FlxG.camera);
					FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.1, {ease: FlxEase.cubeOut});
					FlxG.camera.shake(0.02, 0.15);
				});
			}
		}
		else
		{
			FlxTween.completeTweensOf(Conductor);
		}
	}

	public function tweenSongPos(target:Float, duration:Float = 0.1, ?ease:EaseFunction, ?onComplete:FlxTween->Void)
	{
		target = FlxMath.bound(target, 0, audio.length);
		if (noFunAllowed)
			duration = 0;

		FlxTween.completeTweensOf(Conductor);
		tweeningSongPos = true;

		if (duration == 0)
		{
			Conductor.songPos = target;
			tweeningSongPos = false;
		}
		else
			FlxTween.tween(Conductor, {songPos: target}, duration, {
				ease: ease ?? FlxEase.cubeOut,
				onComplete: (twn) ->
				{
					tweeningSongPos = false;
					if (onComplete != null)
						onComplete(twn);
				}
			});
	}

	public function sortNotes()
	{
		CHART.notes.sort(NoteUtil.sortNotes);
	}

	public function sortEvents()
	{
		EVENTS.events.sort(EventUtil.sortEvents);
	}

	public function playSfx(key:String, pitchShift:Bool = true, startDelay:Float = 0.0)
	{
		var sfx = FlxG.sound.load(Assets.sound(key));
		if (pitchShift)
			sfx.pitch = FlxG.random.float(0.8, 1.2);
		if (startDelay <= 0.0)
			sfx.play();
		else
			new FlxTimer().start(startDelay, (tmr) ->
			{
				sfx.play();
			});
	}

	public function playMetronome(pitchShift:Bool = true)
	{
		var sfx = FlxG.sound.load(Assets.sound("metronome"), metronomeVolume);
		sfx.pitch = pitchShift ? 1.12 : 1;
		sfx.play();
	}

	override function draw()
	{
		renderNotes.killMembers();
		renderEvents.killMembers();

		for (noteData in CHART.notes)
		{
			var noteY:Float = grid.gridY + (noteData.stepTime * GRID_SIZE * GRID_ZOOM);
			var noteHeight:Float = GRID_SIZE + (GRID_SIZE * GRID_ZOOM * (noteData.length + 1));
			var noteskin:String = noteData.strumline == 0 ? META.assets.opponentNotes : META.assets.playerNotes;
			if (noteY < -noteHeight)
				continue;
			if (noteY > FlxG.height)
				break;

			var note:ChartingNote = cast renderNotes.recycle(ChartingNote);
			note.loadData(noteData, noteskin + (quantNotes ? '-quant' : ''));
			note.reloadSprite();
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();

			note.selected = false;
			if (!selectedNotes.contains(noteData))
				note.color = 0xFFFFFFFF;
			else
				note.selected = true;

			if (noteData.stepTime < curStepFloat)
				note.alpha = 0.4;

			note.zIndex = 2;
			note.setPosition(grid.gridX + (note.data.lane * GRID_SIZE) + (note.data.strumline * GRID_SIZE * GRID_LANES / 2), noteY);

			if (!renderNotes.members.contains(note))
				renderNotes.add(note);

			if (noteData.length > 0)
			{
				var hold:ChartingNote = cast renderNotes.recycle(ChartingNote);
				hold.loadData(noteData, noteskin + (quantNotes ? '-quant' : ''));
				hold.isHold = true;
				hold.reloadSprite();

				hold.setGraphicSize(GRID_SIZE * 0.25, GRID_SIZE * GRID_ZOOM * (noteData.length + 1));
				hold.updateHitbox();

				hold.setPosition(note.x + (GRID_SIZE - hold.width) / 2, note.y);
				hold.alpha = note.alpha;
				hold.shader = note.shader;

				hold.holdParent = note; // idk you might need it
				hold.zIndex = 1;

				if (!renderNotes.members.contains(hold))
					renderNotes.add(hold);
			}
		}

		eventAmounts.clear();
		for (eventData in EVENTS.events)
		{
			var eventY:Float = grid.gridY + (eventData.stepTime * GRID_SIZE * GRID_ZOOM);
			var eventOrder:Int = eventAmounts.get(Std.string(eventData.stepTime)) ?? 1;
			if (eventY < -GRID_SIZE || eventY > FlxG.height)
				continue;

			var event:ChartingEvent = cast renderEvents.recycle(ChartingEvent);
			event.reloadEvent(eventData);
			event.x = grid.gridX - ((event.width + EVENT_PADDING) * eventOrder) - EVENT_PADDING;
			event.y = eventY - (centerEvents ? event.height / 2 : 0);
			event.zIndex = 2;

			event.selected = false;
			if (!selectedEvents.contains(eventData))
				event.color = 0xFFFFFFFF;
			else
				event.selected = true;

			if (!renderEvents.members.contains(event))
				renderEvents.add(event);

			var eventLength = EventUtil.getLength(eventData);
			if (eventLength >= 0)
			{
				//
				var hold:ChartingEvent = cast renderEvents.recycle(ChartingEvent);
				hold.reloadHold(eventLength);
				hold.x = event.x + (event.width / 2) - (hold.width / 2);
				hold.y = event.y + (centerEvents ? event.height / 2 : 0);
				hold.selected = event.selected;
				hold.zIndex = 1;
				if (!hold.selected)
					hold.color = 0xFFFFFFFF;
				if (!renderEvents.members.contains(hold))
					renderEvents.add(hold);
			}

			eventAmounts.set(Std.string(eventData.stepTime), eventOrder + 1);
		}

		renderNotes.sort(ZIndex.sort);
		renderEvents.sort(ZIndex.sort);

		super.draw();

		if (cursorTxt.text != "")
		{
			cursorTxt.setPosition(FlxG.mouse.x + 18, FlxG.mouse.y + 18);
			cursorTxt.draw();
		}

		if (autoScrolling)
			scrollBall.draw();
	}

	override function stepHit()
	{
		super.stepHit();
		if (audio.playing && Conductor.songPos >= 0)
			audio.sync();
	}

	override function beatHit()
	{
		super.beatHit();
		if (playingSong && metronome)
			playMetronome(curBeat % 4 == 0);
	}

	public var CHART(get, never):DoidoChart;

	public function get_CHART():DoidoChart
		return SONG.CHART;

	public var EVENTS(get, never):DoidoEvents;

	public function get_EVENTS():DoidoEvents
		return SONG.EVENTS;

	public var META(get, never):DoidoMeta;

	public function get_META():DoidoMeta
		return SONG.META;
}

class ChartingGrid extends FlxSprite
{
	public var GRID_SIZE:Float = 0.0;
	public var gridX:Float = 0.0;
	public var gridY:Float = 0.0;
	public var gridLength:Int = 0;

	public var length:Float = 0.0;

	public var border:FlxSprite;
	public var sectBG:FlxSprite;
	public var sectCap:FlxSprite;
	public var sectText:FlxBitmapText;
	public var midLine:FlxSprite;
	public var beatLine:FlxSprite;

	private var hoverSquare:FlxSprite;

	public function new(x:Float, length:Float, hoverSquare:FlxSprite)
	{
		super();
		gridX = x;
		this.length = length;
		this.hoverSquare = hoverSquare;
		GRID_SIZE = ChartingState.GRID_SIZE;
		this.makeColor(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);

		border = new FlxSprite(gridX - GRID_SIZE * 0.25).makeColor(GRID_SIZE * 8.5, FlxG.height, 0xFF1C1A24);

		sectBG = new FlxSprite().makeColor(1, 1, 0xFF1C1A24);
		sectCap = new FlxSprite().loadImage("editors/charting/sectionCap");

		sectText = new FlxBitmapText(0, 0, Assets.bitmapFont("phantommuff"));
		sectText.alignment = CENTER;
		sectText.scale.set(0.8, 0.8);
		sectText.updateHitbox();

		midLine = new FlxSprite(gridX + GRID_SIZE * 4).makeColor(4, FlxG.height, 0xFF1C1A24);
		midLine.x -= midLine.width / 2;

		beatLine = new FlxSprite(gridX, 0).makeColor(GRID_SIZE * 8, 4, 0xFFFFFFFF);
	}

	override function draw()
	{
		var minGrid:Int = 0;
		var maxGrid:Int = 0;

		border.draw();
		gridLength = Math.ceil(Conductor.getStepAtTime(length) * ChartingState.GRID_ZOOM);
		for (_y in 0...gridLength)
		{
			var gridY:Float = gridY + (GRID_SIZE * _y);
			if (gridY < -GRID_SIZE)
			{
				minGrid++;
				continue;
			}
			maxGrid = _y + 1;
			if (gridY > FlxG.height)
				break;

			// grid squares
			for (_x in 0...8)
			{
				color = (((_x + _y) % 2 == 0) ? 0xFFEBEFFE : 0xFFD7D9F6);
				x = gridX + (GRID_SIZE * _x);
				y = gridY;
				super.draw();
			}
		}

		// hover squares
		if (hoverSquare.visible)
			hoverSquare.draw();

		for (_y in minGrid...maxGrid)
		{
			var zoomedY:Float = (_y / ChartingState.GRID_ZOOM);
			var gridY:Float = gridY + (GRID_SIZE * _y);
			// beat lines and section numbers
			if (zoomedY % 4 == 0)
			{
				beatLine.color = (zoomedY % 16 == 0) ? 0xFF1C1A24 : 0xFFA5B1E4;
				beatLine.scale.y = (zoomedY % 16 == 0) ? 8 : 4;
				beatLine.updateHitbox();

				beatLine.y = gridY - (beatLine.height / 2);
				beatLine.draw();
			}

			// section numbers
			if (zoomedY % 16 == 0)
			{
				sectText.text = '${Math.floor(zoomedY / 16)}'.lpad("0", 2);

				sectBG.scale.set(sectText.width + 12, sectText.height + 12);
				sectBG.updateHitbox();

				sectCap.scale.y = (sectBG.height / sectCap.frameHeight);
				sectCap.updateHitbox();

				sectBG.setPosition(border.x + border.width, gridY - (sectBG.height / 2));
				sectCap.setPosition(sectBG.x + sectBG.width - (sectCap.width / 2), sectBG.y);
				sectText.setPosition(sectBG.x + (12 / 2), sectBG.y + (12 / 2));
				sectCap.draw();
				sectBG.draw();
				sectText.draw();
			}
		}
		midLine.draw();
	}
}

class GridWindow extends DoidoWindow
{
	var windowTitle:FlxBitmapText;
	var zoomTxt:FlxBitmapText;
	var snapTxt:FlxBitmapText;

	var songName:PsychUIInputText;
	var zoomStepper:PsychUINumericStepper;
	var snapDrowUp:PsychUIDropDownMenu;

	public function new(chartState:ChartingState)
	{
		super(chartState);
		bg.scale.set(190, 104);
		bg.updateHitbox();
		bg.setPosition(18, FlxG.height - bg.height - 18);

		windowTitle = new FlxBitmapText(bg.x + 6, bg.y + 12, Assets.bitmapFont("phantommuff"));
		windowTitle.alignment = LEFT;
		windowTitle.text = "Grid Settings: ";
		windowTitle.scale.set(0.625, 0.625);
		windowTitle.updateHitbox();
		add(windowTitle);

		zoomTxt = new FlxBitmapText(bg.x + 6, windowTitle.y + 32, Assets.bitmapFont("phantommuff"));
		zoomTxt.alignment = LEFT;
		zoomTxt.text = "Zoom: ";
		zoomTxt.color = 0xFFD8DAF6;
		zoomTxt.scale.set(0.625, 0.625);
		zoomTxt.updateHitbox();
		add(zoomTxt);

		zoomStepper = new PsychUINumericStepper(bg.x + 82, windowTitle.y + 30, 0.25, ChartingState.GRID_ZOOM, 0.25, 4, 2, 100, true);
		zoomStepper.onValueChange = () ->
		{
			ChartingState.GRID_ZOOM = zoomStepper.value;
		};
		add(zoomStepper);

		snapTxt = new FlxBitmapText(bg.x + 6, zoomTxt.y + 32, Assets.bitmapFont("phantommuff"));
		snapTxt.alignment = LEFT;
		snapTxt.text = "Snap: ";
		snapTxt.color = 0xFFD8DAF6;
		snapTxt.scale.set(0.625, 0.625);
		snapTxt.updateHitbox();
		add(snapTxt);

		var snaps:Array<String> = [
			"NONE", "4th", "8th", "12th", "16th", "20th", "24th", "32th", "48th", "64th", "96th", "192th"
		];
		snaps.reverse();
		snapDrowUp = new PsychUIDropDownMenu(bg.x + 82, zoomTxt.y + 30, snaps, (i, s) ->
		{
			if (s == "NONE")
				s = "0th";
			ChartingState.GRID_SNAP = Std.parseInt(s.replace("th", ""));
		}, 100, true);
		snapDrowUp.selectedLabel = (ChartingState.GRID_SNAP == 0 ? "NONE" : '${ChartingState.GRID_SNAP}th');
		add(snapDrowUp);
	}
}

class TimeWindow extends DoidoWindow
{
	public static var oldTimer:Bool = false;

	public var timeTxt:FlxBitmapText;
	public var infoTxt:FlxBitmapText;
	public var timeBar:DoidoBar;
	public var timeBall:FlxSprite;
	public var buttons:Array<FlxSprite> = [];

	public function new(chartState:ChartingState)
	{
		super(chartState);
		bg.scale.set(458, 138);
		bg.updateHitbox();
		bg.setPosition(FlxG.width - bg.width - 18, FlxG.height - bg.height - 18);

		timeTxt = new FlxBitmapText(bg.x + 8, bg.y + 8, Assets.bitmapFont("phantommuff"));
		timeTxt.alignment = LEFT;
		add(timeTxt);

		infoTxt = new FlxBitmapText(bg.x + 8, timeTxt.y + 32, Assets.bitmapFont("phantommuff"));
		infoTxt.color = 0xFFD8DAF6;
		infoTxt.alignment = LEFT;
		infoTxt.scale.set(0.625, 0.625);
		infoTxt.updateHitbox();
		add(infoTxt);

		timeBar = new DoidoBar("editors/charting/timeBar", "editors/charting/timeBar-border");
		timeBar.setPosition(bg.x + (bg.width - timeBar.width) / 2, bg.y + bg.height - timeBar.height - 12);
		timeBar.sideR.color = 0xFF2A2C44;
		add(timeBar);

		timeBall = new FlxSprite(0, timeBar.y).loadImage("editors/charting/timeBall");
		timeBall.y += (timeBar.height - timeBall.height) / 2;
		add(timeBall);

		// play button
		addButton(0, 0, () ->
		{
			if (!chartState.tweeningSongPos)
				chartState.playingSong = !chartState.playingSong;
			/*else
				{
					FlxTween.completeTweensOf();
					FlxTween.color(btn, 0.4, 0xFFFF0000, 0xFFFFFFFF);
					FlxTween.shake(btn, 0.05, 0.4);
			}*/
		});

		// section buttons
		addButton(-32, 3, () ->
		{
			chartState.changeSection(-1);
		});
		addButton(32, 2, () ->
		{
			chartState.changeSection(1);
		});

		// reset button
		addButton(64, 4, () ->
		{
			chartState.resetSection();
		});
	}

	override function draw()
	{
		var timeText:String = "Time: " + getTime(Conductor.songPos) + " / " + getTime(chartState.audio.length);
		if (timeTxt.text != timeText)
			timeTxt.text = timeText;

		var infoText:String = "";
		infoText += "Step: " + Math.floor(chartState.curStepFloat * 100) / 100;
		infoText += "\nBeat: " + Math.floor(chartState.curStepFloat / 4 * 100) / 100;
		infoText += "\nBPM: " + Math.floor(Conductor.bpm * 1000) / 1000;
		if (infoTxt.text != infoText)
			infoTxt.text = infoText;

		timeBar.percent = (1.0 - (Conductor.songPos / chartState.audio.length)) * 100;
		timeBall.x = FlxMath.lerp(timeBar.x, timeBar.x + timeBar.width, 1 - (timeBar.percent / 100)) - (timeBall.width / 2);

		// time button!!
		buttons[0].animation.curAnim.curFrame = (chartState.playingSong ? 1 : 0);

		super.draw();
	}

	public function addButton(xOffset:Float, frame:Int, func:Void->Void)
	{
		var newBtn = new DoidoButton(func);
		newBtn.loadSparrow("editors/charting/timeButtons");
		newBtn.animation.addByPrefix("btn", "timeButtons", 0, false);
		newBtn.animation.play("btn", true, false, frame);
		buttons.push(newBtn);
		add(newBtn);

		newBtn.x = (bg.x + (bg.width - newBtn.width) / 2) + xOffset;
		newBtn.y = timeBar.y - newBtn.height - 12;
	}

	var scrubbing:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(timeBar.border) || FlxG.mouse.overlaps(timeBall))
		{
			chartState.curCursor = POINTER;
			if (FlxG.mouse.justPressed)
				scrubbing = true;
		}

		if (scrubbing)
		{
			chartState.curCursor = POINTER;
			chartState.playingSong = false;

			Conductor.songPos = FlxMath.bound(FlxMath.remapToRange(FlxG.mouse.x, timeBar.x, timeBar.x + timeBar.width, 0, chartState.audio.length), 0,
				chartState.audio.length);

			if (!FlxG.mouse.pressed)
				scrubbing = false;
		}
	}

	public function getTime(time:Float):String
	{
		time /= 1000;
		if (!oldTimer) // new timer
			return FlxStringUtil.formatTime(time, true);
		else // old timer
			return '${Math.floor(time * 100) / 100}';
	}
}
