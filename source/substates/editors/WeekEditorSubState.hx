package substates.editors;

import doido.objects.ui.PsychUIDropDownMenu;
import doido.objects.ui.DoidoRadio;
import doido.objects.ui.window.DoidoMenu.MenuWindow;
import doido.objects.ui.buttons.DoidoTextButton;
import doido.objects.ui.window.DoidoChooser.ChooserWindow;
import doido.objects.ui.window.DoidoWindow;
import doido.objects.ui.window.DoidoBox;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import doido.objects.ui.PsychUIInputText;
import states.menus.StoryMenuState;
import doido.song.Week;

class WeekEditorSubState extends MusicBeatSubState
{
	var storyMenu:StoryMenuState;
	var menu:DoidoBox;
	var bgWidth:Int = 318;

	var curWeek:WeekData;
	var curSong:WeekSong;
	var editingSong:String = "";
	var songList:Array<String>;

	public function new(week:WeekData, storyMenu:StoryMenuState)
	{
		super();
		this.storyMenu = storyMenu;
		curWeek = copyWeek(week);
		curSong = newSong();
		storyMenu.editingWeek = curWeek;
		storyMenu.reload();

		Main.setFpsPos(Main.fpsX, FlxG.height - Main.fpsHeight - 5);
		FlxG.mouse.visible = true;

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": 8 + 54;
				case "margin_second": 8 + 54 + 50;
				case "margin_right": 8 + bgWidth - width - 8;
				case "center": 8 + (bgWidth / 2) - (width / 2);
				default: 8 + 4;
			}
		}

		function getY(i:Int = 0)
			return 55 + 22 + 8 + 4 + (26 * i);

		var fileWindow:MenuWindow = new MenuWindow(8, 55 + 22 + 8, bgWidth, null);
		fileWindow.title = "File";

		var songWindow:DoidoWindow = new DoidoWindow(null);
		songWindow.title = "Songs";
		songWindow.bg.scale.set(bgWidth, 357 - 6);
		songWindow.bg.updateHitbox();
		songWindow.bg.setPosition(8, 55 + 22 + 8);

		var dataWindow:DoidoWindow = new DoidoWindow(null);
		dataWindow.title = "Data";
		dataWindow.bg.scale.set(bgWidth, 238);
		dataWindow.bg.updateHitbox();
		dataWindow.bg.setPosition(8, 55 + 22 + 8);

		var songs = new ChooserWindow(getX(), getY(0), 310, 200, [], null);
		songs.view = LIST;
		songs.type = NONE;
		songWindow.add(songs);

		var selected = createText(getX(), getY(8) + 3, "Selected: New");
		songWindow.add(selected);

		songWindow.add(createText(getX(), getY(9) + 3, "Song: ", 0xFFD8DAF6));
		songWindow.add(createText(getX(), getY(10) + 3, "Icon: ", 0xFFD8DAF6));

		var song:PsychUIInputText;
		song = new PsychUIInputText(getX("margin_first"), getY(9), 260, "", 14);
		song.onChange.add((old, cur, input) ->
		{
			curSong.song = cur;
		});
		songWindow.add(song);

		var icon:PsychUIInputText;
		icon = new PsychUIInputText(getX("margin_first"), getY(10), 260, "", 14);
		icon.onChange.add((old, cur, input) ->
		{
			curSong.icon = cur;
		});
		songWindow.add(icon);

		songs.onClick = (str) ->
		{
			if (str == "Add New")
				curSong = newSong();
			else
			{
				for (song in curWeek.songs)
				{
					if (song.song == str)
					{
						curSong = copySong(song);
						break;
					}
				}
			}

			editingSong = curSong.song;
			song.text = curSong.song;
			icon.text = curSong.icon;
			selected.text = 'Selected: ${curSong.song == "" ? "New" : curSong.song}';
		};

		var newButton = new DoidoTextButton("Save as New", "small");
		newButton.x = getX() + 10;
		newButton.y = getY(11);
		newButton.button.setColorTransform(0, 0.79, 0);
		newButton.label.color = 0xFFFFFFFF;
		songWindow.add(newButton);

		var saveButton = new DoidoTextButton("Save Current", "small");
		saveButton.x = getX("margin_right", saveButton.width) - 10;
		saveButton.y = getY(11);
		saveButton.button.setColorTransform(0.59, 0.78, 1);
		saveButton.label.color = 0xFFFFFFFF;
		songWindow.add(saveButton);

		var deleteButton = new DoidoTextButton("Delete Song", "small");
		deleteButton.x = getX("center", deleteButton.width);
		deleteButton.y = getY(12) + 4;
		deleteButton.button.setColorTransform(1, 0, 0);
		deleteButton.label.color = 0xFFFFFFFF;
		songWindow.add(deleteButton);

		function reloadAnims()
		{
			selected.text = 'Selected: ${curSong.song == "" ? "New" : curSong.song}';
			editingSong = curSong.song;
			song.text = curSong.song;
			icon.text = curSong.icon;

			songList = [for (song in curWeek.songs) song.song];
			songs.options = songList.concat(["Add New"]);
			songs.descs = [for (song in curWeek.songs) '(${song.icon == "" ? "none" : song.icon})'];
			storyMenu.reload();
		}

		function saveSong(update:Bool = true)
		{
			if (curSong.song.length > 0)
			{
				if (songList.contains(editingSong) && (update || songList.contains(curSong.song)))
				{
					if (songList.contains(curSong.song))
						editingSong = curSong.song;

					for (i in 0...curWeek.songs.length)
					{
						if (curWeek.songs[i].song == editingSong)
						{
							curWeek.songs[i] = copySong(curSong);
							editingSong = curSong.song;
							break;
						}
					}
				}
				else
				{
					var newSong = copySong(curSong);
					curWeek.songs.push(newSong);
				}

				reloadAnims();
			}
		}

		newButton.button.onUp.add(() -> saveSong(false));
		saveButton.button.onUp.add(() -> saveSong(true));

		deleteButton.button.onUp.add(() ->
		{
			if (songList.contains(editingSong))
			{
				for (song in curWeek.songs)
				{
					if (song.song == editingSong)
					{
						curWeek.songs.remove(song);
						break;
					}
				}
			}

			curSong = newSong();
			reloadAnims();
		});

		dataWindow.add(createText(getX(), getY(0) + 3, "Week File: ", 0xFFD8DAF6));
		dataWindow.add(createText(getX(), getY(1) + 3, "Week Name: ", 0xFFD8DAF6));
		dataWindow.add(createText(getX(), getY(2) + 3, "Alt. Name: ", 0xFFD8DAF6));
		// dataWindow.add(createText(getX(), getY(3) + 3, "Chars: ", 0xFFD8DAF6));
		dataWindow.add(createText(getX(), getY(3) + 3, "Diffs: ", 0xFFD8DAF6));
		dataWindow.add(createText(getX(), getY(4) + 3, "Story Diffs: ", 0xFFD8DAF6));
		dataWindow.add(createText(getX(), getY(5) + 3, "Story Color: ", 0xFFD8DAF6));

		var file:PsychUIInputText;
		file = new PsychUIInputText(getX("margin_second"), getY(0), 210, "", 14);
		file.onChange.add((old, cur, input) ->
		{
			curWeek.weekFile = cur;
			storyMenu.reload();
		});
		dataWindow.add(file);

		var name:PsychUIInputText;
		name = new PsychUIInputText(getX("margin_second"), getY(1), 210, "", 14);
		name.onChange.add((old, cur, input) ->
		{
			curWeek.weekName = cur;
			storyMenu.reload();
		});
		dataWindow.add(name);

		var freeplay:PsychUIInputText;
		freeplay = new PsychUIInputText(getX("margin_second"), getY(2), 210, "", 14);
		freeplay.onChange.add((old, cur, input) ->
		{
			curWeek.freeplayName = cur;
		});
		dataWindow.add(freeplay);

		var diffs:PsychUIInputText;
		diffs = new PsychUIInputText(getX("margin_second"), getY(3), 210, "", 14);
		diffs.onChange.add((old, cur, input) ->
		{
			curWeek.diffs = cur.split(",").map(s -> s.trim());
		});
		dataWindow.add(diffs);

		var storyDiffs:PsychUIInputText;
		storyDiffs = new PsychUIInputText(getX("margin_second"), getY(4), 210, "", 14);
		storyDiffs.onChange.add((old, cur, input) ->
		{
			curWeek.storyDiffs = cur.split(",").map(s -> s.trim());
			storyMenu.reload();
		});
		dataWindow.add(storyDiffs);

		var storyColor:PsychUIInputText;
		storyColor = new PsychUIInputText(getX("margin_second"), getY(5), 210, "", 14);
		storyColor.onChange.add((old, cur, input) ->
		{
			curWeek.storyColor = cur;
			storyMenu.reload();
		});
		dataWindow.add(storyColor);

		var radio = new DoidoRadio(["Always", "Story Only", "Freeplay Only"], 0, (cur) ->
		{
			curWeek.storyModeOnly = cur == 1;
			curWeek.freeplayOnly = cur == 2;
		});
		radio.x = getX();
		radio.y = getY(6);
		dataWindow.add(radio);

		var characterList = Assets.list("data/storychars/", true, JSON).concat(["None"]);
		var charWidth = 100;

		var right = new PsychUIDropDownMenu(getX("margin_right", charWidth), getY(8), characterList, (i, s) ->
		{
			curWeek.chars[2] = s == "None" ? "" : s;
			storyMenu.reload();
		}, charWidth, false);
		dataWindow.add(right);

		var center = new PsychUIDropDownMenu(getX("margin_right", charWidth), getY(7), characterList, (i, s) ->
		{
			curWeek.chars[1] = s == "None" ? "" : s;
			storyMenu.reload();
		}, charWidth, false);
		dataWindow.add(center);

		var left = new PsychUIDropDownMenu(getX("margin_right", charWidth), getY(6), characterList, (i, s) ->
		{
			curWeek.chars[0] = s == "None" ? "" : s;
			storyMenu.reload();
		}, charWidth, false);
		dataWindow.add(left);

		function reloadData()
		{
			file.text = curWeek.weekFile;
			name.text = curWeek.weekName;
			freeplay.text = curWeek.freeplayName;
			storyColor.text = curWeek.storyColor;
			diffs.text = curWeek.diffs.join(', ');
			storyDiffs.text = curWeek.storyDiffs.join(', ');
			radio.cur = curWeek.storyModeOnly ? 1 : (curWeek.freeplayOnly ? 2 : 0);
			left.selectedLabel = curWeek.chars[0] == "" ? "None" : curWeek.chars[0];
			center.selectedLabel = curWeek.chars[1] == "" ? "None" : curWeek.chars[1];
			right.selectedLabel = curWeek.chars[2] == "" ? "None" : curWeek.chars[2];
			reloadAnims();
		}

		fileWindow.addButton("New", () ->
		{
			curWeek = Week.defaultWeek();
			curSong = newSong();
			storyMenu.editingWeek = curWeek;
			reloadData();
			storyMenu.reload();
		});
		fileWindow.addSeparator();
		fileWindow.addButton("Save Week", () ->
		{
			var data:String = haxe.Json.stringify(curWeek, "\t");
			if (data != null && data.length > 0)
			{
				Assets.fileSave(data.trim(), '${curWeek.weekFile}.json');
			}
		});
		fileWindow.addSeparator();
		fileWindow.addButton("Exit", () -> close(), 0xFFFF0000);
		fileWindow.updateBg();

		reloadData();

		menu = new DoidoBox(8, 55, bgWidth, 22, 0, false, [fileWindow, songWindow, dataWindow], null);
		add(menu);
	}

	function newSong():WeekSong
		return {song: "", icon: ""};

	function copySong(song:WeekSong)
		return {song: song.song, icon: song.icon};

	function copyWeek(week:WeekData)
		return {
			songs: [for (song in week.songs) copySong(song)],
			weekFile: week.weekFile,
			weekName: week.weekName,
			freeplayName: week.freeplayName,
			chars: week.chars.copy(),
			diffs: week.diffs.copy(),
			storyDiffs: week.storyDiffs.copy(),
			storyColor: week.storyColor,
			freeplayOnly: week.freeplayOnly,
			storyModeOnly: week.storyModeOnly
		};

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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PsychUIInputText.focusOn == null)
		{
			if (Controls.justPressed(BACK))
				close();
		}
	}

	override function close()
	{
		storyMenu.editingWeek = null;
		storyMenu.reload();
		FlxG.mouse.visible = false;
		Main.setFpsPos(Main.fpsX, 55);
		super.close();
	}
}
