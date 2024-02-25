package states.editors;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.GameData.MusicBeatState;
import gameObjects.*;
import gameObjects.hud.note.*;
import gameObjects.hud.HealthIcon;
import states.PlayState;
import states.LoadSongState;
import subStates.editors.*;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import sys.FileSystem;

using StringTools;

class ChartingState extends MusicBeatState
{
	public static var SONG:SwagSong = SongData.defaultSong();
	public static var songDiff:String = "normal";

	public static var curSection:Int = 0;

	public static var GRID_SIZE:Int = 40; // 40
	public static var GRID_SNAP:Int = 16;
	public var GRID_ZOOM:Float = 1;

	var UI_box:FlxUITabMenu;

	static var curNoteType:String = 'none';
	var allNoteTypes:Array<String> = [
		'none',
		'no animation',
		'bomb',
	];

	var selectSquare:FlxSprite;
	var curSelectedNote:Array<Dynamic> = null;
	var curNoteSprite:Note;

	var playerHighlight:FlxSprite;

	var mainGrid:FlxSprite;
	var sectionGrids:FlxTypedGroup<ChartGrid>;
	var renderedNotes:FlxTypedGroup<Note>;
	var renderedTypes:FlxTypedGroup<FlxText>;

	var songLine:FlxSprite;
	var infoTxt:FlxText;

	var iconBf:HealthIcon;
	var iconDad:HealthIcon;

	var isTyping:Bool = false;
	var playing:Bool = false;
	public static var songList:Array<FlxSound> = [];

	static var playHitSounds:Array<Bool> = [true, true];
	var hitsound:FlxSound;

