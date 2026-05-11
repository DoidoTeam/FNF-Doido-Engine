package substates.menus;

import doido.utils.NoteUtil;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import doido.objects.Alphabet;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import states.PlayState;

typedef OptionData =
{
	var name:String;
	var ?desc:Dynamic->String;
	var get:Void->Dynamic;
	var set:Dynamic->Void;

	// extra settings
	var ?display:Dynamic->String;
	var ?onChange:Void->Void;
	var ?canPlaySound:Void->Bool;

	// playstate stuff
	var ?updatePlayState:PlayState->Void;
	var ?playStateWarning:Bool;

	// SELECTORS
	var ?options:Array<String>;

	// SLIDERS
	var ?step:Float;
	var ?hold:Float;
	var ?limits:Array<Float>;
}

class OptionsSubState extends MusicBeatSubState
{
	public var playState:PlayState = null;

	public var optionOrder:Array<String> = ["Gameplay", "Preferences", "Graphics", #if TOUCH_CONTROLS "Mobile", #end];
	public var optionList:Map<String, Array<OptionData>> = [];

	public var bg:FlxSprite;
	public var bgWidth:Float = 0.0;
	public var bgHeight:Float = 0.0;

	public var alphabetGrp:FlxTypedGroup<OptionAlphabet>;
	public var attachGrp:FlxTypedGroup<Attachment>;

	public var descTxt:Alphabet;

	public var warningWidth:Float = 0.0;
	public var warningTxt:Alphabet;

	public final enabledColor:FlxColor = FlxColor.WHITE;
	public final disabledColor:FlxColor = FlxColor.WHITE.getDarkened(0.6);

	static var curCategoryString:String = "";
	static var curCategory:Int = 0;
	static var curSelection:Int = 0;

	public var curAttachType:AttachmentType = CATEGORY;

	public var holdTimerSlider:Float = 0.0;
	public var holdMaxSlider:Float = 0.4;
	public var holdTimerSliderSfx:Bool = false;

	public function new(?playState:PlayState)
	{
		super();
		this.playState = playState;

		#if MODS_FOLDER
		if (doido.Mods.modOptions.length > 0)
			optionOrder.push("Mods");
		#end

		optionList = [
			"Gameplay" => [
				{
					name: "Ghost Tapping",
					get: () -> Save.data.ghostTapping,
					set: (s:String) -> Save.data.ghostTapping = s,
					options: ["off", "idle", "on"],
					/*display: (s:String) -> {
						return switch(s) {
							case "idle": "IDLE";
							default: s.toUpperCase();
						}
					},*/
					desc: (s:String) ->
					{
						return switch (s.toLowerCase())
						{
							case "on": "You can press inputs freely.";
							case "idle": "If you press a wrong input while notes are near\nyour strumline, you will suffer a penalty.";
							default: "If you press a wrong input,\nyou will suffer a penalty.";
						}
					},
					playStateWarning: true,
				},
				{
					name: "Splash Notes",
					get: () -> Save.data.splashNotes,
					set: (s:String) -> Save.data.splashNotes = s,
					options: ["ALWAYS", "PLAYER ONLY", "OFF"],
					desc: (s:String) ->
					{
						if (s == "OFF")
							return "";

						if (s == "PLAYER ONLY")
							return "Spawns a splash on your strumline if\nyou press a note with a sick rating.";

						return "Spawns a splash on your strumline if you press a\nnote with a sick rating."
							+ " Every note your opponent hit\nwill spawn a splash on their strumline.";
					},
				},
				{
					name: "Downscroll",
					get: () -> Save.data.downscroll,
					set: (b:Bool) -> Save.data.downscroll = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Notes spawn at the top of the screen\nand fall down towards your strumline.";
						else
							return "Notes spawn at the bottom of the screen\nand fly up towards your strumline.";
					},
					updatePlayState: (playState) ->
					{
						playState.downscroll = Save.data.downscroll;
						#if TOUCH_CONTROLS
						if (Save.data.modernControls)
							playState.downscroll = true;
						#end
						playState.hudClass.updatePositions();

						for (strumline in playState.playField.strumlines)
						{
							if (!strumline.hasModchart)
							{
								strumline.downscroll = playState.downscroll;
								strumline.recalculateY();
								strumline.updateNotes(playState.curStepFloat);
							}
						}
					}
				},
				{
					name: "Centered Notes",
					get: () -> Save.data.middlescroll,
					set: (b:Bool) -> Save.data.middlescroll = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Your strumlines will be set to the center\nof the screen, and your opponents' will be hidden.";
						else
							return "Your strumlines will be set to one side\nof the screen, side by side with your opponents'.";
					},
					updatePlayState: (playState) ->
					{
						playState.middlescroll = Save.data.middlescroll;
						#if TOUCH_CONTROLS
						if (Save.data.modernControls)
							playState.middlescroll = true;
						#end
						playState.hudClass.updatePositions();

						var strumPos = playState.playField.getStrumlinePos(playState.middlescroll);
						var _i:Int = 0;
						for (strumline in playState.playField.strumlines)
						{
							if (!strumline.hasModchart)
							{
								strumline.x = (FlxG.width / 2) + strumPos[_i % strumPos.length];
								strumline.recalculateX();
								strumline.updateNotes(playState.curStepFloat);
							}
							_i++;
						}
					}
				},
				{
					name: "Note Quantization",
					get: () -> Save.data.quantNotes,
					set: (b:Bool) -> Save.data.quantNotes = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Notes are colored based on their timing.\nExample: (4th, 8th, 16th, 32th, etc...)";
						else
							return "Regular colored notes.";
					},
					playStateWarning: true
				},
				{
					name: "Unpause Slowdown",
					get: () -> Save.data.slowdownUnpause,
					set: (b:Bool) -> Save.data.slowdownUnpause = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Unpausing the game will make the song\nslowly catch up to regular speed.";
						else
							return "Unpausing the game will make the song\nresume instantaneously.";
					},
				},
				{
					name: "Change Controls",
					get: () -> null,
					set: (s:String) ->
					{
						openSubState(new ControlsSubState(this));
					},
				},
			],
			"Preferences" => [
				#if windows
				{
					name: "Dark Mode",
					get: () -> Save.data.darkMode,
					set: (b:Bool) -> Save.data.darkMode = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Some graphics, like the window title and the loading screen,\nwill have a dark theme applied.";
						else
							return "Some graphics, like the window title and the loading screen,\nwill have a light theme applied.";
					},
					onChange: () ->
					{
						doido.system.Windows.setDarkMode(Save.data.darkMode);
					}
				},
				#end
				#if desktop
				{
					name: "View FPS Counter",
					get: () -> Save.data.fpsCounter,
					set: (b:Bool) -> Save.data.fpsCounter = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Displays an overlay that includes perfomance info,\nsuch as the framerate and memory usage.";
						else
							return "If enabled, will display an overlay that includes perfomance info,\nsuch as the framerate and memory usage.";
					},
				},
				#end
				#if DISCORD_RPC
				{
					name: "Discord Rich Presence",
					get: () -> Save.data.discordRPC,
					set: (b:Bool) -> Save.data.discordRPC = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Displays the game status on your Discord profile.";
						else
							return "If enabled, will display the game status on your Discord profile.";
					},
				},
				#end
				{
					name: "Faster Transitions",
					get: () -> Save.data.fasterTransitions,
					set: (b:Bool) -> Save.data.fasterTransitions = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Transitions between states will play faster.";
						else
							return "Transitions between states will play slower.";
					},
				},
				{
					name: "Hitsound SFX",
					get: () -> Save.data.hitsound,
					set: (s:String) -> Save.data.hitsound = s,
					desc: (s:String) ->
					{
						return "What sound to play when hitting notes.";
					},
					options: NoteUtil.getHitsounds(),
					canPlaySound: () -> return Save.data.hitsound == "OFF",
					onChange: () -> NoteUtil.playHitsound()
				},
				{
					name: "Hitsound Volume",
					get: () -> Save.data.hitsoundVolume,
					set: (f:Float) -> Save.data.hitsoundVolume = f,
					desc: (f:Float) ->
					{
						if (Save.data.hitsound == "OFF")
							return "You must enable hitsounds\nfor this option to take effect!";
						else if (f <= 0.0)
							return "...really?";
						else
							return "";
					},
					step: 0.05,
					hold: 0.1,
					limits: [0.0, 1.0],
					display: (f:Float) -> return '${Math.floor(f * 100)}%',
					canPlaySound: () -> return (Save.data.hitsound == "OFF"),
					onChange: () ->
					{
						if (holdTimerSliderSfx)
							NoteUtil.playHitsound();
					}
				},
				{
					name: "Flashing Lights",
					get: () -> Save.data.flashingLights,
					set: (s:String) -> Save.data.flashingLights = s,
					desc: (s:String) ->
					{
						switch (s.toUpperCase())
						{
							case "ON": "All special effects are enabled.";
							case "REDUCED": "Some special effects will be softer.";
							default: "Some special effects will be disabled.";
						}
					},
					options: ["ON", "REDUCED", "OFF"]
				},
			],
			"Graphics" => [
				#if desktop
				{
					name: "FPS Cap",
					get: () -> Save.data.fps,
					set: (i:Int) -> Save.data.fps = i,
					limits: [30, 310],
					step: 1,
					hold: 2
				}, {
					name: "Window Size",
					get: () -> Save.data.windowSize,
					set: (s:String) -> Save.data.windowSize = s,
					options: Main.windowSizes,
					onChange: () -> Main.setWindowSize(Save.data.windowSize)
				}, {
					name: "GPU Caching",
					get: () -> Save.data.gpuCaching,
					set: (b:Bool) -> Save.data.gpuCaching = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Every graphic will be stored on your GPU's VRAM.\nDisable this if you have a shitty graphics card.";
						else
							return "Every graphic will be stored on your system RAM.\nEnable this if you have a decent graphics card.";
					},
				}, {
					name: "Shaders",
					get: () -> Save.data.shaders,
					set: (b:Bool) -> Save.data.shaders = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Fancy graphical effects will be displayed.\nDisable this if you experience crashes and other issues.";
						else
							return "Fancy graphical effects will not be displayed.\nKeep this off if you experience crashes and other issues.";
					},
					updatePlayState: (playState) ->
					{
						playState.shaders.enabled = Save.data.shaders;
					}
				},
				#end
				{
					name: "Antialiasing",
					get: () -> Save.data.antialiasing,
					set: (b:Bool) -> Save.data.antialiasing = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Graphics have a filter that makes lines softer.\nLooks prettier, but may impact performance.";
						else
							return "Graphics may look pixelated,\nbut the game will have better performance.";
					},
					playStateWarning: true
				},
				{
					name: "Low Quality",
					get: () -> Save.data.lowQuality,
					set: (b:Bool) -> Save.data.lowQuality = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Some background elements will be hidden\nin order to improve performance.";
						else
							return "";
					},
				},
			],
			#if MODS_FOLDER
			"Mods" => getModOptions(),
			#end
			#if TOUCH_CONTROLS
			"Mobile" => [
				{
					name: "Modern Controls",
					get: () -> Save.data.modernControls,
					set: (b:Bool) -> Save.data.modernControls = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Note layout inspired by base FNF,\nwhere the notes are centered and split.";
						else
							return "Note layout inspired by older FNF mobile engines,\nwith Hitboxes that cover the whole screen.";
					},
					playStateWarning: true
				},
				{
					name: "Invert Swipe X",
					get: () -> Save.data.invertX,
					set: (b:Bool) -> Save.data.invertX = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Inverts the direction of horizontal swipes.";
						else
							return "If enabled, will invert the direction of horizontal swipes.";
					},
				},
				{
					name: "Invert Swipe Y",
					get: () -> Save.data.invertY,
					set: (b:Bool) -> Save.data.invertY = b,
					desc: (b:Bool) ->
					{
						if (b)
							return "Inverts the direction of vertical swipes.";
						else
							return "If enabled, will invert the direction of vertical swipes.";
					},
				},
			],
			#end
		];
	}

	override function create()
	{
		super.create();
		persistentDraw = false;
		bg = new FlxSprite().makeColor(0, 0, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.9;
		add(bg);

		add(alphabetGrp = new FlxTypedGroup<OptionAlphabet>());
		add(attachGrp = new FlxTypedGroup<Attachment>());

		descTxt = new Alphabet(FlxG.width / 2, 0, '', false, CENTER);
		descTxt.scale.set(0.4, 0.4);
		descTxt.updateHitbox();
		add(descTxt);

		warningTxt = new Alphabet(FlxG.width / 2, 0, '<color value=#FF0000>RESTART THE SONG TO APPLY SOME SETTINGS</color>', false, CENTER);
		warningWidth = warningTxt.width;
		warningTxt.scale.set(0.5, 0.5);
		warningTxt.updateHitbox();
		warningTxt.visible = false;
		add(warningTxt);

		changeCategory();
	}

	#if MODS_FOLDER
	public function getModOptions():Array<OptionData>
	{
		var options:Array<OptionData> = [];
		for (option in doido.Mods.modOptions)
		{
			options.push({
				name: option.name,
				get: () -> Save.data.modData.get(option.name),
				set: (d:Dynamic) -> Save.data.modData.set(option.name, d),
				desc: (option.desc == null ? null : (a) -> return option.desc),
				playStateWarning: option.playStateWarning,
				options: option.options,
				step: option.step,
				hold: option.hold,
				limits: option.limits
			});
		}
		return options;
	}
	#end

	public var curSound:FlxSound;

	public function playSound(key:String)
	{
		if (curSound?.playing)
			curSound.stop();
		curSound = FlxG.sound.load(Assets.sound(key));
		curSound.play();
	}

	public function triggerWarning()
	{
		NoteUtil.playMissSound();
		warningTxt.visible = true;
	}

	public function changeCategory(?change:Int = 0)
	{
		descTxt.y = FlxG.height;
		warningTxt.y = FlxG.height;
		// if (change != 0) FlxG.sound.play(Assets.sound("scroll"));
		var sfx = FlxG.sound.load(Assets.sound("options/options-open"));
		sfx.pitch = FlxG.random.float(0.9, 1.1);
		sfx.play();

		curCategory = FlxMath.wrap(curCategory + change, 0, optionOrder.length - 1);
		curCategoryString = optionOrder[curCategory];

		alphabetGrp.forEachAlive((alphabet) ->
		{
			alphabet.kill();
		});
		attachGrp.forEachAlive((attach) ->
		{
			attach.kill();
		});

		var catTitle:OptionAlphabet = alphabetGrp.recycle(OptionAlphabet);
		catTitle.reloadStuff(40, curCategoryString, true);
		catTitle.hasAttachment = true;
		catTitle.y += bg.y;
		catTitle.ID = 0;
		if (!alphabetGrp.members.contains(catTitle))
			alphabetGrp.add(catTitle);

		var catAttach:Attachment = attachGrp.recycle(Attachment);
		catAttach.reloadStuff(catTitle, CATEGORY);
		if (attachGrp.members.contains(catAttach))
			attachGrp.add(catAttach);

		var _i:Int = 0;
		for (data in optionList.get(curCategoryString))
		{
			if (data.canPlaySound == null)
				data.canPlaySound = () -> true;

			var formatName:String = data.name;
			if (playState != null)
			{
				if (data.playStateWarning ?? false)
					formatName += '*';
			}

			var optionText:OptionAlphabet = alphabetGrp.recycle(OptionAlphabet);
			optionText.reloadStuff(130 + (60 * _i), formatName);
			optionText.y += bg.y;
			optionText.x = bg.x + 20;
			optionText.ID = _i + 1;

			optionText.hasAttachment = true;
			if (!alphabetGrp.members.contains(optionText))
				alphabetGrp.add(optionText);

			var dataGet:Dynamic = data.get();
			var attach:Attachment = attachGrp.recycle(Attachment);
			if (Std.isOfType(dataGet, Bool))
			{
				attach.reloadStuff(optionText, CHECKMARK);
				var check = attach.checkmark;
				check.animation.play(cast(dataGet, Bool) ? "true" : "false", true);
				check.animation.curAnim.curFrame = check.animation.curAnim.numFrames - 1;
			}
			else if (Std.isOfType(dataGet, String))
			{
				attach.reloadStuff(optionText, SELECTOR);
				attach.setSelectorValue(0, data);
			}
			else if (Std.isOfType(dataGet, Int) || Std.isOfType(dataGet, Float))
			{
				attach.reloadStuff(optionText, SLIDER);
				attach.setSliderValue(dataGet, data);
			}
			else
			{
				// optionText.x = bg.x + (bg.width - optionText.width) / 2;
				optionText.hasAttachment = false;
				attach.kill(); // no use for you sorry little attachment...
			}

			if (attachGrp.members.contains(attach))
				attachGrp.add(attach);

			_i++;
		}

		changeSelection();
		calcBGWidth();
		calcBGHeight();
	}

	public function changeSelection(?change:Int = 0)
	{
		holdTimerSlider = 0.0;
		if (change != 0)
			FlxG.sound.play(Assets.sound("scroll"));
		curSelection = FlxMath.wrap(curSelection + change, 0, optionList.get(curCategoryString).length);

		alphabetGrp.forEachAlive((alphabet) ->
		{
			alphabet.color = disabledColor;
			if (alphabet.ID == curSelection)
				alphabet.color = enabledColor;
		});

		curAttachType = null;
		attachGrp.forEachAlive((attach) ->
		{
			if (attach.parent.ID == curSelection)
				curAttachType = attach.type;
		});

		curOption = optionList.get(curCategoryString)[curSelection - 1];
		reloadDesc();
	}

	public function reloadDesc()
	{
		descTxt.visible = false;
		if (curOption?.desc != null)
		{
			var daText = curOption.desc(curOption.get());
			if (daText != "")
			{
				descTxt.visible = true;
				descTxt.text = '<color value=#FFFFFF>${daText}</color>';
			}
		}
	}

	public function calcBGWidth()
	{
		var alphabetWidth:Float = 0.0;
		alphabetGrp.forEachAlive((alphabet) ->
		{
			alphabetWidth = Math.max(alphabetWidth, alphabet.width);
		});
		var rawAttachWidth:Float = 0.0;
		var attachWidth:Float = 0.0;
		attachGrp.forEachAlive((attach) ->
		{
			if (attach.parent.width + attach.getWidth() > rawAttachWidth)
			{
				rawAttachWidth = attach.parent.width + attach.getWidth();
				attachWidth = attach.getWidth() - alphabetWidth + attach.parent.width;
			}
		});

		bgWidth = alphabetWidth + attachWidth + 20;
	}

	public function calcBGHeight()
	{
		var firstAlphabetY:Float = FlxG.height;
		var lastAlphabetY:Float = 0.0;
		alphabetGrp.forEachAlive((alphabet) ->
		{
			firstAlphabetY = Math.min(firstAlphabetY, alphabet.y);
			lastAlphabetY = Math.max(lastAlphabetY, alphabet.y + alphabet.height);
		});
		bgHeight = lastAlphabetY - firstAlphabetY;
	}

	public function saveOptions()
	{
		Save.save();
		reloadDesc();
		if (curOption.onChange != null)
			curOption.onChange();
		if (playState == null)
			return;
		if (curOption.updatePlayState != null)
			curOption.updatePlayState(playState);
		if (curOption.playStateWarning ?? false)
			triggerWarning();
	}

	override function draw()
	{
		if (warningTxt.visible)
			for (char in warningTxt.members)
			{
				char.clipToSprite([bg]);
			}

		if (descTxt.visible)
			for (char in descTxt.members)
			{
				char.clipToSprite([bg]);
			}

		alphabetGrp.forEach((alphabet) ->
		{
			for (char in alphabet.members)
			{
				char.clipToSprite([bg]);
			}
		});
		attachGrp.forEach((attach) ->
		{
			for (item in attach.members)
			{
				if (Std.isOfType(item, SliderBar))
				{
					for (sprite in cast(item, SliderBar))
						sprite.clipToSprite([bg]);
				}
				else if (Std.isOfType(item, Alphabet))
				{
					for (char in cast(item, Alphabet))
						char.clipToSprite([bg]);
				}
				else
					item.clipToSprite([bg]);
			}
		});

		attachGrp.forEachAlive((attach) ->
		{
			attach.y = attach.parent.y;
			attach.color = attach.parent.color;

			for (arrow in attach.arrows)
			{
				if (arrow.alive)
				{
					if (attach.parent.ID != curSelection)
						arrow.animation.play("idle");
					else
					{
						if (arrow.ID == 0)
							arrow.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
						else
							arrow.animation.play(Controls.pressed(UI_RIGHT) ? "push" : "idle");
					}
				}
			}

			switch (attach.type)
			{
				case CATEGORY:
					for (arrow in attach.arrows)
					{
						arrow.y = attach.parent.y;
						arrow.x = attach.parent.x - (attach.parent.width / 2);
						if (arrow.ID == 0)
							arrow.x -= arrow.width + 15;
						else
							arrow.x += attach.parent.width + 15;
					}
				case SELECTOR:
					attach.arrows[1].x = attach.parent.x + bgWidth - attach.arrows[1].width;
					attach.selectorTxt.x = attach.arrows[1].x - attach.selectorTxt.width - 10;
					attach.arrows[0].x = attach.selectorTxt.x - attach.arrows[0].width - 10;

					for (arrow in attach.arrows)
						arrow.y = attach.parent.y - 6;

				case SLIDER:
					attach.arrows[1].x = attach.parent.x + bgWidth - attach.arrows[1].width;
					attach.sliderBar.x = attach.arrows[1].x - attach.sliderBar.border.width - 20;
					attach.arrows[0].x = attach.sliderBar.x - attach.arrows[0].width - 20;

					attach.sliderBar.y = attach.parent.y + (attach.parent.height - attach.sliderBar.border.height) / 2;
					attach.sliderBall.setPosition(attach.sliderBar.x
						+ (attach.sliderBar.border.width * (100 - attach.sliderBar.percent) / 100)
						- (attach.sliderBall.width / 2),
						attach.sliderBar.y
						+ (attach.sliderBar.border.height - attach.sliderBall.height) / 2);
					attach.sliderBar.updatePos();

					attach.selectorTxt.x = attach.sliderBar.x + (attach.sliderBar.border.width - attach.selectorTxt.width) / 2;

					for (arrow in attach.arrows)
					{
						arrow.y = attach.parent.y - 6;
						arrow.color = attach.parent.color;
					}
					if (attach.sliderBar.percent <= 0.0)
						attach.arrows[1].color = disabledColor;
					if (attach.sliderBar.percent >= 100) attach.arrows[0].color = disabledColor;

				case CHECKMARK:
					attach.y -= 25;
					var check = attach.checkmark;
					check.x = attach.parent.x + bgWidth - attach.getWidth();
			}
		});
		super.draw();
	}

	public var curOption:OptionData;

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Controls.justPressed(BACK))
		{
			FlxG.sound.play(Assets.sound("options/options-close"));
			close();
		}

		var change:Int = (Controls.pressed(UI_DOWN) ? 1 : 0) - (Controls.pressed(UI_UP) ? 1 : 0);
		if (change != 0)
			holdTimer += elapsed;
		else
			holdTimer = 0.0;
		if (Controls.justPressed(UI_UP) || Controls.justPressed(UI_DOWN) || holdTimer >= holdMax)
		{
			changeSelection(change);
			if (holdTimer >= holdMax)
				holdTimer = holdMax - 0.12;
		}

		var formatBGWidth:Float = bgWidth + 140;
		var formatBGHeight:Float = bgHeight + 80;
		if (warningTxt.visible)
			formatBGHeight += warningTxt.height;
		if (descTxt.visible)
		{
			formatBGHeight += descTxt.height + 20;
			if (descTxt.width > bgWidth)
				formatBGWidth = descTxt.width + 140;
		}

		bg.scale.set(FlxMath.lerp(bg.scale.x, formatBGWidth, elapsed * 8), FlxMath.lerp(bg.scale.y, formatBGHeight, elapsed * 8));
		bg.updateHitbox();
		bg.screenCenter();

		var lastAlphabet:Float = 0.0;
		alphabetGrp.forEachAlive((alphabet) ->
		{
			alphabet.y = FlxMath.lerp(alphabet.y, bg.y + alphabet.startY, elapsed * 8);
			if (alphabet.y + alphabet.height > lastAlphabet)
				lastAlphabet = alphabet.y + alphabet.height;
			if (alphabet.ID == 0)
				return;
			alphabet.x = FlxMath.lerp(alphabet.x, bg.x + (alphabet.hasAttachment ? (bg.width - bgWidth) : (bg.width - alphabet.width)) / 2, elapsed * 8);
		});

		descTxt.y = FlxMath.lerp(descTxt.y, lastAlphabet + 20, elapsed * 8);
		warningTxt.scale.x = FlxMath.lerp(warningTxt.scale.x, ((bg.width - 40) / warningWidth), elapsed * 8);
		warningTxt.updateHitbox();
		warningTxt.y = FlxMath.lerp(warningTxt.y, bg.y + bg.height - warningTxt.height - 20, elapsed * 8);

		if (curAttachType != null)
		{
			switch (curAttachType)
			{
				case CATEGORY:
					if (Controls.justPressed(UI_LEFT))
						changeCategory(-1);
					else if (Controls.justPressed(UI_RIGHT))
						changeCategory(1);

				case SELECTOR:
					attachGrp.forEachAlive((attach) ->
					{
						if (attach.parent.ID != curSelection)
							return;

						var change:Int = (Controls.pressed(UI_RIGHT) ? 1 : 0) - (Controls.pressed(UI_LEFT) ? 1 : 0);

						if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT))
						{
							attach.setSelectorValue(change, curOption);
							if (curOption.canPlaySound())
								playSound('options/selector-change');

							calcBGWidth();
							saveOptions();
						}
					});

				case SLIDER:
					attachGrp.forEachAlive((attach) ->
					{
						if (attach.parent.ID != curSelection)
							return;

						var change:Int = (Controls.pressed(UI_RIGHT) ? 1 : 0) - (Controls.pressed(UI_LEFT) ? 1 : 0);
						if (change != 0)
							holdTimerSlider += elapsed;
						else
							holdTimerSlider = 0.0;

						if (Controls.justPressed(UI_LEFT) || Controls.justPressed(UI_RIGHT) || holdTimerSlider >= holdMaxSlider)
						{
							var prevPercent = attach.sliderBar.percent;

							var step:Float = curOption.step ?? 1.0;
							if (holdTimerSlider >= holdMaxSlider && curOption.hold != null)
								step = curOption.hold;
							var newValue:Float = curOption.get() + change * step;
							attach.setSliderValue(newValue, curOption);

							if (holdTimerSlider < holdMaxSlider)
								holdTimerSliderSfx = true;
							else
							{
								if (prevPercent == attach.sliderBar.percent)
									holdTimerSliderSfx = false;
								else
									holdTimerSliderSfx = !holdTimerSliderSfx;
							}

							if (holdTimerSliderSfx && curOption.canPlaySound())
								playSound('options/slider-${change < 0 ? "down" : "up"}');

							if (holdTimerSlider >= holdMaxSlider)
								holdTimerSlider = holdMaxSlider - 0.02; // 0.02

							saveOptions();
						}
					});

				case CHECKMARK:
					if (Controls.justPressed(ACCEPT))
					{
						curOption.set(!curOption.get());

						attachGrp.forEachAlive((attach) ->
						{
							if (attach.parent.ID != curSelection)
								return;
							var check = attach.checkmark;
							check.animation.play('${curOption.get()}', true);
						});

						if (curOption.canPlaySound())
							playSound('options/checkmark-${curOption.get()}');

						saveOptions();
					}
			}
		}
		else
		{
			if (Controls.justPressed(ACCEPT))
			{
				if (curOption.set != null)
					curOption.set("clicked!");
			}
		}
	}
}

