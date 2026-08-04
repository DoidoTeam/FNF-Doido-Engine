package substates.menus;

#if MODS_FOLDER
import flixel.FlxSprite;
import doido.objects.Alphabet;
import doido.Mods;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;

typedef ModOption =
{
	var id:String;
	var name:String;
	var icon:String;
	var modVer:String;
	var apiVer:String;
	var enabled:Bool;
	var system:Bool;
	var invalid:Bool;
	var deps:Int;
}

class ModSubState extends MusicBeatSubState
{
	public var width:Float = 1000;
	public var height:Float = 600;
	public var realX:Float = 0;
	public var realY:Float = 0;
	public var padding:Int = 12;

	public final maxOptions:Int = 5;
	public final enabledColor:FlxColor = FlxColor.WHITE;
	public final disabledColor:FlxColor = FlxColor.WHITE.getDarkened(0.6);

	public var curSelected:Int = 0;
	public var curSys:Int = 0;

	public var mods:Array<ModOption> = [];
	public var systemOptions:Array<String> = ["reload list", #if (windows || android) "open folder" #end];

	public var bg:FlxSprite;
	public var displayGrp:FlxTypedGroup<ModDisplay>;

	public var debugSubState:DebugSubState;

	public function new(?debugSubState:DebugSubState, prevWidth:Float = 0, prevHeight:Float = 0)
	{
		super();
		this.debugSubState = debugSubState;
		FlxG.sound.play(Assets.sound("options/options-open"));

		bg = new FlxSprite().makeColor(width, height, 0xFF000000);
		bg.screenCenter();
		bg.alpha = 0.8;
		add(bg);

		realX = bg.x;
		realY = bg.y;
		bg.scale.x = prevWidth;
		bg.scale.y = prevHeight;
		bg.screenCenter();

		displayGrp = new FlxTypedGroup<ModDisplay>();
		add(displayGrp);

		reloadMods();
		positionBg(0);
	}

	var optionCount:Int = 0;

	public function reloadMods()
	{
		mods = [];
		for (mod in Mods.modList.mods)
		{
			var meta = Mods.getMeta(mod.name);
			mods.push({
				id: mod.name,
				name: meta.title,
				icon: mod.name,
				enabled: mod.enabled,
				modVer: meta.modVersion,
				apiVer: meta.apiVersion,
				system: false,
				invalid: Mods.isInvalid(mod.name),
				deps: Lambda.count(meta.dependencies) + Lambda.count(meta.optionalDependencies)
			});
		}

		mods.push({
			id: systemOptions[curSys],
			name: systemOptions[curSys],
			icon: "-",
			enabled: true,
			modVer: "0.0.0",
			apiVer: "0.0.0",
			system: true,
			invalid: false,
			deps: 0
		});

		displayGrp.killMembers();
		optionCount = 0;
		for (mod in mods)
		{
			var disp:ModDisplay = displayGrp.recycle(ModDisplay);
			disp.setMod(mod);
			if (!mod.system)
			{
				disp.x = realX + padding;
				disp.checkmark.x = realX + width - disp.checkmark.width - padding;
			}
			disp.ID = optionCount;
			displayGrp.add(disp);
			optionCount++;
		}

		changeSelection();
		positionOptions();
	}

	function positionBg(elapsed:Float)
	{
		bg.scale.set(FlxMath.lerp(bg.scale.x, width, elapsed * 8), FlxMath.lerp(bg.scale.y, height, elapsed * 8));
		bg.updateHitbox();
		bg.screenCenter();
	}

	public function positionOptions(?elapsed:Float)
	{
		var half:Int = Std.int(maxOptions / 2);
		var scrollAnchor:Int = 0;
		if (optionCount > maxOptions)
			scrollAnchor = Std.int(FlxMath.bound(curSelected - half, 0, optionCount - maxOptions));

		displayGrp.forEachAlive((disp) ->
		{
			var daPos:Int = (disp.ID - scrollAnchor);
			var yOffset:Float = (disp.fakeHeight + padding) * daPos;
			if (elapsed != null)
				disp.y = FlxMath.lerp(disp.y, realY + padding + yOffset, elapsed * 8);
			else
				disp.y = realY + padding + yOffset;
		});
	}

	var holdTimer:Float = 0.0;
	var holdMax:Float = 0.5;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Controls.justPressed(BACK))
		{
			FlxG.sound.play(Assets.sound("options/options-close"));
			if (Mods.reloadGame)
				Init.flagState();
			else
			{
				if (debugSubState != null)
					debugSubState.bg.scale.set(bg.width, bg.height);
				close();
			}
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

		if (Controls.justPressed(UI_LEFT) && isSystem)
			changeSys(-1);
		if (Controls.justPressed(UI_RIGHT) && isSystem)
			changeSys(1);

		if (Controls.justPressed(ACCEPT))
			toggleMod();

		positionBg(elapsed);
		positionOptions(elapsed);
	}

