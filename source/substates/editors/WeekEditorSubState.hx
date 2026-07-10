package substates.editors;

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

		Main.setFpsPos(Main.fpsX, FlxG.height - Main.fpsHeight - 5);
		FlxG.mouse.visible = true;

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": 8 + 54;
				case "margin_first_small": 8 + 76;
				case "margin_second": 8 + 178;
				case "margin_right": 8 + bgWidth - width - 8;
				case "center": 8 + (bgWidth / 2) - (width / 2);
				default: 8 + 4;
			}
		}

		function getY(i:Int = 0)
			return 55 + 22 + 8 + 4 + (26 * i);

		var fileWindow:MenuWindow = new MenuWindow(8, 55 + 22 + 8, bgWidth, null);
		fileWindow.title = "File";
		// fileWindow.addButton("New");
		// fileWindow.addSeparator();
		// fileWindow.addButton("Open Week");
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

		var songWindow:DoidoWindow = new DoidoWindow(null);
		songWindow.title = "Songs";
		songWindow.bg.scale.set(bgWidth, 357 - 6);
		songWindow.bg.updateHitbox();
		songWindow.bg.setPosition(8, 55 + 22 + 8);

		var dataWindow:DoidoWindow = new DoidoWindow(null);
		dataWindow.title = "Data";
		dataWindow.bg.scale.set(bgWidth, 357 - 6);
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

		function reload()
		{
			selected.text = 'Selected: ${curSong.song == "" ? "New" : curSong.song}';
			editingSong = curSong.song;
			song.text = curSong.song;
			icon.text = curSong.icon;

			songList = [for (song in curWeek.songs) song.song];
			songs.options = songList.concat(["Add New"]);
			songs.descs = [for (song in curWeek.songs) '(${song.icon == "" ? "none" : song.icon})'];
		}

		reload();

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

				reload();
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
			reload();
		});

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
		FlxG.mouse.visible = false;
		Main.setFpsPos(Main.fpsX, 55);
		super.close();
	}
}
