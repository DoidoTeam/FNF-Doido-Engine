package states.editors;

import doido.objects.DoidoSprite.Animation;
import doido.objects.ui.window.DoidoWindow;
import doido.objects.DoidoCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.math.FlxMath;
import objects.Character;
import objects.Character;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxBitmapText;
import doido.objects.ui.DoidoSlider;
import doido.objects.ui.*;
import doido.objects.ui.window.DoidoChooser;
import flixel.util.FlxColor;
import doido.objects.ui.buttons.DoidoTextButton;
import doido.objects.ui.DoidoCheckmark;
import haxe.Json;
import doido.objects.DoidoSprite;
import doido.objects.ui.window.*;
import doido.objects.ui.buttons.*;

class CharacterEditor extends MusicBeatState
{
	var curChar:String = "";
	var isPlayer:Bool = false;

	public function new(curChar:String, isPlayer:Bool = false)
	{
		this.curChar = curChar;
		this.isPlayer = isPlayer;
		super();
	}

	var camChar:DoidoCamera;
	var camHUD:DoidoCamera;

	public var char:Character;
	public var ghost:Ghost;

	var middlePoint:FlxSprite;

	var defaultAnim:Animation = {
		name: "",
		prefix: "",
		framerate: 24,
		loop: false,
		offset: {x: 0, y: 0},
		indices: [],
		flipX: false,
		flipY: false
	};
	var animEditing:Animation;
	var curEditing:String = "";

	var camFollow:FlxObject;
	var animWindow:AnimWindow;

	public var menuMain:DoidoBox;

	override function create()
	{
		super.create();
		DiscordIO.changePresence("In the Character Editor");
		FlxG.mouse.visible = true;

		camChar = new DoidoCamera(false, true);
		camHUD = new DoidoCamera(true, false);

		animEditing = DoidoSprite.copyAnim(defaultAnim);

		camFollow = new FlxObject();
		camChar.follow(camFollow, LOCKON, 1);
		camFollow.setPosition(FlxG.width / 2 + FlxG.width / 4, FlxG.height / 2 - FlxG.width / 8);
		camChar.zoom = camZoom;

		var grid = FlxGridOverlay.create(64, 64, FlxG.width * 3, FlxG.height * 3, true, 0xFFEBEFFE, 0xFFD7D9F6);
		grid.screenCenter();
		add(grid);

		middlePoint = new FlxSprite().loadImage('editors/point');
		middlePoint.setPosition((FlxG.width - middlePoint.width) / 2, FlxG.height - 200 - (middlePoint.height / 2));
		middlePoint.color = 0xFFFF0000;

		char = new Character(curChar, isPlayer);
		ghost = new Ghost(char);

		add(ghost);
		add(char);

		add(middlePoint);

		for (char in [ghost, char])
		{
			char.debugMode = true;
			updatePos(char);
		}

		for (anim in char.animList)
		{
			if (!char.animOffsets.exists(anim))
				char.addOffset(anim, {x: 0, y: 0});
		}

		animWindow = new AnimWindow(this);
		animWindow.cameras = [camHUD];
		add(animWindow);

		addMain();
	}

	function createBasic(title:String = "test"):DoidoWindow
	{
		var newWindow:DoidoWindow = new DoidoWindow(null);
		newWindow.title = title;
		newWindow.bg.scale.set(458, 501);
		newWindow.bg.updateHitbox();
		newWindow.bg.setPosition(FlxG.width - newWindow.bg.width - 18, 57);
		newWindow.cameras = [camHUD];
		return newWindow;
	}