	public function toggleMod()
	{
		if (isSystem)
		{
			switch (curMod.id)
			{
				case "open folder":
					Assets.openFolder(Mods.MOD_ROOT);
				case "reload list":
					Mods.scan();
					reloadMods();
					curSelected = mods.length - 1;
					changeSelection();
					positionOptions();
					if (Mods.queuedErrors.length > 0)
						showErrors();
			}
		}
		else if (curMod.invalid)
			FlxG.sound.play(Assets.sound('cancel'));
		else
		{
			curMod.enabled = !curMod.enabled;
			Mods.setMod(curMod.id, curMod.enabled, true);
			displayGrp.forEachAlive((disp) ->
			{
				var modToggle = Mods.getMod(disp.mod.id);
				if (modToggle != disp.checked)
				{
					disp.mod.enabled = modToggle;
					disp.checked = modToggle;
					disp.checkmark.animation.play(Std.string(modToggle));
				}
			});
		}
	}

	function showErrors()
	{
		var text = "Found errors while loading Mods:\n";
		for (error in Mods.queuedErrors)
		{
			text += '- $error\n';
		}
		Main.alert(text, "Mod Load Error");
		Mods.queuedErrors = [];
	}

	public function changeSelection(?change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound("scroll"));

		if (FlxG.keys.pressed.CONTROL && change != 0 && !isSystem)
		{
			Mods.move(curSelected, change);
			reloadMods();
		}

		curSelected += change;
		curSelected = FlxMath.wrap(curSelected, 0, mods.length - 1);

		displayGrp.forEachAlive((disp) ->
		{
			disp.setColor(disp.ID == curSelected ? enabledColor : disabledColor);
			disp.hovering = disp.ID == curSelected;
		});
	}

	public function changeSys(?change:Int = 0)
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound("scroll"));

		curSys += change;
		curSys = FlxMath.wrap(curSys, 0, systemOptions.length - 1);

		// to-do: make this less shitty
		reloadMods();
	}

	override function draw()
	{
		function check(obj:FlxBasic)
		{
			if (obj == null)
				return;

			if (Std.isOfType(obj, FlxSpriteGroup))
			{
				var grp:FlxSpriteGroup = cast obj;
				grp.forEach((member) -> check(member));
			}
			else if (Std.isOfType(obj, FlxGroup))
			{
				var grp:FlxGroup = cast obj;
				grp.forEach((member) -> check(member));
			}
			else if (Std.isOfType(obj, FlxSprite))
				setClip(cast obj, bg);
		}

		check(displayGrp);

		// for (obj in objects)
		//	check(obj);

		// setClip(closeButton, bg);
		// setClip(titleText, bg);

		super.draw();
	}

	var curMod(get, never):ModOption;
	var isSystem(get, never):Bool;

	function get_curMod():ModOption
		return mods[curSelected];

	function get_isSystem():Bool
		return systemOptions.contains(curMod.id);

	// for some reason clipToSprite isnt working right
	function setClip(sprite:FlxSprite, bg:FlxSprite)
	{
		var newx:Float = bg.x - sprite.x;
		var newy:Float = bg.y - sprite.y;
		var newwidth:Float = (bg.x + bg.width - sprite.x) - newx;
		var newheight:Float = (bg.y + bg.height - sprite.y) - newy;
		sprite.clipRect = new FlxRect(newx / sprite.scale.x, newy / sprite.scale.y, newwidth / sprite.scale.x, newheight / sprite.scale.y);
	}
}