	override function create()
	{
		super.create();
		CoolUtil.playMusic();
		reloadAudio();
		Controls.setSoundKeys(true);
		FlxG.mouse.visible = true;
		PlayState.resetStatics();
		ChartTestSubState.downscroll = SaveData.data.get('Downscroll');

		// setting up the cameras
		var camGame = new FlxCamera();
		var camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		// adding the cameras
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		hitsound = new FlxSound().loadEmbedded(Paths.sound("hitsounds/OSU"), false, false);
		hitsound.play();
		hitsound.stop();
		FlxG.sound.list.add(hitsound);

		var bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuDesat"));
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.15;
		add(bg);

		sectionGrids = new FlxTypedGroup<ChartGrid>();
		add(sectionGrids);

		// renders the previous the current and the next section
		for(i in 0...3)
		{
			var grid = new ChartGrid();
			sectionGrids.add(grid);

			grid.ID = i;
			grid.reloadGrid(
				getSection(curSection + (i - 1)).lengthInSteps,
				GRID_ZOOM,
				i
			);

			if(i == 1)
				mainGrid = grid.grid;
		}
		//reloadGrids();
		playerHighlight = new FlxSprite().makeGraphic(GRID_SIZE * 4, GRID_SIZE, 0xFF20229F);
		playerHighlight.antialiasing = false;
		playerHighlight.alpha = 0.4;
		add(playerHighlight);

		iconBf = new HealthIcon();
		iconDad = new HealthIcon();
		add(iconBf);
		add(iconDad);
		reloadIcons(true);

		renderedNotes = new FlxTypedGroup<Note>();
		add(renderedNotes);

		renderedTypes = new FlxTypedGroup<FlxText>();
		add(renderedTypes);

		selectSquare = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
		selectSquare.alpha = 0.7;
		add(selectSquare);

		songLine = new FlxSprite().makeGraphic(GRID_SIZE * 8, 4, 0xFFFFFFFF);
		songLine.x = (FlxG.width / 2) - (songLine.width / 2);
		add(songLine);

		infoTxt = new FlxText(0, 0, 0, "", 20);
		//infoTxt.setFormat(Main.gFont, 20, 0xFFFFFFFF, LEFT);
		infoTxt.scrollFactor.set();
		add(infoTxt);

		var tabs = [
			{name: "Song", 	  label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note",	  label: 'Note'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 300);
		UI_box.scrollFactor.set();
		UI_box.x = mainGrid.x + mainGrid.width;
		UI_box.y = 20;
		add(UI_box);

		// reduced to a single function cuz its easier
		addUIStuff();

		reloadSection(curSection);
		updateInfoTxt();
	}

	function reloadGrids()
	{
		var shouldGridReload:Bool = false;

		for(grid in sectionGrids.members)
		{
			if(getSection(curSection + (grid.ID - 1)).lengthInSteps != grid.sectionLength
			|| grid.zoom != GRID_ZOOM)
				shouldGridReload = true;
		}

		for(grid in sectionGrids.members)
		{
			if(shouldGridReload)
			{
				grid.reloadGrid(
					getSection(curSection + (grid.ID - 1)).lengthInSteps,
					GRID_ZOOM,
					grid.ID
				);

				if(grid.ID == 1)
					mainGrid = grid.grid;
			}
		}
	}

	var copySectTxt:FlxText;
	
	var snapDropDown:FlxUIDropDownMenu;
	var stepperZoom:FlxUINumericStepper;

	var typingShit:Array<FlxUIInputText> = [];
	function addTypingShit(shit:Dynamic)
	{
		if(shit is FlxUIInputText)
			typingShit.push(shit);

		if(shit is FlxUINumericStepper)
		{
			var stepper:FlxUINumericStepper = cast shit;
			@:privateAccess{
				typingShit.push(cast(stepper.text_field));
			}
		}
	}

	function addUIStuff()
	{
		/*
		*
		*	SONG TAB
		*
		*/ 
		var tabSong = new FlxUI(null, UI_box);
		tabSong.name = "Song";
		UI_box.addGroup(tabSong);

		var songNameInput = new FlxUIInputText(10, 20, 180, SONG.song, 8);
		songNameInput.name = "song_name";
		addTypingShit(songNameInput);

		var check_voices = new FlxUICheckBox(10, 40, null, null, "Has voices", 48);
		check_voices.checked = SONG.needsVoices;
		check_voices.name = "check_voices";
		
		var songDiffInput = new FlxUIInputText(10+70, 50, 180-70, songDiff, 8);
		songDiffInput.name = "song_diff";
		addTypingShit(songDiffInput);

		var saveButton = new FlxButton(200, 10, "Save", function() {
			var formatSONG:SwagSong = SONG;
			for(section in formatSONG.notes)
				for(note in section.sectionNotes)
					if(note.length > 2)
						if(note[3] == 'none')
							note[3] = '';

			var json = {"song": formatSONG};

			var data:String = Json.stringify(json, "\t");

			if(data != null && data.length > 0)
			{
				var _file = new FileReference();
				_file.save(data.trim(), '${SONG.song.toLowerCase()}-$songDiff.json');
			}
		});

		var getAutoSave = new FlxButton(200, 30, "Load Autosave", function() {
			openSubState(new ChartAutoSaveSubState());
		});

		var reloadSong = new FlxButton(200, 50, "Reload Audio", function() {
			reloadAudio();
		});

		var reloadJson = new FlxButton(200, 70, "Reload JSON", function() {
			var daSong:String = SONG.song.toLowerCase();
			try
			{
				SONG = SongData.loadFromJson(daSong, songDiff);
				curSection = 0;
				Main.switchState();
			}
			catch(e)
			{
				var nop = new FlxText(0,0,0,"JSON NOT FOUND",18);
				add(nop);
				nop.moves = true;
				nop.color = 0xFFFF0000;
				nop.scrollFactor.set();
				nop.setPosition(UI_box.x + UI_box.width - 8, UI_box.y + 80);
				nop.velocity.y = -100;
				nop.acceleration.y = 300;
				FlxTween.tween(nop, {alpha: 0}, FlxG.random.float(0.4,0.8), {
					startDelay: 0.8,
					onComplete: function(twn:FlxTween) { nop.destroy(); }
				});
			}
		});
		
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65+5, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		addTypingShit(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80+5, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = SONG.speed;
		stepperSpeed.name = 'song_speed';	
		addTypingShit(stepperSpeed);

		var characters = CoolUtil.charList();
		
		var player1DropDown = new FlxUIDropDownMenu(140, 115, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			SONG.player1 = characters[Std.parseInt(character)];
			reloadIcons(true);
		});
		player1DropDown.selectedLabel = SONG.player1;

		var player2DropDown = new FlxUIDropDownMenu(10, 115, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			SONG.player2 = characters[Std.parseInt(character)];
			reloadIcons(true);
		});
		player2DropDown.selectedLabel = SONG.player2;
		
		var playTicksBf = new FlxUICheckBox(10, 230, null, null, 'BF Hitsounds', 100);
		playTicksBf.name = "bf_hitsounds";
		playTicksBf.checked = playHitSounds[1];

		var playTicksDad = new FlxUICheckBox(10, 250, null, null, 'Dad Hitsounds', 100);
		playTicksDad.name = "dad_hitsounds";
		playTicksDad.checked = playHitSounds[0];
		
		var stepperVolInst = new FlxUINumericStepper(110, 190, 0.1, 1, 0, 1.0, 2);
		stepperVolInst.value = Conductor.bpm;
		stepperVolInst.name = 'vol_inst';
		addTypingShit(stepperVolInst);
		
		var stepperVolVoices = new FlxUINumericStepper(110, 210, 1, 1, 0, 1.0, 2);
		stepperVolVoices.value = Conductor.bpm;
		stepperVolVoices.name = 'vol_voices';
		addTypingShit(stepperVolVoices);
		
		var muteInst:FlxUICheckBox = null;
		muteInst = new FlxUICheckBox(10, 190, null, null, 'Mute Inst', 100, function() {
			songList[0].volume = 0;
			if(!muteInst.checked)
				songList[0].volume = stepperVolInst.value;
		});
		var muteVoices:FlxUICheckBox = null;
		muteVoices = new FlxUICheckBox(10, 210, null, null, 'Mute Voices', 100, function() {
			if(songList.length <= 1) return;
			
			songList[1].volume = 0;
			if(!muteVoices.checked)
				songList[1].volume = stepperVolVoices.value;
		});

		var clearSongButton = new FlxButton(200, 250, "Clear Song", function() {
			SONG.notes = [];
			reloadSection(0);
		});
		clearSongButton.color = FlxColor.RED;
		clearSongButton.label.color = FlxColor.WHITE;
		
		tabSong.add(new FlxText(songNameInput.x, songNameInput.y - 15, 0, "Song Name: "));
		tabSong.add(songNameInput);
		tabSong.add(new FlxText(songDiffInput.x, songDiffInput.y - 15, 0, "Difficulty: "));
		tabSong.add(songDiffInput);
		tabSong.add(check_voices);
		tabSong.add(saveButton);
		tabSong.add(getAutoSave);
		tabSong.add(reloadSong);
		tabSong.add(reloadJson);
		tabSong.add(new FlxText(stepperSpeed.x + stepperSpeed.width, stepperSpeed.y, 0, ' :Song Speed'));
		tabSong.add(new FlxText(stepperBPM.x + stepperBPM.width, stepperBPM.y, 0, ' :BPM'));
		tabSong.add(stepperBPM);
		tabSong.add(stepperSpeed);
		tabSong.add(playTicksBf);
		tabSong.add(playTicksDad);
		tabSong.add(new FlxText(stepperVolInst.x   + stepperVolInst.width,   stepperVolInst.y,   0, ' :Inst Volume'));
		tabSong.add(new FlxText(stepperVolVoices.x + stepperVolVoices.width, stepperVolVoices.y, 0, ' :Voices Volume'));
		tabSong.add(stepperVolInst);
		tabSong.add(stepperVolVoices);
		tabSong.add(muteInst);
		tabSong.add(muteVoices);
		
		
		tabSong.add(clearSongButton);

		tabSong.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tabSong.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tabSong.add(player1DropDown);
		tabSong.add(player2DropDown);

		/*
		*
		*	SECTION TAB
		*
		*/ 
		var tabSect = new FlxUI(null, UI_box);
		tabSect.name = "Section";
		UI_box.addGroup(tabSect);

		var stepperLength = new FlxUINumericStepper(10, 10, 4, 16, 4, 48, 0);
		stepperLength.value = getSection(curSection).lengthInSteps;
		stepperLength.name = "section_length";
		addTypingShit(stepperLength);

		var check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = getSection(curSection).mustHitSection;

		var check_changeBPM = new FlxUICheckBox(10, 70, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		var stepperSectionBPM = new FlxUINumericStepper(10, 90, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.name = 'section_bpm';
		stepperSectionBPM.value = Conductor.bpm;
		addTypingShit(stepperSectionBPM);
		//getSection(curSection).bpm = stepper.value;

		copySectTxt = new FlxText(0,0,0,"");

		var stepperCopy = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);
		stepperCopy.name = 'section_copy';
		var copyButton = new FlxButton(10, 130, "Copy last sect", function()
		{
			if(Std.int(stepperCopy.value) == 0) return;
			var daSec:Int = curSection - Std.int(stepperCopy.value);
			if(daSec < 0) daSec = 0;

			var daNums:Array<Int> = [curSection, daSec];
			if (daNums[1] < daNums[0])
				daNums.reverse();

			var copyOffset:Float = 0;
			var daCrochet:Float = Conductor.calcStep(Conductor.bpm);
			for(i in daNums[0]...daNums[1])
			{
				//trace('looped $i');
				var section = getSection(i);
				if(section.changeBPM)
					daCrochet = Conductor.calcStep(section.bpm);

				copyOffset += (section.lengthInSteps * daCrochet);
			}
			for(i in 0...getSection(daSec).sectionNotes.length)
			{
				var cn:Array<Dynamic> = getSection(daSec).sectionNotes[i];
				var note:Array<Dynamic> = [cn[0], cn[1], cn[2], cn[3]];

				note[0] += copyOffset * ((stepperCopy.value > 0) ? 1 : -1);

				getSection(curSection).sectionNotes.push(note);
			}
			reloadSection(curSection, false);
		});
		addTypingShit(stepperCopy);

		copySectTxt.text = 'Section: ' + (curSection - 1);
		copySectTxt.setPosition(stepperCopy.x + stepperCopy.width + 8, stepperCopy.y);

		var clearSectionButton = new FlxButton(10, 150, "Clear Section", function() {
			getSection(curSection).sectionNotes = [];
			reloadSection(curSection, false);
		});
		var swapSection = new FlxButton(10, 170, "Swap section", function()
		{
			for(i in 0...getSection(curSection).sectionNotes.length)
			{
				var note:Array<Dynamic> = getSection(curSection).sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				getSection(curSection).sectionNotes[i] = note;
			}
			reloadSection(curSection, false);
		});


		tabSect.add(stepperLength);
		tabSect.add(stepperSectionBPM);
		tabSect.add(copySectTxt);
		tabSect.add(stepperCopy);
		tabSect.add(copyButton);
		tabSect.add(check_mustHitSection);
		tabSect.add(check_changeBPM);
		tabSect.add(clearSectionButton);
		tabSect.add(swapSection);

		/*
		*
		*	NOTE TAB
		*
		*/
		var tabNote = new FlxUI(null, UI_box);
		tabNote.name = "Note";
		UI_box.addGroup(tabNote);

		var stepperSusLength = new FlxUINumericStepper(10, 20, Conductor.stepCrochet / 2, 0, 0, songLength);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		addTypingShit(stepperSusLength);
		if(curSelectedNote != null)
			updateCurNote();
		
		var noteTypeDropDown = new FlxUIDropDownMenu(10, 60, FlxUIDropDownMenu.makeStrIdLabelArray(allNoteTypes, true), function(daType:String)
		{
			curNoteType = allNoteTypes[Std.parseInt(daType)];
			reloadSection(curSection, false);
		});
		noteTypeDropDown.name = "dropdown_noteType";
		noteTypeDropDown.selectedLabel = curNoteType;
		
		var convertSide:String = 'ALL';
		var convertOptions:Array<String> = ['ALL', 'DAD NOTES', 'BF NOTES'];
		var convertDropDown = new FlxUIDropDownMenu(noteTypeDropDown.x, 100,
		FlxUIDropDownMenu.makeStrIdLabelArray(convertOptions, true), function(value:String)
		{
			convertSide = convertOptions[Std.parseInt(value)];
		});
		convertDropDown.selectedLabel = convertSide;
		
		var convertButton:FlxButton = new FlxButton(10 + noteTypeDropDown.width + 10, convertDropDown.y, "Convert Notes", function()
		{
			for(note in getSection(curSection).sectionNotes)
			{
				var isPlayer = (note[1] >= 4);
				if(getSection(curSection).mustHitSection)
					isPlayer = (note[1] <  4);

				if(isPlayer && convertSide == 'DAD NOTES') continue;
				if(!isPlayer && convertSide == 'BF NOTES') continue;

				note[3] = noteTypeDropDown.selectedLabel;
			}
			reloadSection(curSection, false);
		});
		
		tabNote.add(new FlxText(stepperSusLength.x, stepperSusLength.y - 15, 0, 'Note Length:'));
		tabNote.add(stepperSusLength);
		tabNote.add(convertButton);
		tabNote.add(new FlxText(convertDropDown.x,  convertDropDown.y  - 15, 0, 'Convert Note Types:'));
		tabNote.add(convertDropDown);
		tabNote.add(new FlxText(noteTypeDropDown.x, noteTypeDropDown.y - 15, 0, 'Note Type:'));
		tabNote.add(noteTypeDropDown);

		/*
		*	LEFT HUD
		*
		*	GRID TAB
		*/
		var UI_left = new FlxUITabMenu(null, [{name: "Grid", label: 'Grid Settings'}], true);
		UI_left.resize(140, 100);
		UI_left.scrollFactor.set();
		UI_left.x = mainGrid.x - UI_left.width;
		UI_left.y = 20;
		add(UI_left);

		var tabGrid = new FlxUI(null, UI_left);
		tabGrid.name = "Grid";
		UI_left.addGroup(tabGrid);
		
		stepperZoom = new FlxUINumericStepper(10, 20, 1, 1, -1, 4, 0);
		stepperZoom.name = 'grid_zoom';
		stepperZoom.value = GRID_ZOOM;
		addTypingShit(stepperZoom);
		
		formatSnaps = [];
		for(i in 0...allSnaps.length)
		{
			if(i == 0)
				formatSnaps.push("none");
			else
				formatSnaps.push('${allSnaps[i]}th');
		}
		
		snapDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(formatSnaps, true), function(daType:String)
		{
			updateSnapLabel(Std.parseInt(daType));
		});
		snapDropDown.name = "dropdown_snap";
		updateSnapLabel(curSnapNum);

		tabGrid.add(new FlxText(10, stepperZoom.y - 15, 0, "Grid Zoom:"));
		tabGrid.add(stepperZoom);
		tabGrid.add(new FlxText(10, snapDropDown.y - 15, 0, "Grid Snapping:"));
		tabGrid.add(snapDropDown);
	}
	
	function formatGridZoom(toStepper:Bool = false):Float
	{
		var balls:Array<Float> = [0.5, 0.25];
		if(toStepper)
			return (GRID_ZOOM == 0.5) ? 0 : (GRID_ZOOM == 0.25) ? -1 : GRID_ZOOM;
		else
			return (stepperZoom.value <= 0) ? (balls[Math.floor(Math.abs(stepperZoom.value))]) : stepperZoom.value;
	}
	
	final allSnaps:Array<Int> = [0, 4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
	var formatSnaps:Array<String> = [];
	static var curSnapNum:Int = 4; // 16
	
	function updateSnapLabel(snapNum:Int = 0)
	{
		curSnapNum = snapNum;
		
		curSnapNum = FlxMath.wrap(curSnapNum, 0, formatSnaps.length - 1);
		
		var snapText = formatSnaps[curSnapNum];
		snapText = snapText.replace("th", "");

		GRID_SNAP = 0;
		if(snapText != "none")
			GRID_SNAP = Std.parseInt(snapText);
		
		snapDropDown.selectedLabel = formatSnaps[allSnaps.indexOf(GRID_SNAP)];
		reloadSection(curSection, false);
		//trace('curSnap: ' + GRID_SNAP);
	}

	// set up your stuff down here
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		switch(id)
		{
			case FlxUIInputText.CHANGE_EVENT:
				var input:FlxUIInputText = cast sender;
				switch(input.name)
				{
					case 'song_name':
						SONG.song = input.text.toLowerCase();
					case 'song_diff':
						songDiff = input.text.toLowerCase();
				}

			case FlxUICheckBox.CLICK_EVENT:
				var check:FlxUICheckBox = cast sender;
				//switch(check.getLabel().text)
				switch(check.name)
				{
					case "dad_hitsounds": playHitSounds[0] = check.checked;
					case "bf_hitsounds":  playHitSounds[1] = check.checked;
					case "check_voices": 
						SONG.needsVoices = check.checked;
						reloadAudio();
					case "check_mustHit":
						getSection(curSection).mustHitSection = check.checked;
						reloadSection(curSection, false);
					case "check_changeBPM":
						getSection(curSection).changeBPM = check.checked;
						reloadSection(curSection);
				}

			case FlxUINumericStepper.CHANGE_EVENT:
				if(sender is FlxUINumericStepper)
				{
					var stepper:FlxUINumericStepper = cast sender;
					/*@:privateAccess{
						stepper.text_field.text = stepper.text_field.text.replace(' ', '');
						stepper.value = Std.parseFloat(stepper.text_field.text);
					}*/
					switch(stepper.name)
					{
						case 'song_speed':
							SONG.speed = stepper.value;
						case 'song_bpm':
							SONG.bpm = stepper.value;
							reloadSection(curSection, false);
						case 'note_susLength':
							if(curSelectedNote != null)
								curSelectedNote[2] = stepper.value;
							updateCurNote();
							reloadSection(curSection, false);
						case 'section_bpm':
							getSection(curSection).bpm = stepper.value;
							reloadSection(curSection, false);
						case 'section_length':
							getSection(curSection).lengthInSteps = Math.floor(stepper.value);
							reloadSection(curSection, false);
						case 'section_copy':
							copySectTxt.text = 'Section: ' + (curSection - Math.floor(stepper.value));
						case 'grid_zoom':
							GRID_ZOOM = formatGridZoom(false);//(stepper.value);
							reloadSection(curSection, false);
							
						case 'vol_inst':
							songList[0].volume = stepper.value;
						case 'vol_voices':
							if(songList.length <= 1) return;
							
							songList[1].volume = stepper.value;
					}
				}
		}
	}

	function updateCurNote()
	{
		if(curSelectedNote == null) return;

		for(group in UI_box.members)
		if(group is FlxUI)
		{
			var daGroup:FlxUI = cast group;
			for(item in daGroup.members)
			{
				if(item is FlxUIDropDownMenu)
				{
					var dropdown:FlxUIDropDownMenu = cast item;
					switch(dropdown.name)
					{
						case "dropdown_noteType":
							curNoteType = curSelectedNote[3];
							if(!allNoteTypes.contains(curNoteType))
								curNoteType = 'none';

							dropdown.selectedLabel = curNoteType;
					}
				}
				if(item is FlxUINumericStepper)
				{
					var stepper:FlxUINumericStepper = cast item;
					switch(stepper.name)
					{
						case "note_susLength":
							stepper.value = curSelectedNote[2];
					}
				}
			}
		}
	}

	function reloadIcons(changeIcon:Bool = false)
	{
		if(changeIcon)
		{
			iconBf.setIcon(SONG.player1);
			iconDad.setIcon(SONG.player2);

			for(icon in [iconBf, iconDad])
			{
				icon.setGraphicSize(64, 64);
				icon.updateHitbox();
				icon.scrollFactor.set();
				icon.y = (FlxG.height / 2) - (icon.height / 2);
			}
		}

		var iconPos:Array<Float> = [
			mainGrid.x - 64 - 16,
			mainGrid.x + mainGrid.width + 16
		];

		if(!getSection(curSection).mustHitSection)
			iconPos.reverse();

		iconBf.x  = iconPos[0];
		iconDad.x = iconPos[1];
	}

	/*  instead of doing a lot of if and elses
	* 	this function gets a section for you
	* 	without the risk of crashing the game (i hope)
	*/
	public static function getSection(daSec:Int):SwagSection
	{
		if(daSec < 0) daSec = 0;

		if(SONG.notes[daSec] == null)
			SONG.notes[daSec] = SongData.defaultSection();

		return SONG.notes[daSec];
	}

	// basically goes for the shortest audio
	public static var songLength:Float = 0;

	function reloadAudio()
	{
		songList = [];
		songLength = 0;
		function addMusic(music:FlxSound):Void
		{
			FlxG.sound.list.add(music);

			if(music.length > 0)
			{
				songList.push(music);

				if(music.length < songLength)
					songLength = music.length;
			}

			music.play();
			music.stop();
		}

		var daSong:String = SONG.song.toLowerCase();

		var inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);
		songLength = inst.length;
		addMusic(inst);

		if(SONG.needsVoices)
		{
			var vocals = new FlxSound();
			vocals.loadEmbedded(Paths.vocals(daSong), false, false);
			addMusic(vocals);
		}
	}

