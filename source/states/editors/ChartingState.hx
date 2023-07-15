package states.editors;

import flixel.FlxG;
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

class ChartingState extends MusicBeatState
{
	public static var SONG:SwagSong = SongData.defaultSong();

	public static var curSection:Int = 0;

	public static var GRID_SIZE:Int = 40;

	var selectSquare:FlxSprite;

	var mainGrid:FlxSprite;
	var sectionGrids:FlxTypedGroup<FlxSprite>;
	var renderedNotes:FlxTypedGroup<Note>;

	var songLine:FlxSprite;
	var infoTxt:FlxText;

	override function create()
	{
		super.create();
		reloadAudio();

		var bg = new FlxSprite().loadGraphic(Paths.image("menu/backgrounds/menuDesat"));
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.4;
		add(bg);

		sectionGrids = new FlxTypedGroup<FlxSprite>();
		add(sectionGrids);

		// renders the previous the current and the next section
		for(i in 0...3)
		{
			var gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
			gridBG.ID = i;
			sectionGrids.add(gridBG);

			gridBG.x = (FlxG.width / 2) - (gridBG.width / 2);
			gridBG.y = (GRID_SIZE * 16) * (i - 1);

			// if not the current section
			if(i != 1)
				gridBG.alpha = 0.4;
			else
				mainGrid = gridBG;

			for(b in 0...4)
			{
				var beatLine = new FlxSprite().makeGraphic(GRID_SIZE * 8, 2, 0xFFFF0000);
				beatLine.x = gridBG.x;
				beatLine.y = gridBG.y + (GRID_SIZE * 4 * b);
				sectionGrids.add(beatLine);

				beatLine.alpha = 0.9;
				if(i != 1)
					beatLine.alpha = 0.4;
			}

			var gridCut = new FlxSprite().makeGraphic(2, GRID_SIZE * 16, 0xFF000000);
			gridCut.x = (FlxG.width / 2) - (gridCut.width / 2);
			gridCut.y = gridBG.y;
			sectionGrids.add(gridCut);
		}

		iconBf = new HealthIcon();
		iconDad = new HealthIcon();
		add(iconBf);
		add(iconDad);
		reloadIcons(true);

		renderedNotes = new FlxTypedGroup<Note>();
		add(renderedNotes);

		selectSquare = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE, 0xFFFFFFFF);
		selectSquare.alpha = 0.7;
		add(selectSquare);

		songLine = new FlxSprite().makeGraphic(GRID_SIZE * 8, 4, 0xFFFFFFFF);
		songLine.x = (FlxG.width / 2) - (songLine.width / 2);
		add(songLine);

		infoTxt = new FlxText(0, 0, 0, "", 20);
		//infoTxt.setFormat(Main.gFont, 20, 0xFFFFFFFF, LEFT);
		//infoTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		infoTxt.scrollFactor.set();
		add(infoTxt);