class OptionAlphabet extends Alphabet
{
	public var startY:Float = 0.0;
	public var isCategory:Bool = false;
	public var hasAttachment:Bool = false;

	public function new()
	{
		super(0, 0, text, true);
	}

	public function reloadStuff(startY:Float, text:String, isCategory:Bool = false)
	{
		this.y = this.startY = startY;
		this.text = text;
		this.isCategory = isCategory;
		if (isCategory)
		{
			align = CENTER;
			x = FlxG.width / 2;
			scale.set(0.8, 0.8);
		}
		else
		{
			align = LEFT;
			scale.set(0.65, 0.65);
		}
		updateHitbox();
	}

	override function draw()
	{
		forEachAlive(function(char:AlphaCharacter)
		{
			char.color = color;
		});
		super.draw();
	}
}

enum AttachmentType
{
	CATEGORY;
	CHECKMARK;
	SELECTOR;
	SLIDER;
}

class Attachment extends FlxSpriteGroup
{
	public var startY:Float = 0.0;
	public var parent:OptionAlphabet;

	public var type:AttachmentType = CHECKMARK;

	public var checkmark:FlxSprite;
	public var arrows:Array<FlxSprite> = [];
	public var selectorTxt:Alphabet;
	public var sliderBar:SliderBar;
	public var sliderBall:FlxSprite;