	function createCharacter():DoidoWindow
	{
		var tab = createBasic("Character");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 70;
				case "margin_first_search": tab.bg.x + 80;
				case "margin_second": tab.bg.x + 229 + 8;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				case "center_left": tab.bg.x + (tab.bg.width / 4) - (width / 2);
				case "center_right": tab.bg.x + ((tab.bg.width / 4) * 3) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		tab.add(createText(getX(), getY(0) + 3, "Sprite:", 0xFFD8DAF6));
		var textWidth:Int = 200;
		var sprite:PsychUIInputText;
		sprite = new PsychUIInputText(getX("margin_first"), getY(0), textWidth, char.data.spritesheet, 14);
		sprite.onChange.add((old, cur, input) ->
		{
			char.data.spritesheet = cur;
		});
		sprite.cameras = [camHUD];
		tab.add(sprite);

		var player:DoidoCheckmark = new DoidoCheckmark(char.isPlayer);
		player.x = getX("margin_right", player.width);
		player.y = getY(1) - 2;
		player.onUp.add(() ->
		{
			char.isPlayer = player.value;
			flipCheck(char);
		});
		tab.add(player);
		tab.add(createText(player.x - 60, getY(1) + 2, "Player:", 0xFFD8DAF6));

		var ghostFlip:DoidoCheckmark = new DoidoCheckmark(ghost.isPlayer);
		ghostFlip.x = player.x - 60 - ghostFlip.width - 5;
		ghostFlip.y = getY(1) - 2;
		ghostFlip.onUp.add(() ->
		{
			ghost.isPlayer = ghostFlip.value;
			flipCheck(ghost);
		});
		tab.add(ghostFlip);
		tab.add(createText(ghostFlip.x - 55, getY(1) + 2, "Ghost:", 0xFFD8DAF6));

		var reload = new DoidoTextButton("Reload Sprite", "small");
		reload.x = getX("margin_right", reload.width);
		reload.y = getY(0) - 3;
		reload.button.setColorTransform(1, 0, 0);
		reload.label.color = 0xFFFFFFFF;
		reload.button.onUp.add(() ->
		{
			char.clearAnims();
			char.loadCharacter(true);
			ghost.syncGhost();
			updatePos(char);
			updatePos(ghost);
		});
		tab.add(reload);

		var pixel:DoidoCheckmark = new DoidoCheckmark(char.data.pixel);
		pixel.x = getX("margin_right", pixel.width);
		pixel.y = getY(3) - 2;
		pixel.onUp.add(() ->
		{
			char.data.pixel = pixel.value;
			char.antialiasing = ((char.data.pixel) ? false : flixel.FlxSprite.defaultAntialiasing);
			flipCheck(char);
		});
		tab.add(pixel);
		tab.add(createText(pixel.x - 45, getY(3) + 2, "Pixel:", 0xFFD8DAF6));

		// getX() + 120
		var spriteType:PsychUIDropDownMenu;
		spriteType = new PsychUIDropDownMenu(getX("margin_right", 130), getY(2), ["SPARROW", "ATLAS", "PACKER", "ASEPRITE"], (i, s) ->
		{
			char.data.spriteType = s;
		}, 130, false);
		spriteType.selectedLabel = char.data.spriteType;
		spriteType.cameras = [camHUD];
		tab.add(spriteType);

		tab.add(createText(getX(), getY(2) + 3, "Idles:", 0xFFD8DAF6));
		var idles:PsychUIInputText;
		idles = new PsychUIInputText(getX("margin_first"), getY(2), textWidth, char.idleAnims.join(", "), 14);
		idles.onChange.add((old, cur, input) ->
		{
			char.idleAnims = cur.split(",").map(s -> s.trim());
			char.data.idleAnims = char.idleAnims;
			trace(char.data.idleAnims);
		});
		idles.cameras = [camHUD];
		tab.add(idles);

		tab.add(createText(getX(), getY(3) + 3, "Scale:", 0xFFD8DAF6));
		var scaleX = new PsychUINumericStepper(getX("margin_first"), getY(3), 0.1, char.data.scale.x, 0.1, 10, 2);
		scaleX.onValueChange = () ->
		{
			char.data.scale.x = scaleX.value;
			char.scale.set(char.data.scale.x, char.data.scale.y);
			updatePos(char);
			ghost.syncGhost();
			updatePos(ghost);
		}
		scaleX.cameras = [camHUD];
		tab.add(scaleX);

		var scaleY = new PsychUINumericStepper(getX("margin_first") + 105, getY(3), 0.1, char.data.scale.y, 0.1, 10, 2);
		scaleY.onValueChange = () ->
		{
			char.data.scale.y = scaleY.value;
			char.scale.set(char.data.scale.x, char.data.scale.y);
			updatePos(char);
			ghost.syncGhost();
			updatePos(ghost);
		}
		scaleY.cameras = [camHUD];
		tab.add(scaleY);

		var characterList = Assets.list("data/characters/", true, JSON).concat(["face"]);

		var ghosts:PsychUIDropDownMenu;
		ghosts = new PsychUIDropDownMenu(getX() + 120, getY(1), characterList, (i, s) ->
		{
			ghost.curChar = s;
			ghost.syncGhost();
			updatePos(ghost);

			setDescs();
			updateAnim(false);
		}, 100, false);
		ghosts.selectedLabel = char.curChar;
		ghosts.cameras = [camHUD];
		tab.add(ghosts);

		var characters:PsychUIDropDownMenu;
		characters = new PsychUIDropDownMenu(getX(), getY(1), characterList, (i, s) ->
		{
			if (ghost.curChar == char.curChar)
			{
				ghost.curChar = s;
				ghosts.selectedLabel = s;
			}

			char.curChar = s;
			char.clearAnims();
			char.loadCharacter(false);
			updatePos(char);
			ghost.syncGhost();
			updatePos(ghost);

			sprite.text = char.data.spritesheet;
			spriteType.selectedLabel = char.data.spriteType ?? "SPARROW";
			anims.options = char.animList.concat(["Add New"]);
			updateAnim(false);
		}, 100, false);
		characters.selectedLabel = char.curChar;
		characters.cameras = [camHUD];
		tab.add(characters);

		/*
			var atlasType:PsychUIDropDownMenu;
			atlasType = new PsychUIDropDownMenu(getX(), getY(1), ["SYMBOL", "FRAMELABEL"], (i, s) ->
			{
				char.data.atlasType = s;
			}, 100, false);
			atlasType.selectedLabel = char.data.atlasType;
			atlasType.cameras = [camHUD];
			tab.add(atlasType);
		 */

		return tab;
	}