class ModDisplay extends FlxSpriteGroup
{
	public var icon:FlxSprite;
	public var checkmark:FlxSprite;
	public var name:Alphabet;
	public var ver:Alphabet;
	public var arrows:Array<FlxSprite> = [];

	public var nameText:String = "";
	public var verText:String = "";

	public var padding:Int = 12;
	public var fakeHeight:Float = 0;

	public var lastColor:FlxColor;
	public var hovering:Bool = false;
	public var mod:ModOption;
	public var checked:Bool = false;

	public function new(mod:ModOption)
	{
		super();
		hovering = false;

		icon = new FlxSprite();
		add(icon);

		name = new Alphabet(0, 0, "", true, LEFT);
		name.scale.set(0.8, 0.8);
		add(name);

		checkmark = new FlxSprite();
		checkmark.loadSparrow("menu/checkmark");
		checkmark.animation.addByPrefix("false", "false", 24, false);
		checkmark.animation.addByPrefix("true", "true", 24, false);
		checkmark.scale.set(0.9, 0.9);
		add(checkmark);

		ver = new Alphabet(0, 0, '<color value=#FFFFFF>$verText</color>', false, LEFT);
		ver.scale.set(0.3, 0.3);
		add(ver);

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
			arrow.y = name.y;
			add(arrow);
		}
	}

	public function setMod(mod:ModOption)
	{
		this.mod = mod;

		icon.loadGraphic(Mods.getIcon(mod.id));
		icon.setGraphicSize(150 * 0.7, 150 * 0.7);
		icon.updateHitbox();

		nameText = mod.name;
		name.text = nameText;
		name.updateHitbox();

		checked = mod.enabled;
		checkmark.animation.play(Std.string(mod.enabled), true, 99);
		checkmark.updateHitbox();

		if (mod.system)
			verText = 'Hold CTRL to reorder mods.';
		else if (mod.invalid)
			verText = '${Mods.getInvalid(mod.id)}';
		else
			verText = 'MOD: v${mod.modVer} | API: v${mod.apiVer} | Deps: ${mod.deps}';

		ver.text = '<color value=#FFFFFF>$verText</color>';
		ver.updateHitbox();

		name.x = icon.x + icon.width + padding;
		name.y = icon.y + (icon.height / 2) - (name.height / 2);
		checkmark.y = icon.y - 14;

		name.y -= (ver.height / 2);
		ver.x = name.x;
		ver.y = name.y + name.height;

		checkmark.visible = !mod.system && !mod.invalid;
		icon.visible = !mod.system;

		arrows[0].visible = mod.system;
		arrows[1].visible = mod.system;

		if (mod.system)
		{
			name.screenCenter(X);
			ver.screenCenter(X);

			arrows[0].y = name.y;
			arrows[1].y = name.y;
			arrows[0].x = name.x - arrows[0].width - padding;
			arrows[1].x = name.x + name.width + padding;
		}

		fakeHeight = icon.height;
	}

	public function setColor(newColor:FlxColor)
	{
		for (obj in [icon, checkmark].concat(arrows))
			obj.color = newColor;

		var white = newColor.toHexString(false, false);
		name.text = '<color value=#$white>$nameText</color>';
		ver.text = '<color value=#$white>$verText</color>';
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (hovering && mod.system)
		{
			for (arrow in arrows)
			{
				if (arrow.ID == 0)
					arrow.animation.play(Controls.pressed(UI_LEFT) ? "push" : "idle");
				else
					arrow.animation.play(Controls.pressed(UI_RIGHT) ? "push" : "idle");
			}
		}
	}
}
#end