	public function new()
	{
		super();
		checkmark = new FlxSprite();
		checkmark.loadSparrow("menu/checkmark");
		checkmark.animation.addByPrefix("false", "false", 24, false);
		checkmark.animation.addByPrefix("true", "true", 24, false);
		checkmark.animation.play("true");
		checkmark.scale.set(0.7, 0.7);
		checkmark.updateHitbox();
		add(checkmark);

		for (i in 0...2)
		{
			var dir:String = (i == 0 ? "left" : "right");
			var arrow = new FlxSprite();
			arrow.loadSparrow("menu/menuArrows");
			arrow.animation.addByPrefix('idle', 'arrow $dir', 24, false);
			arrow.animation.addByPrefix('push', 'arrow push $dir', 24, false);
			arrow.animation.play("idle");
			arrow.scale.set(0.7, 0.7);
			arrow.updateHitbox();
			arrows.push(arrow);
			arrow.ID = i;
			add(arrow);
		}

		sliderBar = new SliderBar();
		add(sliderBar);

		sliderBall = new FlxSprite().loadImage("menu/sliderBall");
		add(sliderBall);

		selectorTxt = new Alphabet(x, y, "", true, LEFT);
		selectorTxt.scale.set(0.65, 0.65);
		selectorTxt.updateHitbox();
		add(selectorTxt);
	}