	function flipCheck(char:Character)
	{
		char.flipX = char.data.flipX;
		if (char.isPlayer)
			char.flipX = !char.flipX;
	}

	var spacingH:Float = 30;

	var anims:ChooserWindow;

	function setDescs()
	{
		var offsets:Array<String> = [];
		for (anim in char.animList)
		{
			var animoff = char.animOffsets.get(anim);
			offsets.push('(${animoff.x}, ${animoff.y})');
		}

		anims.descs = offsets;
	}

	function createAnimations():DoidoWindow
	{
		var tab = createBasic("Animations");

		function getX(place:String = "margin_left", width:Float = 0)
		{
			return switch (place)
			{
				case "margin_first": tab.bg.x + 80;
				case "margin_first_search": tab.bg.x + 80;
				case "margin_second": tab.bg.x + 229 + 8;
				case "margin_right": tab.bg.x + tab.bg.width - width - 8;
				case "center": tab.bg.x + (tab.bg.width / 2) - (width / 2);
				case "center_left": tab.bg.x + (tab.bg.width / 4) - (width / 2);
				case "center_right": tab.bg.x + ((tab.bg.width / 4) * 3) - (width / 2);
				default: tab.bg.x + 8;
			}
		}

		function getY(i:Int = 0)
			return tab.bg.y + 8 + (spacingH * i);

		var bottomY = 15;

		var balls:FlxSprite = new FlxSprite().loadImage("editors/charting/balls");
		balls.setPosition(getX("center", balls.width), getY(bottomY - 5) + 12);
		tab.add(balls);

		var editText = createText(getX(), getY(bottomY - 4) + 3, 'Currently Editing: ${curEditing == "" ? "New" : curEditing}', 0xFFFFFFFF);
		tab.add(editText);

		tab.add(createText(getX(), getY(bottomY - 3) + 3, "Name:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(bottomY - 2) + 3, "Prefix:", 0xFFD8DAF6));
		tab.add(createText(getX(), getY(bottomY - 1) + 3, "Indices:", 0xFFD8DAF6));

		var textWidth:Int = 200;
		var name:PsychUIInputText;
		name = new PsychUIInputText(getX("margin_first"), getY(bottomY - 3), textWidth, animEditing.name, 14);
		name.onChange.add((old, cur, input) ->
		{
			animEditing.name = cur;
		});
		name.cameras = [camHUD];
		tab.add(name);

		var prefix:PsychUIInputText;
		prefix = new PsychUIInputText(getX("margin_first"), getY(bottomY - 2), textWidth, animEditing.prefix, 14);
		prefix.onChange.add((old, cur, input) ->
		{
			animEditing.prefix = cur;
		});
		prefix.cameras = [camHUD];
		tab.add(prefix);

		var indices:PsychUIInputText;
		indices = new PsychUIInputText(getX("margin_first"), getY(bottomY - 1), textWidth, animEditing.indices.join(", "), 14);
		indices.onChange.add((old, cur, input) ->
		{
			animEditing.indices = cur.split(",").map(s -> Std.parseInt(s)).filter(n -> n != null);
		});
		indices.cameras = [camHUD];
		tab.add(indices);

		/*
			var coordWidth:Int = 42;
			tab.add(createText(getX("margin_right", coordWidth) - 22, getY(bottomY - 3) + 3, "Y:", 0xFFD8DAF6));
			var y:PsychUIInputText;
			y = new PsychUIInputText(getX("margin_right", coordWidth), getY(bottomY - 3), coordWidth, "", 14);
			y.cameras = [camHUD];
			tab.add(y);

			tab.add(createText(getX("margin_right", 100) - 38, getY(bottomY - 3) + 3, "X:", 0xFFD8DAF6));
			var x:PsychUIInputText;
			x = new PsychUIInputText(getX("margin_right", coordWidth) - 18 - coordWidth - 12, getY(bottomY - 3), coordWidth, "", 14);
			x.cameras = [camHUD];
			tab.add(x); */

		var loop:DoidoCheckmark = new DoidoCheckmark(animEditing.loop);
		loop.x = getX("margin_right", loop.width);
		loop.y = getY(bottomY - 1) - 1;
		loop.onUp.add(() ->
		{
			animEditing.loop = loop.value;
		});
		tab.add(loop);
		tab.add(createText(loop.x - 46, getY(bottomY - 1) + 3, "Loop:", 0xFFD8DAF6));

		tab.add(createText(getX("margin_right", 100) - 38, getY(bottomY - 2) + 3, "FPS: ", 0xFFD8DAF6));
		var fpsStepper = new PsychUINumericStepper(getX("margin_right", 100), getY(bottomY - 2), 1, animEditing.framerate, 1, 339, 0);
		fpsStepper.onValueChange = () ->
		{
			animEditing.framerate = Std.int(fpsStepper.value);
		}
		tab.add(fpsStepper);

		var newButton = new DoidoTextButton("Save as New", "small");
		newButton.x = getX() + 20;
		newButton.y = getY(bottomY) + 7;
		newButton.button.setColorTransform(0, 0.79, 0);
		newButton.label.color = 0xFFFFFFFF;
		tab.add(newButton);

		var saveButton = new DoidoTextButton("Save Current", "small");
		saveButton.x = getX("center", saveButton.width);
		saveButton.y = getY(bottomY) + 7;
		saveButton.button.setColorTransform(0.59, 0.78, 1);
		saveButton.label.color = 0xFFFFFFFF;
		tab.add(saveButton);

		var deleteButton = new DoidoTextButton("Delete Anim", "small");
		deleteButton.x = getX("margin_right", deleteButton.width) - 20;
		deleteButton.y = getY(bottomY) + 7;
		deleteButton.button.setColorTransform(1, 0, 0);
		deleteButton.label.color = 0xFFFFFFFF;
		tab.add(deleteButton);

		tab.add(createText(getX(), getY(0) + 3, "Search:", 0xFFD8DAF6));

		anims = new ChooserWindow(getX("center", 440), getY(1) + 5, 440, 265, [], null);
		anims.view = LIST;
		anims.type = NONE;
		anims.options = char.animList.concat(["Add New"]);
		anims.onClick = (str) ->
		{
			if (str == "Add New")
				animEditing = DoidoSprite.copyAnim(defaultAnim);
			else
			{
				for (anim in char.data.anims)
				{
					if (anim.name == str)
					{
						animEditing = DoidoSprite.copyAnim(anim);
						break;
					}
				}
			}

			curEditing = animEditing.name;
			editText.text = 'Currently Editing: ${curEditing == "" ? "New" : curEditing}';
			name.text = animEditing.name;
			indices.text = animEditing.indices.join(", ");
			prefix.text = animEditing.prefix;
			fpsStepper.value = animEditing.framerate ?? 24;
			loop.value = animEditing.loop ?? false;
		};

		setDescs();

		anims.cameras = [camHUD];
		tab.add(anims);

		function saveAnim(update:Bool = true)
		{
			// you have to actually be making something to save....
			if (animEditing.name.length > 0 && animEditing.prefix.length > 0)
			{
				if (char.existsInList(curEditing) && (update || char.existsInList(animEditing.name)))
				{
					if (char.existsInList(animEditing.name))
						curEditing = animEditing.name;

					for (i in 0...char.data.anims.length)
					{
						var anim = char.data.anims[i];
						if (anim.name == curEditing)
						{
							var oldOffset = anim.offset;
							var oldEditing = curEditing;
							char.data.anims[i] = DoidoSprite.copyAnim(animEditing);
							char.data.anims[i].offset = oldOffset;

							curEditing = animEditing.name;
							char.removeAnim(oldEditing);
							char.addAnim(char.data.anims[i], i);

							break;
						}
					}
				}
				else
				{
					var newAnim = DoidoSprite.copyAnim(animEditing);
					char.data.anims.push(newAnim);
					curEditing = animEditing.name;
					char.addAnim(newAnim);
				}

				char.playAnim(curEditing);

				// dont mind it, really
				if (curEditing == char.idleAnims[0] && char.animExists(curEditing))
					updatePos(char);

				editText.text = 'Currently Editing: ${curEditing == "" ? "New" : curEditing}';
				anims.options = char.animList.concat(["Add New"]);
				setDescs();
				updateAnim();
			}
		}

		newButton.button.onUp.add(() -> saveAnim(false));
		saveButton.button.onUp.add(() -> saveAnim(true));

		deleteButton.button.onUp.add(() ->
		{
			if (char.animList.length >= 2)
			{
				if (char.existsInList(curEditing))
				{
					if (char.curAnimName == curEditing)
					{
						char.playAnim(char.animList[FlxMath.wrap(char.animList.indexOf(curEditing) - 1, 0, char.animList.length - 1)]);
					}
					for (i in 0...char.data.anims.length)
					{
						if (char.data.anims[i].name == curEditing)
						{
							char.data.anims.remove(char.data.anims[i]);
							char.removeAnim(curEditing);
							break;
						}
					}
				}
				else
				{
					// ???
				}

				animEditing = DoidoSprite.copyAnim(defaultAnim);
				curEditing = "";
				editText.text = 'Currently Editing: ${curEditing == "" ? "New" : curEditing}';
				name.text = animEditing.name;
				indices.text = animEditing.indices.join(", ");
				prefix.text = animEditing.prefix;
				fpsStepper.value = animEditing.framerate ?? 24;
				loop.value = animEditing.loop ?? false;
				anims.options = char.animList.concat(["Add New"]);
				setDescs();
				updateAnim();
			}
		});

		var filter:PsychUIInputText;
		filter = new PsychUIInputText(getX("margin_first_search"), getY(0), 372, "", 14);
		filter.onChange.add((old, cur, input) -> anims.filter = cur);
		filter.behindText.color = 0xFFD8DAF6;
		filter.cameras = [camHUD];
		tab.add(filter);

		var glass:FlxSprite = new FlxSprite().loadImage("editors/charting/glass");
		glass.setGraphicSize(filter.behindText.height - 2, filter.behindText.height - 2);
		glass.x = filter.behindText.x + 1;
		glass.y = filter.behindText.y + 1;
		tab.add(glass);

		filter.textObj.x += glass.width + 2;
		filter.fieldWidth -= Std.int(glass.width + 2);

		return tab;
	}

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

	function addMain()
	{
		menuMain = new DoidoBox(803, 19, 458, 32, 0, true, [createAnimations(), createCharacter()], null);
		menuMain.cameras = [camHUD];
		add(menuMain);
	}

	static var camZoom:Float = 0.9;

	var draggingCharacter:Bool = false;
	var typing(get, never):Bool;

	function get_typing():Bool
		return PsychUIInputText.focusOn != null;

	var focused:Bool = true;
	var waitingForFocus:Bool = false;
	var clickedOnWindow:Bool = false;

	override function onFocusLost()
	{
		focused = false;
		super.onFocusLost();
	}

	override function onFocus()
	{
		waitingForFocus = true;
		super.onFocus();
	}

	public var curCursor:lime.ui.MouseCursor = DEFAULT;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		curCursor = DEFAULT;

		if (FlxG.keys.justPressed.S && FlxG.keys.pressed.CONTROL)
			save();

		var overlapsWindow:Bool = false;
		for (basic in members)
		{
			if (Std.isOfType(basic, IWindow))
			{
				if (cast(basic, IWindow).overlapping)
				{
					overlapsWindow = true;
				}
			}
		}

		if (FlxG.mouse.justPressed)
			clickedOnWindow = overlapsWindow;

		if (!overlapsWindow && !clickedOnWindow && !typing && focused)
		{
			if (Controls.justPressed(BACK))
				MusicBeat.switchState(new states.DebugMenu());

			var speed:Float = elapsed * 400;
			if (FlxG.keys.anyPressed([A, D, W, S]))
			{
				if (FlxG.keys.pressed.A)
					camFollow.x -= speed;
				if (FlxG.keys.pressed.D)
					camFollow.x += speed;
				if (FlxG.keys.pressed.W)
					camFollow.y -= speed;
				if (FlxG.keys.pressed.S)
					camFollow.y += speed;
			}

			var daChange:Array<Bool> = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN,
			];

			if (daChange[0])
				updateOffset(-1, 0);
			if (daChange[1])
				updateOffset(1, 0);
			if (daChange[2])
				updateOffset(0, -1);
			if (daChange[3])
				updateOffset(0, 1);

			if (draggingCharacter)
			{
				curCursor = MOVE;
				updateOffset(FlxG.mouse.deltaViewX, FlxG.mouse.deltaViewY, false);
			}
			else if (mouseOverlapsOffset(char))
			{
				curCursor = POINTER;
				if (FlxG.mouse.justPressed)
					draggingCharacter = true;
			}

			if ((FlxG.mouse.pressed && !draggingCharacter) || FlxG.mouse.pressedMiddle)
			{
				curCursor = MOVE;
				camFollow.x -= FlxG.mouse.deltaViewX;
				camFollow.y -= FlxG.mouse.deltaViewY;
			}

			// this only checks if the character is being dragged to cover a bug im not sure how to fix
			// ill think about it later so consider this temporary
			if (FlxG.mouse.wheel != 0 && !draggingCharacter)
			{
				var init = FlxG.mouse.getWorldPosition(camChar);
				camZoom += (FlxG.mouse.wheel) / 2;
				camZoom = FlxMath.bound(camZoom, 0.4, 2.5);
				camChar.zoom = FlxMath.lerp(camChar.zoom, camZoom, elapsed * 12);
				var post = FlxG.mouse.getWorldPosition(camChar);

				camFollow.x += init.x - post.x;
				camFollow.y += init.y - post.y;
			}

			if (FlxG.mouse.justReleased && draggingCharacter)
			{
				updateAnim(true);
				draggingCharacter = false;
			}

			if (FlxG.keys.justPressed.Q)
				changeAnim(-1);
			if (FlxG.keys.justPressed.E)
				changeAnim(1);

			if (FlxG.keys.justPressed.SPACE)
				char.playAnim(char.curAnimName, true);
		}

		if (!focused && waitingForFocus)
		{
			focused = true;
			waitingForFocus = false;
		}

		EditorUtil.setCursor(curCursor);
	}