	var conductorOffset:Float = 0;

	function reloadSection(?curSection:Int = 0, ?reloadConductor:Bool = true)
	{
		if(curSection < 0) curSection = 0;

		ChartingState.curSection = curSection;
		renderedNotes.clear();
		renderedTypes.clear();

		// checking if it exists
		var existCheck = getSection(curSection);
		// (it just creates a new section if it doesnt)

		reloadGrids();

		// resetting it for the notes
		conductorOffset = 0;
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

		var noteSecOffset:Float = 0;
		var daSec:Int = 0;
		for(section in SONG.notes)
		{
			// changes the bpm from here onward
			if(section.changeBPM && Conductor.bpm != section.bpm)
				Conductor.setBPM(section.bpm);

			if(Math.abs(daSec - curSection) <= 1)
			{
				for(songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);
					var daNoteType:String = 'none';
					if(songNotes.length > 2)
						daNoteType = songNotes[3];

					// psych event notes come on
					if(songNotes[1] < 0) continue;

					var swagNote:Note = new Note();
					swagNote.reloadNote(daStrumTime, daNoteData, daNoteType, PlayState.assetModifier);

					swagNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
					swagNote.updateHitbox();

					swagNote.x = mainGrid.x + (GRID_SIZE * swagNote.noteData);

					var isPlayer = (songNotes[1] >= 4);
					if(getSection(curSection).mustHitSection)
						isPlayer = (songNotes[1] <  4);

					swagNote.strumlineID = isPlayer ? 1 : 0;

					if((isPlayer && !section.mustHitSection)
					|| (!isPlayer && section.mustHitSection))
						swagNote.x += (GRID_SIZE * 4);

					var gridTime:Float = swagNote.songTime - noteSecOffset;

					swagNote.y = 0;
					var daGrid = sectionGrids.members[daSec - curSection + 1];
					if(daGrid != null)
						swagNote.y = daGrid.grid.y;

					swagNote.y += FlxMath.remapToRange(gridTime, 0, Conductor.stepCrochet, 0, GRID_SIZE * GRID_ZOOM);

					if(curSection != daSec)
					{
						swagNote.ID = 0;
						swagNote.alpha = 0.2; // 0.4
						//swagNote.y += (GRID_SIZE * 16) * (daSec - curSection);
					}

					if(songNotes == curSelectedNote)
						curNoteSprite = swagNote;

					// if its long then
					var noteSustain:Float = songNotes[2];
					if(noteSustain > 0)
					{
						var holdNote = new Note();
						holdNote.isHold = true;
						holdNote.reloadNote(daStrumTime, daNoteData, daNoteType, PlayState.assetModifier);
						renderedNotes.add(holdNote);

						var formatHoldSize = FlxMath.remapToRange(noteSustain, 0, Conductor.stepCrochet, 0, GRID_SIZE * GRID_ZOOM);
						formatHoldSize += GRID_SIZE * (GRID_ZOOM - 1);

						holdNote.setGraphicSize(Math.floor(GRID_SIZE / 4), Math.floor(formatHoldSize));
						holdNote.updateHitbox();

						holdNote.y = swagNote.y + GRID_SIZE;
						holdNote.x = swagNote.x + (GRID_SIZE / 2) - (holdNote.width / 2);

						if(curSection != daSec)
							holdNote.alpha = 0.2; // 0.4
					}
					// adding it on top of everything
					renderedNotes.add(swagNote);

					if(curSection == daSec)
					{
						swagNote.ID = 1;
						if(allNoteTypes.contains(swagNote.noteType) && swagNote.noteType != "none")
						{
							//trace(swagNote.noteType);
							var numTxt:String = Std.string(allNoteTypes.indexOf(swagNote.noteType));

							var typeTxt = new FlxText(0,0,0,numTxt,16);
							typeTxt.setFormat(Main.gFont, Math.floor(GRID_SIZE / 1.3), 0xFFFFFFFF, CENTER);
							typeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
							typeTxt.x = (swagNote.x + swagNote.width / 2 - typeTxt.width / 2);
							typeTxt.y = (swagNote.y + swagNote.height/ 2 - typeTxt.height/ 2);
							renderedTypes.add(typeTxt);
						}
					}
				}
			}
			noteSecOffset += (Conductor.stepCrochet * section.lengthInSteps);
			if(daSec < curSection)
			{
				conductorOffset = noteSecOffset;
			}
			daSec++;
		}

