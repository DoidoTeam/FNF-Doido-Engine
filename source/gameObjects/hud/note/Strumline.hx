package gameObjects.hud.note;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import gameObjects.Character;

class Strumline extends FlxGroup
{
	public var strumGroup:FlxTypedGroup<StrumNote>;
	public var noteGroup:FlxTypedGroup<Note>;
	public var holdGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var x:Float = 0;
	public var downscroll:Bool = false;
	public var scrollSpeed:Float = 2.8;

	public var isPlayer:Bool = false;
	public var botplay:Bool = false;

	public var character:Character;

	public function new(x:Float, ?character:Character, ?downscroll:Bool, ?isPlayer = false, ?botplay = true)
	{
		super();
		this.x = x;
		this.downscroll = downscroll;
		this.isPlayer = isPlayer;
		this.botplay = botplay;
		this.character = character;

		strumGroup = new FlxTypedGroup<StrumNote>();
		noteGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		add(strumGroup);
		add(holdGroup);
		add(noteGroup);

		for(i in 0...4)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i, "default");
			strumGroup.add(strum);
		}

		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function addNote(note:Note)
	{
		allNotes.add(note);
		if(note.isHold)
			holdGroup.add(note);
		else
			noteGroup.add(note);
	}

	public function updateHitbox()
	{
		for(strum in strumGroup.members)
		{
			strum.y = (!downscroll ? 25 : FlxG.height - strum.height - 25);

			strum.x = x;
			strum.x += NoteUtil.noteWidth() * strum.strumData;
		}

		var lastStrum = strumGroup.members[strumGroup.members.length - 1];
		var lineSize:Float = lastStrum.x + lastStrum.width - strumGroup.members[0].x;

		for(strum in strumGroup.members)
		{
			strum.x -= lineSize / 2;

			strum.initialPos.set(strum.x, strum.y);
		}
	}
}