	function mouseOverlapsOffset(_char:Character)
	{
		var mousePos = FlxG.mouse.getWorldPosition(camChar);
		var offsets:DoidoPoint = char.animOffsets.get(char.curAnimName);
		mousePos.x += offsets.x;
		mousePos.y += offsets.y;
		return _char.overlapsPoint(mousePos);
	}

	public function changeAnim(change:Int = 0):Void
	{
		if (change != 0)
			FlxG.sound.play(Assets.sound('scroll'));
		curAnim += change;
		curAnim = FlxMath.wrap(curAnim, 0, char.animList.length - 1);

		char.playAnim(char.animList[curAnim], true);
		updateAnim();
		// updateTxt();
	}

	public function updatePos(char:Character)
	{
		char.updateHitbox();
		// char.scaleOffset = {x: char.offset.x, y: char.offset.y};
		char.setPosition(middlePoint.x - (char.width - middlePoint.width) / 2, middlePoint.y + (middlePoint.height / 2) - char.height);
		char.x += char.globalOffset.x;
		char.y += char.globalOffset.y;
		// char.updateOffset();
	}

	public function updateAnim(updateData:Bool = false)
	{
		animWindow.updateAnim();

		if (updateData)
		{
			ghost.syncGhost();
			updatePos(ghost);
			for (anim in char.data.anims)
			{
				if (anim.name == char.curAnimName)
				{
					anim.offset = char.getOffset(anim.name);
					break;
				}
			}
		}
	}

