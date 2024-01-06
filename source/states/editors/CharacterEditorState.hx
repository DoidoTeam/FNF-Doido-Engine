package states.editors;

import haxe.Json;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import gameObjects.Character;
import gameObjects.hud.Rating;
import data.CharacterData;
import data.GameData.MusicBeatState;
import openfl.net.FileReference;
import states.*;
import sys.io.File;

class CharacterEditorState extends MusicBeatState
{
	public function new(curChar:String)
	{
		this.curChar = curChar;
		super();
	}
	var curChar:String = "";

	var char:Character;
	var ghost:Character;

	var exportTxt:FlxText;
	
	var camMain:FlxCamera;
	var camHUD:FlxCamera;
	var camFollow:FlxObject;
	
	var ghostAnimButtons:FlxSpriteGroup;
	
	function reloadGhostButtons()
	{
		ghostAnimButtons.clear();
	
		var ghostAnims = ghost.animation.getNameList();
		for(i in 0...ghostAnims.length)
		{
			var animButton = new FlxButton(100, 30 + (20 * i), ghostAnims[i], function() {
				if(char.curChar == ghost.curChar)
					ghost.animOffsets = char.animOffsets;

				ghost.playAnim(ghostAnims[i], true);
			});
			ghostAnimButtons.add(animButton);
			animButton.cameras = [camHUD];
		}
	}
	
	function setCharPos(dude:Character)
	{
		dude.setPosition(FlxG.width * 0.8, FlxG.height * 1.5);
		dude.y -= dude.height;
		
		dude.x += dude.globalOffset.x;
		dude.y += dude.globalOffset.y;
	}
	
	function spawnRating()
	{
		var lol = new Rating("sick", 999);
		lol.setPos(char.x + char.ratingsOffset.x, char.y + char.ratingsOffset.y);
		add(lol);
	}
	
	var changeInputX:FlxUIInputText;
	var changeInputY:FlxUIInputText;
	var checkCamFollow:FlxUICheckBox;

	override function create()
	{
		super.create();
		Controls.setSoundKeys(true);
		FlxG.mouse.visible = true;
		var grid = FlxGridOverlay.create(32, 32, FlxG.width * 2, FlxG.height * 2);
		//grid.screenCenter();
		add(grid);
		
		Rating.preload("base");
		
		camMain = new FlxCamera();
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alphaFloat = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camMain, true);
		
		camFollow = new FlxObject();
		FlxG.camera.follow(camFollow, LOCKON, 1);
		//FlxG.camera.focusOn(camFollow.getPosition());
		camMain.zoom = camZoom; // 0.7

		char = new Character();
		char.reloadChar(curChar);
		setCharPos(char);
		add(char);

		ghost = new Character();
		ghost.reloadChar(curChar);
		setCharPos(ghost);
		ghost.alpha = 0.4;
		add(ghost);

		exportTxt = new FlxText(0,0,0,"",24);
		exportTxt.setFormat(Main.gFont, 18, 0xFFFFFFFF, RIGHT);
		exportTxt.setBorderStyle(OUTLINE, 0xFF000000, 2);
		exportTxt.cameras = [camHUD];
		add(exportTxt);
		
		updateTxt();

		var animsHud = new FlxUITabMenu(null, [{name: "anims", label: 'Animations'}], true);
		animsHud.resize(190, FlxG.height);
		animsHud.scrollFactor.set();
		animsHud.cameras = [camHUD];
		add(animsHud);

		var animTab = new FlxUI(null, animsHud);
		animTab.cameras = [camHUD];
		animTab.name = "anims";
		animsHud.addGroup(animTab);

		animTab.add(new FlxText(10, 10,0,"Character: "));
		animTab.add(new FlxText(100,10,0,"Ghost: "));
		
		ghostAnimButtons = new FlxSpriteGroup();
		ghostAnimButtons.cameras = [camHUD];
		animTab.add(ghostAnimButtons);

		var animList = char.animation.getNameList();
		for(i in 0...animList.length)
		{
			var animButton = new FlxButton(10, 30 + (20 * i), animList[i], function() {
				char.playAnim(animList[i], true);
				updateInputTxt();
				updateTxt();
			});
			animTab.add(animButton);
			animButton.cameras = [camHUD];
		}
		reloadGhostButtons();

