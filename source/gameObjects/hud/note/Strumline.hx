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

	public var splashGroup:FlxTypedGroup<SplashNote>;

	// everybody gets one
	public var unspawnNotes:Array<Note> = [];

	public var x:Float = 0;
	public var downscroll:Bool = false;
	public var scrollSpeed:Float = 2.8;

	public var isPlayer:Bool = false;
	public var botplay:Bool = false;

	public var character:Character;

	public function new(x:Float, ?character:Character, ?downscroll:Bool, ?isPlayer = false, ?botplay = true, ?assetModifier:String = "base")
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

		splashGroup = new FlxTypedGroup<SplashNote>();

		add(strumGroup);
		add(holdGroup);
		add(noteGroup);
		add(splashGroup);

		for(i in 0...4)
		{
			var strum = new StrumNote();
			strum.reloadStrum(i, assetModifier);
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

	public function removeNote(note:Note)
	{
		allNotes.remove(note);
		if(note.isHold)
			holdGroup.remove(note);
		else
			noteGroup.remove(note);
	}

	public function addSplash(note:Note)
	{
		switch(SaveData.data.get("Note Splashes"))
		{
			case "PLAYER": if(!isPlayer) return;
			case "OFF": return;
		}

		var pref:String = '-' + NoteUtil.getDirection(note.noteData) + '-' + note.strumlineID;

		if(!SplashNote.existentModifiers.contains(note.assetModifier + pref)
		|| !SplashNote.existentTypes.contains(note.noteType + pref))
		{
			SplashNote.existentModifiers.push(note.assetModifier + pref);
			SplashNote.existentTypes.push(note.noteType + pref);

			var splash = new SplashNote();
			splash.reloadSplash(note);
			splash.visible = false;
			splashGroup.add(splash);
			
			//trace('added ${note.assetModifier + pref} ${note.noteType + pref}');
		}
	}

	public function playSplash(note:Note)
	{
		for(splash in splashGroup.members)
		{
			if(splash.assetModifier == note.assetModifier
			&& splash.noteType == note.noteType
			&& splash.noteData == note.noteData)
			{
				//trace("played");
				var thisStrum = strumGroup.members[splash.noteData];
				splash.x = thisStrum.x + thisStrum.width / 2 - splash.width / 2;
				splash.y = thisStrum.y + thisStrum.height/ 2 - splash.height/ 2;

				splash.playAnim();
			}
		}
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