	var curAnim:Int = 0;

	function updateOffset(x:Float = 0, y:Float = 0, arrows:Bool = true)
	{
		if (arrows)
		{
			if (FlxG.keys.pressed.ALT)
			{
				x *= 0.1;
				y *= 0.1;
			}
			else if (FlxG.keys.pressed.SHIFT)
			{
				x *= 10;
				y *= 10;
			}
			else if (FlxG.keys.pressed.CONTROL)
			{
				x *= 100;
				y *= 100;
			}
		}

		char.addToOffset(char.curAnimName, -x, -y);

		var loopAnimName:String = char.curAnimName.endsWith("-loop") ? char.curAnimName.replace("-loop", "") : char.curAnimName + "-loop";
		if (char.animExists(loopAnimName))
		{
			var off = char.getOffset(char.curAnimName);
			char.addOffset(loopAnimName, {x: off.x, y: off.y});
		}

		char.playAnim(char.curAnimName, true);
		if (arrows)
			updateAnim(true);
	}

	function save()
	{
		var data:String = Json.stringify(char.data, "\t");
		if (data != null && data.length > 0)
		{
			Assets.fileSave(data.trim(), '${char.curChar}.json');
		}
	}
}

class AnimWindow extends DoidoWindow
{
	var characterEditor:CharacterEditor;