	public function getWidth():Float
	{
		return switch (type)
		{
			case SELECTOR: arrows[1].width + selectorTxt.width + arrows[0].width + 20;
			case SLIDER: arrows[1].width + sliderBar.border.width + arrows[0].width + 40;
			case CHECKMARK: checkmark.width - 12;
			default: 0.0;
		}
	}

	public function setSliderValue(newValue:Float, data:OptionData)
	{
		if (type != SLIDER)
			return;

		var step:Float = data.step ?? 1.0;

		var limits = data.limits;
		if (limits == null)
			limits = [0, 100];
		if (newValue < Math.min(limits[0], limits[1]))
			newValue = Math.min(limits[0], limits[1]);
		if (newValue > Math.max(limits[1], limits[0]))
			newValue = Math.max(limits[1], limits[0]);

		if (Std.isOfType(data.get(), Float))
			data.set(Math.round(newValue / step) * step);
		else
			data.set(Math.floor(newValue));

		selectorTxt.text = (data.display == null) ? '$newValue' : data.display(newValue);
		sliderBar.percent = FlxMath.remapToRange(newValue, limits[0], limits[1], 100, 0);
	}

	public function setSelectorValue(change:Int, data:OptionData)
	{
		if (type != SELECTOR)
			return;

		if (change != 0)
		{
			var curSel = data.options.indexOf(data.get());
			curSel += change;
			data.set(data.options[FlxMath.wrap(curSel, 0, data.options.length - 1)]);
		}

		selectorTxt.text = (data.display == null) ? data.get() : data.display(data.get());
	}