		reloadSection(curSection);
	}

	public var iconBf:HealthIcon;
	public var iconDad:HealthIcon;
	public function reloadIcons(changeIcon:Bool = false)
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

	public function getSection(daSec:Int):SwagSection
	{
		if(SONG.notes[curSection] == null)
			SONG.notes[curSection] = SongData.defaultSection();

		return SONG.notes[curSection];
	}

	public function reloadAudio()
	{
		songList = [];

		var daSong:String = SONG.song.toLowerCase();

		var inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);
		songList.push(inst);

		var vocals = new FlxSound();
		vocals.loadEmbedded(Paths.vocals(daSong), false, false);
		songList.push(vocals);
	}

	public var conductorOffset:Float = 0;

	public function reloadSection(?curSection:Int = 0, ?reloadConductor:Bool = true)
	{
		if(curSection < 0) return;

		ChartingState.curSection = curSection;
		renderedNotes.clear();

		// checking if it exists
		var existCheck = getSection(curSection);

		Conductor.setBPM(SONG.bpm);
		conductorOffset = 0;

		var daSec:Int = 0;
		for(section in SONG.notes)
		{
			if(Math.abs(curSection - daSec) <= 1)
			{
				if(section.changeBPM && Conductor.bpm != section.bpm)
					Conductor.setBPM(section.bpm);

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
					swagNote.reloadNote(daStrumTime, daNoteData, daNoteType);
					renderedNotes.add(swagNote);

					swagNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
					swagNote.updateHitbox();

					swagNote.x = mainGrid.x + (GRID_SIZE * swagNote.noteData);

					var isPlayer = (songNotes[1] >= 4);
					if(section.mustHitSection)
						isPlayer = (songNotes[1] <  4);

					swagNote.strumlineID = isPlayer ? 1 : 0;

					if((isPlayer && !section.mustHitSection)
					|| (!isPlayer && section.mustHitSection))
						swagNote.x += (GRID_SIZE * 4);

					var actualTime:Float = swagNote.songTime - (Conductor.crochet * 4 * daSec);

					swagNote.y = FlxMath.remapToRange(actualTime, 0, Conductor.stepCrochet, 0, GRID_SIZE);

					if(curSection != daSec)
					{
						swagNote.alpha = 0.4;
						swagNote.y += (GRID_SIZE * 16) * (daSec - curSection);
					}
				}
			}
			if(daSec < curSection)
			{
				conductorOffset += (Conductor.crochet * 4);
			}
			daSec++;
		}

		reloadIcons();
		if(reloadConductor)
		{
			Conductor.songPos = conductorOffset;
			curStep = _curStep;
			stepHit();
		}
	}

	public var playing:Bool = false;
	public var songList:Array<FlxSound> = [];

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.justPressed.ENTER)
		{
			PlayState.SONG = SONG;
			Main.switchState(new PlayState());
		}

		if(FlxG.keys.justPressed.SPACE)
			playing = !playing;

		if(FlxG.mouse.overlaps(mainGrid))
		{
			var sizeTimed:Float = GRID_SIZE;

			selectSquare.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			selectSquare.y = Math.floor(FlxG.mouse.y / sizeTimed) * sizeTimed;
			selectSquare.visible = true;

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
					var newNote:Array<Dynamic> = [conductorOffset, 0, 0, "none"];

					newNote[0] += Math.floor((FlxG.mouse.y - mainGrid.y) / sizeTimed) * Conductor.stepCrochet;
					newNote[1] = Math.floor((FlxG.mouse.x - mainGrid.x) / GRID_SIZE);

					trace(newNote);
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
								getSection(curSection).sectionNotes.remove(note);
							else
							{
								trace("should have selected but whatev");
							}
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
				if(Conductor.songPos < 0)
					Conductor.songPos = 0;
			}
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

		songLine.y = (Conductor.songPos - conductorOffset) * (GRID_SIZE / Conductor.stepCrochet);

		var changeSecPrev:Bool = false;
		var changeSecNext:Bool = false;
		var backScroll:Bool = false;

		if(FlxG.keys.justPressed.A)
		{
			playing = false;
			changeSecPrev = true;
		}
		if(FlxG.keys.justPressed.D)
		{
			playing = false;
			changeSecNext = true;
		}

		if(Conductor.songPos < conductorOffset)
		{
			backScroll = true;
			changeSecPrev = true;
		}
		if(Conductor.songPos > conductorOffset + (Conductor.stepCrochet * 16))
			changeSecNext = true;

		if(changeSecPrev)
			reloadSection(curSection - 1);
		if(changeSecNext)
			reloadSection(curSection + 1);

		if(backScroll)
			Conductor.songPos += (Conductor.stepCrochet * 16);

		// manually setting up the camera scroll cuz yes
		FlxG.camera.scroll.y = songLine.y + (songLine.height / 2) - (FlxG.height / 2);

		//infoTxt.graphic.dump();
		infoTxt.text = ""
		+ "Time: " + Std.string(Math.floor(Conductor.songPos / 1000 * 100) / 100)
		+ "\nStep: " + curStep
		+ "\nBeat: " + curBeat
		+ "\nSect: " + curSection;
		infoTxt.x = mainGrid.x + mainGrid.width + 16;
		infoTxt.y = FlxG.height - infoTxt.height - 16;
	}
}