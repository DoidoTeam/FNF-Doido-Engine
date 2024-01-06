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
		this.isPlayer 	= isPlayer;
		this.botplay 	= botplay;
		this.character 	= character;
		
		allNotes = new FlxTypedGroup<Note>();
		
		add(holdGroup 	= new FlxTypedGroup<Note>());
		add(strumGroup 	= new FlxTypedGroup<StrumNote>());
		add(splashGroup = new FlxTypedGroup<SplashNote>());
		add(noteGroup 	= new FlxTypedGroup<Note>());
		
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
			case "PLAYER ONLY": if(!isPlayer) return;
			case "OFF": return;
		}

		var pref:String = '-' + CoolUtil.getDirection(note.noteData) + '-' + note.strumlineID;

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
				splash.x = thisStrum.x/* + thisStrum.width / 2*/ - splash.width / 2;
				splash.y = thisStrum.y/* + thisStrum.height/ 2*/ - splash.height/ 2;

				splash.playAnim();
			}
		}
	}
	
	/*
	*	sets up the notes positions
	*	you can change it but i dont recommend it
	*/
	public function updateHitbox()
	{
		for(strum in strumGroup)
		{
			strum.y = (!downscroll ? 100 : FlxG.height - 100);
			
			strum.x = x;
			strum.x += CoolUtil.noteWidth() * strum.strumData;
			
			strum.x -= (CoolUtil.noteWidth() * (strumGroup.members.length - 1)) / 2;
			
			strum.initialPos.set(strum.x, strum.y);
		}
	}
}