		var charsHud = new FlxUITabMenu(null, [{name: "chars", label: 'Characters:'}], true);
		charsHud.resize(280, 205);
		charsHud.scrollFactor.set();
		charsHud.cameras = [camHUD];
		charsHud.x = FlxG.width - charsHud.width;
		add(charsHud);

		var charsTab = new FlxUI(null, charsHud);
		charsTab.cameras = [camHUD];
		charsTab.name = "chars";
		charsHud.addGroup(charsTab);

		var charList = CoolUtil.charList();

		var charDropDown = new FlxUIDropDownMenu(10, 25, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			var choice = charList[Std.parseInt(character)];
			Main.switchState(new CharacterEditorState(choice));
		});
		charDropDown.selectedLabel = curChar;
		charDropDown.cameras = [camHUD];

		var ghostDropDown = new FlxUIDropDownMenu(140, 25, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			//Main.switchState(new CharacterEditorState(curChar, charList[Std.parseInt(character)]));
			ghost.reloadChar(charList[Std.parseInt(character)]);
			reloadGhostButtons();
			setCharPos(ghost);
		});
		ghostDropDown.selectedLabel = ghost.curChar;
		ghostDropDown.cameras = [camHUD];

		var checkFlipChar = new FlxUICheckBox(10, 50, null, null, "Char FlipX", 100);
		checkFlipChar.checked = char.flipX;
		function flipCheck()
		{
			char.flipX = checkFlipChar.checked;
			if(char.isPlayer)
				char.flipX = !char.flipX;
		}
		checkFlipChar.callback = flipCheck;
		checkFlipChar.cameras = [camHUD];

		var checkFlipGhost = new FlxUICheckBox(140, 50, null, null, "Ghost FlipX", 100);
		checkFlipGhost.checked = ghost.flipX;
		checkFlipGhost.callback = function()
		{
			ghost.flipX = checkFlipGhost.checked;
		};
		checkFlipGhost.cameras = [camHUD];
		
		var checkIsPlayer = new FlxUICheckBox(10, 75, null, null, "Playable?", 100);
		checkIsPlayer.callback = function()
		{
			char.isPlayer = checkIsPlayer.checked;
			flipCheck();
		};
		checkIsPlayer.cameras = [camHUD];

		var checkShowGhost = new FlxUICheckBox(140, 75, null, null, "Show Ghost", 100);
		checkShowGhost.checked = ghost.visible;
		checkShowGhost.callback = function()
		{
			ghost.visible = checkShowGhost.checked;
		};
		checkShowGhost.cameras = [camHUD];
		
		var changeButtons = new FlxSpriteGroup();
		// selectedChange buttons
		function paintEmButtons()
		{
			for(item in changeButtons.members)
			if(Std.isOfType(item, FlxButton))
			{
				var button:FlxButton = cast item;
				
				button.color 		= FlxColor.WHITE;
				button.label.color 	= FlxColor.BLACK;
				if(button.text.toLowerCase() == selectedChange)
				{
					button.color 		= FlxColor.GRAY;
					button.label.color 	= FlxColor.WHITE;
				}
			}
		}
		var thoseButtons:Array<String> = ["animation", "global", "camera", "ratings"];
		for(i in 0...thoseButtons.length)
		{
			var butt = new FlxButton(
			10  + (80 * (i % 2)),
			115 + (20 * Math.floor(i / 2)),
			thoseButtons[i],
			function() {
				selectedChange = thoseButtons[i].toLowerCase();
				paintEmButtons();
				updateInputTxt();
			});
			changeButtons.add(butt);
		}
		paintEmButtons();
		
		changeInputX = new FlxUIInputText(190, 115, 55, "", 8);
		changeInputX.cameras = [camHUD];
		changeInputX.name = 'inputX';
		
		changeInputY = new FlxUIInputText(190, 135, 55, "", 8);
		changeInputY.cameras = [camHUD];
		changeInputY.name = 'inputY';
		
		updateInputTxt();
		
		var saveButton = new FlxButton(10, 160, "Save", function() {
			saveOffsets();
		});
		
		checkCamFollow = new FlxUICheckBox(140, 160, null, null, "Focus on Character", 100);
		checkCamFollow.checked = true;
		checkCamFollow.cameras = [camHUD];

		charsTab.add(checkFlipChar);
		charsTab.add(checkFlipGhost);
		charsTab.add(checkIsPlayer);
		charsTab.add(checkShowGhost);
		charsTab.add(new FlxText(10,115-15,0,"Currently Editing: "));
		charsTab.add(changeButtons);
		charsTab.add(new FlxText(190-15,115,0,"X: "));
		charsTab.add(changeInputX);
		charsTab.add(new FlxText(190-15,135,0,"Y: "));
		charsTab.add(changeInputY);
		charsTab.add(saveButton);
		charsTab.add(checkCamFollow);
		// adding these last
		charsTab.add(new FlxText(10, 10,0,"Character: "));
		charsTab.add(charDropDown);
		charsTab.add(new FlxText(140,10,0,"Ghost: "));
		charsTab.add(ghostDropDown);
	}
	
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		switch(id)
		{
			case FlxUIInputText.CHANGE_EVENT:
				var input:FlxUIInputText = cast sender;
				switch(input.name)
				{
					case 'inputX'|'inputY':
						var formatText:String = input.text;
						var inputArray:Array<String> = formatText.split("");
						var possibleNums:String = '0123456789.-';
						for(i in inputArray)
							if(!possibleNums.contains(i))
								formatText = formatText.replace(i, "");
						
						if(formatText == "") formatText = "0";
						
						var inputNum:Float = Std.parseFloat(formatText);
						
						switch(selectedChange)
						{
							case "global":
								if(input.name == 'inputX')
									char.globalOffset.x = inputNum;
								else
									char.globalOffset.y = inputNum;
								setCharPos(char);
								
								if(char.curChar == ghost.curChar)
								{
									ghost.globalOffset.set(char.globalOffset.x, char.globalOffset.y);
									setCharPos(ghost);
								}
								
							case "camera":
								checkCamFollow.checked = true;
								if(input.name == 'inputX')
									char.cameraOffset.x = inputNum;
								else
									char.cameraOffset.y = inputNum;
						
							case "animation":
								if(input.name == 'inputX')
									char.animOffsets.get(char.animation.curAnim.name)[0] = inputNum;
								else
									char.animOffsets.get(char.animation.curAnim.name)[1] = inputNum;
								char.playAnim(char.animation.curAnim.name, true);
								
								if(char.animation.curAnim.name == ghost.animation.curAnim.name
								&& char.curChar == ghost.curChar)
								{
									ghost.playAnim(char.animation.curAnim.name, true);
									ghost.animOffsets = char.animOffsets;
								}
							
							case "ratings":
								if(input.name == 'inputX')
									char.ratingsOffset.x = inputNum;
								else
									char.ratingsOffset.y = inputNum;
								spawnRating();
						}
						updateTxt();
				}
		}
	}
	
	static var camZoom:Float = 1.0;
	var dragCam:Array<Float> = [];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.mouse.visible = false;
			Main.switchState(new LoadSongState());
		}
			
		if(FlxG.mouse.wheel != 0)
		{
			camZoom += (FlxG.mouse.wheel * 10 * elapsed);
			if(camZoom < 0.4)
				camZoom = 0.4;
			
			updateTxt();
		}
		
		camMain.zoom = Math.floor(camZoom / 0.1) * 0.1;
		
		// you can drag the camera
		if(FlxG.mouse.pressedMiddle)
		{
			if(FlxG.mouse.justPressedMiddle)
			{
				camMain.followLerp = 1;
				checkCamFollow.checked = false;
				dragCam = [camFollow.x, camFollow.y, FlxG.mouse.x, FlxG.mouse.y];
			}
			camFollow.setPosition(
				dragCam[0] + (dragCam[2] - FlxG.mouse.x) * 0.8,
				dragCam[1] + (dragCam[3] - FlxG.mouse.y) * 0.8
			);
		}
		// follows the character
		if(checkCamFollow.checked)
		{
			camMain.followLerp = elapsed * 3;
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			camFollow.setPosition(char.getMidpoint().x + (200 * playerMult), char.getMidpoint().y - 20);

			camFollow.x += char.cameraOffset.x * playerMult;
			camFollow.y += char.cameraOffset.y;
		}
		
		var daChange:Array<Bool> = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		];
		
		if(daChange[0]) updateOffset(-1, 0);
		if(daChange[1]) updateOffset(1,  0);
		if(daChange[2]) updateOffset(0, -1);
		if(daChange[3]) updateOffset(0,  1);
		
		// just to test things out
		if(FlxG.keys.justPressed.SPACE)
			updateOffset();
	}
	
	static var selectedChange:String = "animation";

	function updateOffset(x:Float = 0, y:Float = 0)
	{
		if(FlxG.keys.pressed.ALT) {
			x*=0.1;
			y*=0.1;
		} else if(FlxG.keys.pressed.SHIFT) {
			x*=10;
			y*=10;
		} else if(FlxG.keys.pressed.CONTROL) {
			x*=100;
			y*=100;
		}
		
		// ARROWS WASD IJKL
		switch(selectedChange)
		{
			case "global":
				char.globalOffset.x += x;
				char.globalOffset.y += y;
				setCharPos(char);
				
				if(char.curChar == ghost.curChar)
				{
					ghost.globalOffset.set(char.globalOffset.x, char.globalOffset.y);
					setCharPos(ghost);
				}
				
			case "camera":
				checkCamFollow.checked = true;
				char.cameraOffset.x += x;
				char.cameraOffset.y += y;
		
			case "animation":
				char.animOffsets.get(char.animation.curAnim.name)[0] += -x;
				char.animOffsets.get(char.animation.curAnim.name)[1] += -y;
				char.playAnim(char.animation.curAnim.name, true);
				
				if(char.animation.curAnim.name == ghost.animation.curAnim.name
				&& char.curChar == ghost.curChar)
				{
					ghost.playAnim(char.animation.curAnim.name, true);
					ghost.animOffsets = char.animOffsets;
				}
			case "ratings":
				char.ratingsOffset.x += x;
				char.ratingsOffset.y += y;
				spawnRating();
		}
		updateInputTxt();
		
		updateTxt();
	}

	function updateTxt()
	{
		exportTxt.text = "";
		for(anim in char.animation.getNameList())
		{
			if(!char.animOffsets.exists(anim))
				char.addOffset(anim);

			var offsets:Array<Float> = char.animOffsets.get(anim);

			exportTxt.text += '$anim ${offsets[0]} ${offsets[1]}\n';
		}
		exportTxt.text
		+='\nGlobal Offset: ${char.globalOffset.x} ${char.globalOffset.y}'
		+ '\nCamera Offset: ${char.cameraOffset.x} ${char.cameraOffset.y}'
		+ '\nRatings Offset: ${char.ratingsOffset.x} ${char.ratingsOffset.y}'
		+ '\nZoom (on editor): ${camMain.zoom}';
		exportTxt.x = FlxG.width - exportTxt.width;
		exportTxt.y = FlxG.height- exportTxt.height;
	}
	
	function updateInputTxt()
	{
		switch(selectedChange)
		{
			case "global":
				changeInputX.text = Std.string(char.globalOffset.x);
				changeInputY.text = Std.string(char.globalOffset.y);
				
			case "camera":
				changeInputX.text = Std.string(char.cameraOffset.x);
				changeInputY.text = Std.string(char.cameraOffset.y);
		
			case "animation":
				var daAnim = char.animOffsets.get(char.animation.curAnim.name);
				
				changeInputX.text = Std.string(daAnim[0]);
				changeInputY.text = Std.string(daAnim[1]);
			
			case "ratings":
				changeInputX.text = Std.string(char.ratingsOffset.x);
				changeInputY.text = Std.string(char.ratingsOffset.y);
		}
	}

	function saveOffsets()
	{
		var exportData = CharacterData.defaultOffsets();
		
		exportData.globalOffset = [char.globalOffset.x, char.globalOffset.y];
		exportData.cameraOffset = [char.cameraOffset.x, char.cameraOffset.y];
		
		for(anim => offsets in char.animOffsets)
			exportData.animOffsets.push([anim, offsets[0], offsets[1]]);
		
		var data:String = Json.stringify(exportData, "\t");

		if(data != null && data.length > 0)
		{
			var _file = new FileReference();
			_file.save(data.trim(), char.curChar + ".json");
		}
	}
}