	public var animName:FlxBitmapText;
	public var offsetTxt:FlxBitmapText;
	public var charTxt:FlxBitmapText;
	public var ghostTxt:FlxBitmapText;

	var charSlider:DoidoSlider;

	// var ghostSlider:DoidoSlider;

	public function new(characterEditor:CharacterEditor)
	{
		super(null);
		this.characterEditor = characterEditor;

		bg.scale.set(458, 138);
		bg.updateHitbox();
		bg.setPosition(FlxG.width - bg.width - 18, FlxG.height - bg.height - 18);

		animName = new FlxBitmapText(0, bg.y + 8, Assets.bitmapFont("phantommuff"));
		animName.alignment = CENTER;
		add(animName);

		offsetTxt = new FlxBitmapText(0, animName.y + 32, Assets.bitmapFont("phantommuff"));
		offsetTxt.color = 0xFFD8DAF6;
		offsetTxt.alignment = CENTER;
		offsetTxt.scale.set(0.625, 0.625);
		offsetTxt.updateHitbox();
		add(offsetTxt);

		charTxt = new FlxBitmapText(bg.x + 8, offsetTxt.y + 32, Assets.bitmapFont("phantommuff"));
		charTxt.alignment = LEFT;
		charTxt.text = "Character: ";
		charTxt.color = 0xFFD8DAF6;
		charTxt.scale.set(0.625, 0.625);
		charTxt.updateHitbox();
		add(charTxt);

		charSlider = new DoidoSlider(charTxt.x + charTxt.width + 14, charTxt.y + 7, 320, 6, -1, -1, 3, 3, /*Math.POSITIVE_INFINITY*/);
		charSlider.onScrub.add((sld) ->
		{
			var isOff:Bool = (charSlider.value < 0.0);
			if (isOff)
				characterEditor.char.playAnim(characterEditor.char.curAnimName, true);
			else
			{
				characterEditor.char.playAnim(characterEditor.char.curAnimName, true, Math.floor(charSlider.value));
				characterEditor.char.anim.pause();
			}
		});
		add(charSlider);

		ghostTxt = new FlxBitmapText(bg.x + 8, charTxt.y + 32, Assets.bitmapFont("phantommuff"));
		ghostTxt.alignment = LEFT;
		ghostTxt.text = "Ghost: ";
		ghostTxt.color = 0xFFD8DAF6;
		ghostTxt.scale.set(0.625, 0.625);
		ghostTxt.updateHitbox();
		add(ghostTxt);

		/*ghostSlider = new DoidoSlider(charSlider.x, ghostTxt.y + 7, 320, 6, -1, -1, 3, 3);
			ghostSlider.onScrub.add((sld) ->
			{
				var isOff:Bool = (ghostSlider.value < 0.0);
				if (isOff)
					characterEditor.ghost.playAnim(characterEditor.ghost.curAnimName, true);
				else
				{
					characterEditor.ghost.playAnim(characterEditor.ghost.curAnimName, true, Math.floor(ghostSlider.value));
					characterEditor.ghost.anim.pause();
				}
			});
			add(ghostSlider); */

		updateAnim();
	}

