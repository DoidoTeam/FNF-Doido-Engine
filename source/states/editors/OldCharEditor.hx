package states.editors;

import haxe.Json;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxButton;
import gameObjects.Character;
import data.CharacterData;
import data.GameData.MusicBeatState;
import openfl.net.FileReference;
import states.PlayState;
import sys.io.File;

class CharacterEditorState extends MusicBeatState
{
	public function new(curChar:String)
	{
		this.curChar = curChar;
		this.ghostChar = curChar;
		super();
	}
	var curChar:String = "";
	var ghostChar:String = "";

	var char:Character;
	var ghost:Character;

	var charData:DoidoChar;

	var animDropDownGrp:FlxSpriteGroup;
	var animNameInput:FlxUIInputText;
	var animXmlInput:FlxUIInputText;
	var indicesInput:FlxUIInputText;
	var stepperFps:FlxUINumericStepper;
	var checkLoop:FlxUICheckBox;

	function reloadAnimDropDown()
	{
		animDropDownGrp.clear();

		//var charAnims = char.animation.getNameList();
		var charAnims:Array<String> = [];
		for(anim in char.charData.animations)
			charAnims.push(anim.animName);

		var charAnimDD = new FlxUIDropDownMenu(10, 130, FlxUIDropDownMenu.makeStrIdLabelArray(charAnims, true), function(character:String)
		{
			var animName:String = charAnims[Std.parseInt(character)];
			char.playAnim(animName, true);

			var anim:DoidoAnim = null;
			for(i in char.charData.animations)
			{
				if(i.animName == animName)
					anim = i;
			}
			if(anim == null) return;

			animNameInput.text 	= anim.animName;
			animXmlInput.text 	= anim.animXml;
			stepperFps.value 	= anim.framerate;
			checkLoop.checked 	= anim.loop;
			// da indices
			indicesInput.text 	= '';
			for(i in anim.frameIndices)
			{
				if(i == anim.frameIndices.length - 1)
					indicesInput.text += '$i';
				else
					indicesInput.text += '${i},';
			}
		});
		animDropDownGrp.add(charAnimDD);
		try {
			charAnimDD.selectedLabel = char.animation.curAnim.name;
		}
		catch(e) {}

		var ghostAnims = ghost.animation.getNameList();
		if(ghost.curChar == char.curChar)
			ghostAnims = charAnims;
		
		var ghostAnimDD = new FlxUIDropDownMenu(140, 130, FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnims, true), function(character:String)
		{
			ghost.playAnim(ghostAnims[Std.parseInt(character)], true);
		});
		animDropDownGrp.add(ghostAnimDD);
		try {
			ghostAnimDD.selectedLabel = ghost.animation.curAnim.name;
		}
		catch(e) {}
	}

	var camFollow:FlxObject;
	static var camZoom:Float = 1.0;

	override function create()
	{
		super.create();
		var grid = FlxGridOverlay.create(32, 32, FlxG.width * 2, FlxG.height * 2);
		grid.screenCenter();
		add(grid);

		char = new Character();
		char.setPosition(300,200);
		char.x += char.globalOffset.x;
		char.x += char.globalOffset.y;
		char.reloadChar(curChar);
		char.antialiasing = char.charData.antialiasing;
		add(char);

		camFollow = new FlxObject(0,0);
		updateCamPos();
		FlxG.camera.follow(camFollow, LOCKON, 1);
		FlxG.camera.scroll.x = -2000;
		FlxG.camera.scroll.y = -2000;
		//FlxG.camera.focusOn(camFollow.getPosition());

		ghost = new Character();
		ghost.setPosition(300,200);
		ghost.reloadChar(ghostChar);
		ghost.antialiasing = ghost.charData.antialiasing;
		ghost.alpha = 0.4;
		add(ghost);

		ghost.x += ghost.globalOffset.x;
		ghost.x += ghost.globalOffset.y;

		var tabs = [
			{name: "anims", label: 'Animation'},
			{name: "chars", label: 'Character'},
			{name: "editor",label: 'Editor'},
		];

		var charsHUD = new FlxUITabMenu(null, tabs, true);
		charsHUD.resize(280, 180); // 120
		charsHUD.scrollFactor.set();
		charsHUD.x = FlxG.width - charsHUD.width;
		add(charsHUD);

		var animsTab = new FlxUI(null, charsHUD);
		animsTab.name = "anims";
		charsHUD.addGroup(animsTab);

		animDropDownGrp = new FlxSpriteGroup();
		reloadAnimDropDown();

		animNameInput = new FlxUIInputText(10, 20, 180, "", 8);

		animXmlInput = new FlxUIInputText(10, 50, 180, "", 8);

		indicesInput = new FlxUIInputText(10, 80, 180, "", 8);

		stepperFps = new FlxUINumericStepper(200, 20, 1, 24, 0, 60);
		stepperFps.value = 24;

		checkLoop = new FlxUICheckBox(200, 50, null, null, "Loop", 100);
		checkLoop.checked = false;

		var addAnimButton = new FlxButton(10, 95, "Add/Reload", function()
		{
			var gottaReload:Bool = true;
			var animName:String = animNameInput.text;

			var anim:DoidoAnim = CharacterData.defaultAnim();
			for(i in char.charData.animations)
			{
				if(i.animName == animName)
				{
					gottaReload = false;
					char.charData.animations.remove(i);
				}
			}

			anim.animName 	= animNameInput.text;
			anim.animXml 	= animXmlInput.text;
			anim.framerate 	= Math.floor(stepperFps.value);
			anim.loop 		= checkLoop.checked;
			if(indicesInput.text != "")
			{
				var allowedChars:String = "0123456789";

				var daIndices:String = indicesInput.text.replace(" ", "");
				var what:Array<String> = daIndices.split(",");
				for(i in what)
				{
					if(allowedChars.contains(i))
						anim.frameIndices.push(Std.parseInt(i));
				}
			}

			char.charData.animations.push(anim);
			char.reloadCharData();
			char.playAnim(animName, true);

			if(gottaReload)
				reloadAnimDropDown();

			if(char.isPlayer)
				char.flipX = !char.flipX;
		});

		var removeAnimButton = new FlxButton(100, 95, "Remove Anim", function()
		{
			for(i in char.charData.animations)
			{
				if(i.animName == animNameInput.text)
					char.charData.animations.remove(i);
			}
			char.reloadCharData();
			reloadAnimDropDown();

			if(char.isPlayer)
				char.flipX = !char.flipX;
		});

		animsTab.add(new FlxText(10,20-15,0,"Animation Name: "));
		animsTab.add(animNameInput);
		animsTab.add(new FlxText(10,50-15,0,"Animation Symbol (inside the XML): "));
		animsTab.add(animXmlInput);
		animsTab.add(new FlxText(10,80-15,0,"Frame Indices (optional): "));
		animsTab.add(indicesInput);
		animsTab.add(new FlxText(200,20-15,0,"Framerate: "));
		animsTab.add(stepperFps);
		animsTab.add(checkLoop);
		animsTab.add(addAnimButton);
		animsTab.add(removeAnimButton);
		animsTab.add(new FlxText(10, 130-15,0,"Current Anim: "));
		animsTab.add(new FlxText(140,130-15,0,"Ghost Anim: "));
		animsTab.add(animDropDownGrp);

		var charsTab = new FlxUI(null, charsHUD);
		charsTab.name = "chars";
		charsHUD.addGroup(charsTab);

		var editorTab = new FlxUI(null, charsHUD);
		editorTab.name = "editor";
		charsHUD.addGroup(editorTab);

		var sheetInput = new FlxUIInputText(10, 20, 180, "", 8);
		sheetInput.text = char.charData.spritesheet;
		sheetInput.name = 'sheetInput';

		var charList = CoolUtil.charList();

		var charDropDown = new FlxUIDropDownMenu(10, 130, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			var choice = charList[Std.parseInt(character)];
			Main.switchState(new CharacterEditorState(choice));
		});
		charDropDown.selectedLabel = curChar;

		var ghostDropDown = new FlxUIDropDownMenu(10, 25, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			var choice = charList[Std.parseInt(character)];
			ghost.reloadChar(choice);

			ghost.setPosition(300,200);
			ghost.x += ghost.globalOffset.x;
			ghost.x += ghost.globalOffset.y;
			ghost.antialiasing = ghost.charData.antialiasing;
		});
		ghostDropDown.selectedLabel = ghostChar;

		var checkShowGhost = new FlxUICheckBox(10, 70, null, null, "Show Ghost", 100);
		checkShowGhost.checked = ghost.visible;
		checkShowGhost.callback = function()
		{
			ghost.visible = checkShowGhost.checked;
		};

		var stepperCamZoom = new FlxUINumericStepper(10, 100, 0.1, 1.0, 0.1, 4, 2);
		stepperCamZoom.name = 'camZoom';
		stepperCamZoom.value = camZoom;

		var checkFlipGhost = new FlxUICheckBox(10, 50, null, null, "Ghost FlipX", 100);
		checkFlipGhost.checked = ghost.flipX;
		function flipChar():Void
		{
			char.flipX = char.charData.flipX;
			if(char.isPlayer)
				char.flipX = !char.flipX;

			ghost.flipX = checkFlipGhost.checked;
			if(char.isPlayer)
				ghost.flipX = !ghost.flipX;
		}
		checkFlipGhost.callback = function()
		{
			flipChar();
		};

		var checkFlipChar = new FlxUICheckBox(140, 130+2.5, null, null, "FlipX", 30);
		checkFlipChar.checked = char.charData.flipX;
		checkFlipChar.callback = function()
		{
			char.charData.flipX = checkFlipChar.checked;
			flipChar();
		};

		var checkPlayer = new FlxUICheckBox(140+55, 130+2.5, null, null, "Playable?", 55);
		checkPlayer.callback = function()
		{
			char.isPlayer = checkPlayer.checked;
			flipChar();
		};

		var stepperScale = new FlxUINumericStepper(10, 100, 0.1, 1.0, 0.1, 10, 1);
		stepperScale.name = 'stepperScale';
		stepperScale.value = char.charData.scale;

		var stepperPosOffX = new FlxUINumericStepper(20, 50, 10, 0, -9990, 9990, 1);
		stepperPosOffX.name = 'posOffX';
		stepperPosOffX.value = char.charData.posOffset[0];

		var stepperPosOffY = new FlxUINumericStepper(20, 70, 10, 0, -9990, 9990, 1);
		stepperPosOffY.name = 'posOffY';
		stepperPosOffY.value = char.charData.posOffset[1];

		var stepperCamOffX = new FlxUINumericStepper(100, 50, 10, 0, -9990, 9990, 1);
		stepperCamOffX.name = 'camOffX';
		stepperCamOffX.value = char.charData.camOffset[0];

		var stepperCamOffY = new FlxUINumericStepper(100, 70, 10, 0, -9990, 9990, 1);
		stepperCamOffY.name = 'camOffY';
		stepperCamOffY.value = char.charData.camOffset[1];

		var saveButton = new FlxButton(195, 20, "Save", function()
		{
			var data:String = Json.stringify(char.charData, "\t");

			if(data != null && data.length > 0)
			{
				var _file = new FileReference();
				_file.save(data.trim(), char.curChar + ".json");
			}
		});

		var checkAntial = new FlxUICheckBox(80, 100, null, null, "Antialiasing", 70);
		checkAntial.checked = char.charData.antialiasing;
		checkAntial.callback = function()
		{
			char.antialiasing = char.charData.antialiasing = checkAntial.checked;
		};

		var checkQuickDancer = new FlxUICheckBox(170, 100, null, null, "Quick Dancer", 70);
		checkQuickDancer.checked = char.charData.quickDancer;
		checkQuickDancer.callback = function()
		{
			char.charData.quickDancer = checkQuickDancer.checked;
		};

		charsTab.add(saveButton);
		charsTab.add(new FlxText(10,20-15,0,"Sprite Sheet:"));
		charsTab.add(sheetInput);
		charsTab.add(checkFlipChar);
		charsTab.add(checkPlayer);
		charsTab.add(new FlxText(20-15,	stepperPosOffX.y-15,0,"Global Offset:"));
		charsTab.add(new FlxText(20-15, stepperPosOffX.y, 0, "X:"));
		charsTab.add(new FlxText(20-15, stepperPosOffY.y, 0, "Y:"));
		charsTab.add(stepperPosOffX);
		charsTab.add(stepperPosOffY);
		charsTab.add(new FlxText(100-15,stepperCamOffX.y-15,0,"Camera Offset:"));
		charsTab.add(new FlxText(100-15,stepperCamOffX.y, 0, "X:"));
		charsTab.add(new FlxText(100-15,stepperCamOffY.y, 0, "Y:"));
		charsTab.add(stepperCamOffX);
		charsTab.add(stepperCamOffY);
		charsTab.add(new FlxText(10,100-15,0,"Scale: "));
		charsTab.add(stepperScale);
		charsTab.add(checkAntial);
		charsTab.add(checkQuickDancer);
		
		// adding these last
		charsTab.add(new FlxText(10, 130-15,0,"Character: "));
		charsTab.add(charDropDown);

		// ghost tab!!
		editorTab.add(checkFlipGhost);
		editorTab.add(checkShowGhost);
		editorTab.add(new FlxText(10,100-15,0,"Camera Zoom:"));
		editorTab.add(stepperCamZoom);
		editorTab.add(new FlxText(10,10,0,"Ghost: "));
		editorTab.add(ghostDropDown);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		switch(id)
		{
			case FlxUIInputText.CHANGE_EVENT:
				var input:FlxUIInputText = cast sender;
				switch(input.name)
				{
					case 'sheetInput':
						char.charData.spritesheet = input.text;
						char.reloadCharData();
				}

			case FlxUINumericStepper.CHANGE_EVENT:
				if(sender is FlxUINumericStepper)
				{
					var stepper:FlxUINumericStepper = cast sender;
					switch(stepper.name)
					{
						case 'camZoom':
							camZoom = stepper.value;

						case 'stepperScale'|'posOffX'|'posOffY'|'camOffX'|'camOffY':
							var storedAnim:String;
							try
							{
								storedAnim = char.animation.curAnim.name;
							}
							catch(e)
								storedAnim = "";

							switch(stepper.name)
							{
								case 'stepperScale':
									char.charData.scale = stepper.value;
								case 'posOffX':
									char.charData.posOffset[0] = stepper.value;
								case 'posOffY':
									char.charData.posOffset[1] = stepper.value;
								case 'camOffX':
									char.charData.camOffset[0] = stepper.value;
								case 'camOffY':
									char.charData.camOffset[1] = stepper.value;
							}
							char.reloadCharData();
							char.playAnim(storedAnim);

							if(char.isPlayer)
								char.flipX = !char.flipX;

							char.setPosition(300,200);
							char.x += char.charData.posOffset[0];
							char.y += char.charData.posOffset[1];
							if(char.curChar == ghost.curChar)
								ghost.setPosition(char.x, char.y);

						default:
					}
				}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		FlxG.camera.followLerp = elapsed * 3;
		updateCamPos();

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, camZoom, elapsed * 3);

		if(FlxG.keys.justPressed.ESCAPE)
			Main.switchState(new PlayState());

		if(FlxG.keys.justPressed.LEFT) changeOffset(-1,0);
		if(FlxG.keys.justPressed.RIGHT)changeOffset(1, 0);
		if(FlxG.keys.justPressed.UP)   changeOffset(0,-1);
		if(FlxG.keys.justPressed.DOWN) changeOffset(0, 1);

		if(FlxG.keys.justPressed.SPACE)
			char.playAnim(char.animation.curAnim.name);
	}

	function changeOffset(offsetX:Int = 0, offsetY:Int = 0):Void
	{
		var anim:DoidoAnim = null;
		for(i in char.charData.animations)
		{
			if(i.animName == animNameInput.text)
				anim = i;
		}
		if(anim == null) return;

		if(FlxG.keys.pressed.SHIFT)
		{
			offsetX *= 10;
			offsetY *= 10;
		}
		else if(FlxG.keys.pressed.CONTROL)
		{
			offsetX *= 100;
			offsetY *= 100;
		}

		anim.offset[0] += offsetX;
		anim.offset[1] += offsetY;

		var storedAnim:String = char.animation.curAnim.name;
		char.reloadCharData();
		char.playAnim(storedAnim, true);
	}

	function updateCamPos()
	{
		camFollow.setPosition(0,0);

		var playerMult:Int = (char.isPlayer ? -1 : 1);

		camFollow.setPosition(char.getMidpoint().x + (200 * playerMult), char.getMidpoint().y - 20);

		camFollow.x += char.cameraOffset.x * playerMult;
		camFollow.y += char.cameraOffset.y;
	}
}