	public function reloadStuff(parent:OptionAlphabet, type:AttachmentType)
	{
		this.parent = parent;
		this.type = type;

		checkmark.kill();
		for (arrow in arrows)
			arrow.kill();
		selectorTxt.kill();
		sliderBar.kill();
		sliderBall.kill();
		switch (type)
		{
			case CATEGORY | SELECTOR | SLIDER:
				for (arrow in arrows)
				{
					arrow.revive();
					switch (type)
					{
						case CATEGORY: arrow.scale.set(0.7, 0.7);
						default: arrow.scale.set(0.6, 0.6);
					}
					arrow.updateHitbox();
				}
				if (type != CATEGORY)
				{
					selectorTxt.revive();
					if (type == SLIDER)
					{
						sliderBar.revive();
						sliderBall.revive();
					}
				}

			case CHECKMARK:
				checkmark.revive();
			default:
		}
	}

	override function draw()
	{
		selectorTxt?.forEachAlive(function(char:AlphaCharacter)
		{
			char.color = color;
		});
		super.draw();
	}
}

class SliderBar extends FlxSpriteGroup
{
	public var border:FlxSprite;

	public var sideL:FlxSprite;
	public var sideR:FlxSprite;
	public var percent(default, set):Float = 0;

	public function set_percent(v:Float)
	{
		percent = v;
		if (sideL != null && sideR != null)
		{
			sideL.scale.x = 1.0 - (percent / 100);
			sideR.scale.x = (percent / 100);
			sideL.updateHitbox();
			sideR.updateHitbox();
			updatePos();
		}
		return percent;
	}

	public function new()
	{
		super(x, y);
		percent = 50;

		sideR = new FlxSprite();
		sideR.loadGraphic(Assets.image("menu/sliderBarR"));
		sideL = new FlxSprite();
		sideL.loadGraphic(Assets.image("menu/sliderBarL"));

		add(sideR);
		add(sideL);

		border = new FlxSprite().loadGraphic(Assets.image("menu/sliderBar-border"));
		add(border);
	}

	public function updatePos()
	{
		for (item in members)
			item.setPosition(x, y);
		sideR.x += border.width - sideR.width;
	}

	override function draw()
	{
		for (item in members)
			item.color = color;
		super.draw();
	}
}