	public function updateAnim()
	{
		var char = characterEditor.char;
		var ghost = characterEditor.ghost;
		var anim = characterEditor.char.curAnimName;
		var offsets:DoidoPoint = char.animOffsets.get(anim);

		animName.text = anim;
		offsetTxt.text = 'X: ${offsets.x} / Y: ${offsets.y}';

		animName.x = bg.x + bg.width / 2 - animName.width / 2;
		offsetTxt.x = bg.x + bg.width / 2 - offsetTxt.width / 2;

		if (char.animExists(anim))
		{
			charSlider.rangeMax = char.animation.curAnim.frames.length - 1;
			charSlider.steps = char.animation.curAnim.frames.length - 1;
			charSlider.snappingStrength = Math.POSITIVE_INFINITY;
		}

		/*
			ghostSlider.rangeMax = ghost.animation.curAnim.frames.length - 1;
			ghostSlider.steps = ghost.animation.curAnim.frames.length - 1;
			ghostSlider.snappingStrength = Math.POSITIVE_INFINITY;
		 */
	}
}

class Ghost extends Character
{
	public var char:Character = null;

	public function new(char:Character)
	{
		super(char.curChar, char.isPlayer);
		this.char = char;
		ghostAlpha = 0.4;
		syncGhost();
	}

	public function syncGhost()
	{
		clearAnims();
		if (curChar == char.curChar)
			data = char.data;

		loadCharacter(curChar == char.curChar);
		alpha = (data.alpha ?? 1.0) * ghostAlpha;
	}

	public var ghostAlpha(default, set):Float;

	public function set_ghostAlpha(f:Float)
	{
		ghostAlpha = f;
		alpha = (data.alpha ?? 1.0) * ghostAlpha;
		return ghostAlpha;
	}
}