		// setting it up correctly after spawning the notes
		Conductor.setBPM(SONG.bpm);
		for(change in Conductor.bpmChangeMap)
		{
			if(Conductor.songPos >= change.songTime && Conductor.bpm != change.bpm)
				Conductor.setBPM(change.bpm);
		}

		reloadIcons();
		if(reloadConductor)
		{
			Conductor.songPos = conductorOffset;
			stepHit();
		}
		updateInfoTxt();
		setHitNotes();

		playerHighlight.x = mainGrid.x + (getSection(curSection).mustHitSection ? 0 : GRID_SIZE * 4);
		playerHighlight.scale.y = (getSection(curSection).lengthInSteps) * GRID_ZOOM;
		playerHighlight.updateHitbox();

		// updating hud when you change sections
		for(group in UI_box.members)
		if(group is FlxUI)
		{
			var daGroup:FlxUI = cast group;
			for(item in daGroup.members)
			{
				if(item is FlxUICheckBox)
				{
					var check:FlxUICheckBox = cast item;
					switch(check.name)
					{
						case "check_mustHit":
							check.checked = getSection(curSection).mustHitSection;
						case "check_changeBPM":
							check.checked = getSection(curSection).changeBPM;
					}
				}
				if(item is FlxUINumericStepper)
				{
					var stepper:FlxUINumericStepper = cast item;
					switch(stepper.name)
					{
						case "section_length":
							stepper.value = getSection(curSection).lengthInSteps;
						case "section_bpm":
							stepper.value = Conductor.bpm;
						case "section_copy":
							copySectTxt.text = 'Section: ' + (curSection - Math.floor(stepper.value));
					}
				}
			}
		}
	}

	function setHitNotes()
	{
		for(note in renderedNotes.members)
		{
			note.gotHit = false;
			if(note.songTime < Conductor.songPos - 10 || note.mustMiss)
				note.gotHit = true;
		}
	}
	
	var curNoteSin:Float = 0;
	// even if you leave the state the
	// value will still count the 5 minutes
	static var autosavetimer:Float = 0;
	var globalMult:Int = 1;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		isTyping = false;
		for(i in typingShit)
			if(i.hasFocus)
				isTyping = true;
	
		Controls.setSoundKeys(isTyping);
		
		// autosaves every 5 minutes
		autosavetimer += elapsed;
		if(autosavetimer >= 60 * 5)
		{
			trace('autosaved');
			autosavetimer = 0;
			ChartAutoSaveSubState.addSave(SONG, songDiff);
		}

		if(curNoteSprite != null)
		{
			curNoteSin += elapsed * 8;
			curNoteSprite.alpha = 0.8 + Math.sin(curNoteSin) * 0.4;
		}

		if(!isTyping)
		{
			if(FlxG.keys.justPressed.LEFT)
				updateSnapLabel(curSnapNum - 1);
			if(FlxG.keys.justPressed.RIGHT)
				updateSnapLabel(curSnapNum + 1);

			globalMult = 1;
			if(FlxG.keys.pressed.SHIFT)
				globalMult = 4;
			
			var whad:Array<Bool> = [
				FlxG.keys.justPressed.Z,
				FlxG.keys.justPressed.X,
			];
			if(whad.contains(true))
			{
				var zoomArr:Array<Float> = [0.25, 0.5, 1, 2, 3, 4];
				var curNut:Int = zoomArr.indexOf(GRID_ZOOM);
				if(whad[0]) curNut--;
				if(whad[1]) curNut++;

				if(curNut < 0) curNut = 0;
				if(curNut >= zoomArr.length) curNut = zoomArr.length - 1;

				GRID_ZOOM = zoomArr[curNut];
				stepperZoom.value = formatGridZoom(true);
				
				reloadSection(curSection, false);
			}
			
			if(FlxG.keys.justPressed.ENTER)
			{
				FlxG.mouse.visible = false;
				ChartAutoSaveSubState.addSave(SONG, songDiff);
				PlayState.SONG = SONG;
				//Main.switchState(new PlayState());
				Main.switchState(new LoadSongState());
			}
			
			if(FlxG.keys.justPressed.ESCAPE)
			{
				persistentDraw = false;
				ChartTestSubState.startConductor = conductorOffset;
				openSubState(new ChartTestSubState());
			}

			if(FlxG.keys.justPressed.SPACE)
			{
				playing = !playing;

				setHitNotes();
			}

			if(FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				if(playing) playing = false;
				
				Conductor.songPos += 1000 * elapsed * (FlxG.keys.pressed.W ? -1 : 1) * globalMult / GRID_ZOOM;
			}
		}
		if(FlxG.mouse.wheel != 0)
		{
			if(FlxG.keys.pressed.CONTROL)
			{
				if(FlxG.mouse.wheel > 0)
					reloadSection(curSection - 1);
				if(FlxG.mouse.wheel < 0)
					reloadSection(curSection + 1);
			}
			else
			{
				Conductor.songPos += -FlxG.mouse.wheel * 5000 * globalMult * elapsed / GRID_ZOOM;
			}
		}
		
		if(FlxG.mouse.overlaps(mainGrid))
		{
			var zoomSnap:Float = (GRID_SNAP * GRID_ZOOM);
			var realSnap:Float = (zoomSnap / 16);

			var sizeTimed:Float = (GRID_SIZE / realSnap) * GRID_ZOOM;

			selectSquare.x = mainGrid.x + Math.floor((FlxG.mouse.x - mainGrid.x) / GRID_SIZE) * GRID_SIZE;
			selectSquare.y = mainGrid.y + Math.floor((FlxG.mouse.y - mainGrid.y) / sizeTimed) * sizeTimed;
			selectSquare.visible = true;

			if(GRID_SNAP == 0)
				selectSquare.y = FlxG.mouse.y;

			if(FlxG.mouse.justPressed)
			{
				var removeNote:Note = null;
				for(note in renderedNotes.members)
				{
					if(FlxG.mouse.overlaps(note) && !note.isHold)
						removeNote = note;
				}

				// add/remove a note
				if(removeNote == null)
				{
					// strumTime, noteData, sustainLength, noteType
					var newNote:Array<Dynamic> = [conductorOffset, 0, 0, curNoteType];

					newNote[0] += FlxMath.remapToRange(selectSquare.y, 0, GRID_SIZE * GRID_ZOOM, 0, Conductor.stepCrochet);
					newNote[1] = Math.floor((FlxG.mouse.x - mainGrid.x) / GRID_SIZE);

					//trace(newNote);
					curSelectedNote = newNote;
					updateCurNote();
					getSection(curSection).sectionNotes.push(newNote);
				}
				else
				{
					var nCheck:Array<Bool> = [removeNote.strumlineID == 1, getSection(curSection).mustHitSection];
					var rawNoteData:Int = removeNote.noteData;
					if((nCheck[0] && !nCheck[1]) || (!nCheck[0] && nCheck[1]))
						rawNoteData += 4;

					for(note in getSection(curSection).sectionNotes)
					{
						if(note[0] == removeNote.songTime
						&& note[1] == rawNoteData)
						{
							if(!FlxG.keys.pressed.CONTROL)
							{
								getSection(curSection).sectionNotes.remove(note);
								curSelectedNote = null;
							}
							else
							{
								curSelectedNote = note;
							}
							updateCurNote();
						}
					}
				}
				reloadSection(curSection, false);
			}
		}
		else
		{
			selectSquare.visible = false;
		}

		if(curSelectedNote != null)
		{
			if((FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E) && !isTyping)
			{
				var roundCrochet:Float = Math.floor(Conductor.stepCrochet * 100) / 100;

				curSelectedNote[2] += roundCrochet * (FlxG.keys.justPressed.Q ? -1 : 1);
				if(curSelectedNote[2] < 0
				|| curSelectedNote[2] > songLength) // sometimes it glitches
					curSelectedNote[2] = 0;

				reloadSection(curSection, false);
				updateCurNote();
				trace(curSelectedNote[2]);
			}
		}

		for(note in renderedNotes.members)
		{
			var canTap:Bool = true;
			var isPlayer:Bool = (note.strumlineID == 1);
			if((isPlayer && !playHitSounds[1]) || (!isPlayer && !playHitSounds[0]))
				canTap = false;

			if(!note.isHold && note.ID == 1 && playing && canTap)
			{
				if(note.songTime <= Conductor.songPos && !note.gotHit)
				{
					note.gotHit = true;
					hitsound.stop();
					hitsound.play();
				}
			}
		}

		if(Conductor.songPos < -Conductor.crochet)
			Conductor.songPos = -Conductor.crochet;
		if(Conductor.songPos >= songLength)
		{
			Conductor.songPos = 0;
			reloadSection();
		}

		if(playing)
		{
			Conductor.songPos += elapsed * 1000;

			if(FlxG.mouse.wheel != 0)
				playing = false;
		}

		for(song in songList)
		{
			if(playing && Conductor.songPos >= 0)
			{
				if(!song.playing)
					song.play(Conductor.songPos);
				if(Math.abs(song.time - Conductor.songPos) >= 40)
					song.time = Conductor.songPos;
			}
			if(!playing && song.playing)
				song.stop();
		}

		songLine.y = (Conductor.songPos - conductorOffset) * ((GRID_SIZE * GRID_ZOOM) / Conductor.stepCrochet);

		if(!isTyping)
		{
			var changeMult:Int = (FlxG.keys.pressed.SHIFT ? 4 : 1);

			if(FlxG.keys.justPressed.A)
			{
				playing = false;
				for(i in 0...changeMult)
					reloadSection(curSection - 1);
			}
			if(FlxG.keys.justPressed.D)
			{
				playing = false;
				for(i in 0...changeMult)
					reloadSection(curSection + 1);
			}

			if(FlxG.keys.justPressed.R)
			{
				if(FlxG.keys.pressed.SHIFT)
					reloadSection(0);
				else
					reloadSection(curSection);
			}
		}

		if(Conductor.songPos < conductorOffset && Conductor.songPos > 0)
		{
			reloadSection(curSection - 1);
			Conductor.songPos += (Conductor.stepCrochet * getSection(curSection).lengthInSteps);
		}
		if(Conductor.songPos > conductorOffset + (Conductor.stepCrochet * getSection(curSection).lengthInSteps))
			reloadSection(curSection + 1);

		// manually setting up the camera scroll cuz yes
		FlxG.camera.scroll.y = songLine.y + (songLine.height / 2) - (FlxG.height / 2);

		if(FlxG.keys.justPressed.T)
			updateInfoTxt();
	}
	
	// i know what im doing!! (im not)
	override function openSubState(target:flixel.FlxSubState)
	{
		playing = false;
		super.openSubState(target);
	}

	override function stepHit()
	{
		super.stepHit();
		curStep = _curStep;
		curBeat = Math.floor(_curStep / 4);
		updateInfoTxt();
	}

	function updateInfoTxt()
	{
		infoTxt.graphic.dump();
		infoTxt.text = ""
		+ "Time: " + Std.string(Math.floor(Conductor.songPos / 1000 * 100) / 100)
		+ " // "   + Std.string(Math.floor(songLength		 / 1000 * 100) / 100)
		+ "\nStep: " + curStep
		+ "\nBeat: " + curBeat
		+ "\nSect: " + curSection
		+ "\nBPM: " + Std.string(Conductor.bpm)
		+ '\nPress "T" to reload this';
		infoTxt.x = mainGrid.x + mainGrid.width + 16;
		infoTxt.y = FlxG.height - infoTxt.height - 16;
	}
}
class ChartGrid extends FlxGroup
{	
	public function new() {
		super();
	}

