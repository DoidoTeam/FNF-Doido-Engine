package states.editors;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
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
import flixel.system.FlxSound;
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

	public static var curSection:Int = 0;

	public static var GRID_SIZE:Int = 40;
	public static var GRID_SNAP:Int = 16;
	public static var GRID_ZOOM:Float = 1;

	var UI_box:FlxUITabMenu;

	static var curNoteType:String = 'none';
	var allNoteTypes:Array<String> = [
		'none',
		'no animation',
	];

	var selectSquare:FlxSprite;
	var curSelectedNote:Array<Dynamic> = null;

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
	var songList:Array<FlxSound> = [];

	static var playHitSounds:Array<Bool> = [true, true];
	var hitsound:FlxSound;

	override function create()
	{
		super.create();
		reloadAudio();

		// setting up the cameras
		var camGame = new FlxCamera();
		var camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		// adding the cameras
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		hitsound = new FlxSound().loadEmbedded(Paths.sound("hitsound"), false, false);
		hitsound.play();
		hitsound.stop();
		FlxG.sound.list.add(hitsound);

		var bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuDesat"));
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.4;
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
				grid.reloadGrid(
					getSection(curSection + (grid.ID - 1)).lengthInSteps,
					GRID_ZOOM,
					grid.ID
				);

			if(grid.ID == 1)
				mainGrid = grid.grid;
		}
	}

	//var songNameInput:FlxUIInputText;
	var typingShit:Array<FlxUIInputText> = [];

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

		var songNameInput = new FlxUIInputText(10, 10, 180, SONG.song, 8);
		songNameInput.name = "song_name";
		typingShit.push(songNameInput);

		var check_voices = new FlxUICheckBox(10, 30, null, null, "Has voice track", 100);
		check_voices.checked = SONG.needsVoices;
		check_voices.name = "check_voices";

		var saveButton = new FlxButton(200, 10, "Save", function() {
			var json = {"song": SONG};

			var data:String = Json.stringify(json);

			if(data != null && data.length > 0)
			{
				var _file = new FileReference();
				_file.save(data.trim(), SONG.song.toLowerCase() + ".json");
			}
		});

		var getAutoSave = new FlxButton(200, 30, "Load Autosave", function() {
			if(FlxG.save.data.chartAutoSave != null)
			{
				SONG = FlxG.save.data.chartAutoSave;
				curSection = 0;
				Main.switchState();
			}
		});

		var reloadSong = new FlxButton(200, 50, "Reload Audio", function() {
			reloadAudio();
		});

		var reloadJson = new FlxButton(200, 70, "Reload JSON", function() {
			var daSong:String = SONG.song.toLowerCase();
			if(FileSystem.exists(Paths.getPath('songs/$daSong/$daSong.json')))
			{
				SONG = SongData.loadFromJson(daSong);
				curSection = 0;
				Main.switchState();
			}
			else
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

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = SONG.speed;
		stepperSpeed.name = 'song_speed';

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = ["bf", "bf-pixel", "gemamugen"];

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

		var clearSongButton = new FlxButton(200, 250, "Clear Song", function() {
			SONG.notes = [];
			reloadSection(0);
		});
		clearSongButton.color = FlxColor.RED;
		clearSongButton.label.color = FlxColor.WHITE;

		tabSong.add(songNameInput);
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

		var check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = getSection(curSection).mustHitSection;

		var check_changeBPM = new FlxUICheckBox(10, 70, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		var stepperSectionBPM = new FlxUINumericStepper(10, 90, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.name = 'section_bpm';
		stepperSectionBPM.value = Conductor.bpm;
		//getSection(curSection).bpm = stepper.value;

		var stepperCopy = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);
		var copyButton = new FlxButton(10, 130, "Copy last section", function()
		{
			var lastSwag:SwagSection = getSection(curSection - Std.int(stepperCopy.value));
			for(i in 0...lastSwag.sectionNotes.length)
			{
				var cn:Array<Dynamic> = lastSwag.sectionNotes[i];
				var note:Array<Dynamic> = [cn[0], cn[1], cn[2], cn[3]];
				note[0] += (conductorOffset); // goes to the current section
				getSection(curSection).sectionNotes.push(note);
			}
			reloadSection(curSection, false);
		});

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
		if(curSelectedNote != null)
			updateCurNote();
		
		var noteTypeDropDown = new FlxUIDropDownMenu(10, 60, FlxUIDropDownMenu.makeStrIdLabelArray(allNoteTypes, true), function(daType:String)
		{
			curNoteType = allNoteTypes[Std.parseInt(daType)];
			reloadSection(curSection, false);
		});
		noteTypeDropDown.name = "dropdown_noteType";
		noteTypeDropDown.selectedLabel = curNoteType;
		
		var convertOptions:Array<String> = ['ALL', 'DAD NOTES', 'BF NOTES'];
		var convertDropDown = new FlxUIDropDownMenu(noteTypeDropDown.x, 100,
		FlxUIDropDownMenu.makeStrIdLabelArray(convertOptions, true), function(value:String)
		{
			//convertSide = convertOptions[Std.parseInt(value)];
		});
		//convertDropDown.selectedLabel = convertSide;
		
		var convertButton:FlxButton = new FlxButton(10 + noteTypeDropDown.width + 10, convertDropDown.y, "Convert Notes", function()
		{
			//convertSectionType();
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

		var stepperZoom = new FlxUINumericStepper(10, 20, 1, 1, 1, 4, 0);
		stepperZoom.name = 'grid_zoom';
		stepperZoom.value = 1;

		var allSnaps:Array<Int> = [0, 4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
		var formatSnaps:Array<String> = [];
		for(i in 0...allSnaps.length)
		{
			if(i == 0)
				formatSnaps.push("none");
			else
				formatSnaps.push('${allSnaps[i]}th');
		}

		var snapDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(formatSnaps, true), function(daType:String)
		{
			var snapText = formatSnaps[Std.parseInt(daType)];
			snapText = snapText.replace("th", "");

			GRID_SNAP = 0;
			if(snapText != "none")
				GRID_SNAP = Std.parseInt(snapText);

			trace('curSnap: ' + GRID_SNAP);
		});
		snapDropDown.name = "dropdown_snap";
		snapDropDown.selectedLabel = formatSnaps[allSnaps.indexOf(GRID_SNAP)];

		tabGrid.add(new FlxText(10, stepperZoom.y - 15, 0, "Grid Zoom:"));
		tabGrid.add(stepperZoom);
		tabGrid.add(new FlxText(10, snapDropDown.y - 15, 0, "Grid Snapping:"));
		tabGrid.add(snapDropDown);
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
						case 'grid_zoom':
							GRID_ZOOM = (stepper.value);
							reloadSection(curSection, false);
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
	var songLength:Float = 0;

	function reloadAudio()
	{
		songList = [];
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
					//if(section.mustHitSection)
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
						swagNote.alpha = 0.4;
						//swagNote.y += (GRID_SIZE * 16) * (daSec - curSection);
					}

					// if its long then
					var noteSustain:Float = songNotes[2];
					if(noteSustain > 0)
					{
						var holdNote = new Note();
						holdNote.isHold = true;
						holdNote.reloadNote(daStrumTime, daNoteData, daNoteType, PlayState.assetModifier);
						renderedNotes.add(holdNote);

						holdNote.setGraphicSize(Math.floor(GRID_SIZE / 4),
							Math.floor(FlxMath.remapToRange(noteSustain, 0, Conductor.stepCrochet, 0, GRID_SIZE * GRID_ZOOM)));
						holdNote.updateHitbox();

						holdNote.y = swagNote.y + GRID_SIZE;
						holdNote.x = swagNote.x + (GRID_SIZE / 2) - (holdNote.width / 2);

						if(curSection != daSec)
							holdNote.alpha = 0.4;
					}
					// adding it on top of everything
					renderedNotes.add(swagNote);

					if(curSection == daSec)
					{
						swagNote.ID = 1;
						//trace(swagNote.noteType);
						if(!["none", "default"].contains(swagNote.noteType))
						{
							var numTxt:String = Std.string(allNoteTypes.indexOf(swagNote.noteType));
							if(!allNoteTypes.contains(swagNote.noteType))
								numTxt = "??";

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
			if(note.songTime < Conductor.songPos - Conductor.stepCrochet)
				note.gotHit = true;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		isTyping = false;
		for(item in typingShit)
			if(item.hasFocus)
				isTyping = true;

		if(!isTyping)
		{
			if(FlxG.keys.justPressed.ENTER)
			{
				PlayState.SONG = SONG;
				Main.switchState(new PlayState());
			}

			if(FlxG.keys.justPressed.ESCAPE)
			{
				ChartTestState.startConductor = conductorOffset;
				ChartTestState.SONG = SONG;
				Main.switchState(new ChartTestState());
			}

			if(FlxG.keys.justPressed.SPACE)
			{
				playing = !playing;

				setHitNotes();
			}

			if(FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				Conductor.songPos += 1000 * elapsed * (FlxG.keys.pressed.W ? -1 : 1);
			}
		}
		if(FlxG.mouse.wheel != 0)
		{
			if(FlxG.keys.pressed.SHIFT)
			{
				if(FlxG.mouse.wheel > 0)
					reloadSection(curSection - 1);
				if(FlxG.mouse.wheel < 0)
					reloadSection(curSection + 1);
			}
			else
			{
				Conductor.songPos += -FlxG.mouse.wheel * 5000 * elapsed;
			}
		}

		if(FlxG.mouse.overlaps(mainGrid))
		{
			var realSnap:Float = (GRID_SNAP / 16);

			var sizeTimed:Float = (GRID_SIZE / realSnap) * GRID_ZOOM;

			selectSquare.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			selectSquare.y = Math.floor(FlxG.mouse.y / sizeTimed) * sizeTimed;
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

		grid = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, stupidHeight);
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
		
		for(b in 0...Math.floor(sectionLength * zoom / 4))
		{
			var beatLine = new FlxSprite().makeGraphic(GRID_SIZE * 8, 2, 0xFFFF0000);
			beatLine.x = grid.x;
			beatLine.y = grid.y + (GRID_SIZE * 4 * b);
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