	public var grid:FlxSprite;
	public var sectionLength:Int = 16;
	public var zoom:Float = 1;

	public function reloadGrid(sectionLength:Int, zoom:Float, ?i:Int = 0)
	{
		this.sectionLength = sectionLength;
		this.zoom = zoom;

		//if(i == 1)
		//	trace('sucessfully reloaded');

		clear();
		var GRID_SIZE = ChartingState.GRID_SIZE;

		var stupidHeight:Int = Math.floor(GRID_SIZE * sectionLength * zoom);

		grid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, stupidHeight, true, 0xFF646464, 0xFF353535);
		add(grid);

		grid.x = (FlxG.width / 2) - (grid.width / 2);
		grid.y = switch(i)
		{
			case 0: -grid.height;
			default: 0;
			case 2: Math.floor(GRID_SIZE * (ChartingState.getSection(ChartingState.curSection).lengthInSteps) * zoom);
		}

		// if not the current section
		if(i != 1)
			grid.alpha = 0.4;

		var beatLineCount:Int = 4;
		if(zoom < 1.0)
			beatLineCount = (zoom == 0.5) ? 2 : 1;
		
		for(b in 0...Math.floor(sectionLength * zoom / beatLineCount))
		{
			var beatLine = new FlxSprite().makeGraphic(GRID_SIZE * 8, 2, 0xFFFF0000);
			beatLine.x = grid.x;
			beatLine.y = grid.y + (GRID_SIZE * beatLineCount * b);
			add(beatLine);
			
			beatLine.alpha = 0.9;
			if(i != 1)
				beatLine.alpha = 0.4;
		}

		var gridCut = new FlxSprite().makeGraphic(2, stupidHeight, 0xFF000000);
		gridCut.x = (FlxG.width / 2) - (gridCut.width / 2);
		gridCut.y = grid.y;
		add(gridCut);

		if(i != 1)
			gridCut.alpha = 0.4;
	}
}