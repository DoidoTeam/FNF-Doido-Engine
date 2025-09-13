package states.editors;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.net.FileReference;
import backend.utils.CharacterUtil;
import objects.Character;
import objects.menu.DoidoSlider;
import states.*;
import subStates.editors.ChooserSubState;

class CharacterEditorState extends MusicBeatState
{
	public function new(curChar:String, wasPlayState:Bool = false)
	{
		this.curChar = curChar;
		this.wasPlayState = wasPlayState;
		super();
	}
	var curChar:String = "";
	var wasPlayState:Bool = false;

	var charGrp:FlxTypedGroup<Character> = new FlxTypedGroup<Character>();
	var char:Character;
	var ghost:Character;

	var exportTxt:FlxText;
	
	var camMain:FlxCamera;
	var camHUD:FlxCamera;
	var camFollow:FlxObject;
	
	var ghostAnimButtons:FlxSpriteGroup;
	var frameSliders:Array<DoidoSlider> = [];
	
	function reloadGhostButtons()
	{
		ghostAnimButtons.clear();
	
		var ghostAnims = ghost.animList;
		for(i in 0...ghostAnims.length)
		{
			var animButton = new FlxButton(100, 30 + (20 * i), ghostAnims[i], function() {
				if(char.curChar == ghost.curChar)
					ghost.animOffsets = char.animOffsets;

				ghost.playAnim(ghostAnims[i], true);
				updateFrameSlider(1);
			});
			ghostAnimButtons.add(animButton);
			animButton.cameras = [camHUD];
		}
		if(frameSliders.length >= 2)
			updateFrameSlider(1);
	}

	function reloadChar(dude:Character, newChar:String = "bf", isGhost:Bool = false):Character
	{
		if(dude != null)
			charGrp.remove(dude);
		dude = new Character(newChar, false, true);
		charGrp.add(dude);
		if(isGhost)
			dude.alpha = 0.4;
		return dude;
	}
	
	function setCharPos(dude:Character)
	{
		dude.setPosition(FlxG.width * 0.8, FlxG.height * 1.5);
		dude.x -= dude.width / 2;
		dude.y -= dude.height;
		
		dude.x += dude.globalOffset.x;
		dude.y += dude.globalOffset.y;
		//dude.setPosition(0,0);
	}
	
	var changeInputX:FlxUIInputText;
	var changeInputY:FlxUIInputText;
	var checkCamFollow:FlxUICheckBox;

	override function create()
	{
		super.create();
		CoolUtil.playMusic('dialogue/lunchbox');
		Controls.setSoundKeys(true);
		FlxG.mouse.visible = true;
		var grid = FlxGridOverlay.create(32, 32, FlxG.width * 2, FlxG.height * 2);
		//grid.screenCenter();
		add(grid);
		
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
		camMain.followLerp = 1;

		add(charGrp);

		char = reloadChar(char, curChar);
		setCharPos(char);

		ghost = reloadChar(ghost, curChar, true);
		setCharPos(ghost);

		for(i in 0...2)
		{
			var sizes:Array<Int> = [32, 4];
			if(i == 0)
				sizes.reverse();
			var floorSpr = new FlxSprite(FlxG.width * 0.8, FlxG.height * 1.5);
			floorSpr.makeGraphic(sizes[0], sizes[1], 0xFFFF0000);
			add(floorSpr);
			floorSpr.x -= floorSpr.width / 2;
			floorSpr.y -= floorSpr.height / 2;
		}

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

		for(i in 0...2)
		{
			var frameSlider = new DoidoSlider(
				'${(i == 0) ? 'Character' : 'Ghost'} Frame Picker',
				6, animsHud.height - 120 + (60 * i), -1, -1, 10, 0
			);
			frameSlider.minLabel.text = "OFF";
			frameSliders.push(frameSlider);
			animTab.add(frameSlider);
			frameSlider.ID = i;
			frameSlider.onChange = function()
			{
				//Logs.print(i + ' ' + frameSlider.value);
				var charFrame:Character = ((i == 0) ? char : ghost);
				var isOff:Bool = (frameSlider.value < 0.0);
				frameSlider.valueLabel.alpha = (isOff ? 0.0 : 1.0);
				if(isOff)
					charFrame.playAnim(charFrame.curAnimName, true);
				else
				{
					charFrame.playAnim(charFrame.curAnimName, true, false, Math.floor(frameSlider.value));
					charFrame.pauseAnim();
				}
			}
			frameSlider.valueLabel.alpha = 0.0;
			frameSlider.cameras = [camHUD];
			for(item in frameSlider.members)
				item.cameras = [camHUD];
			frameSlider.scrollFactor.set();
			updateFrameSlider(i);
		}

		animTab.add(new FlxText(10, 10,0,"Character: "));
		animTab.add(new FlxText(100,10,0,"Ghost: "));
		
		ghostAnimButtons = new FlxSpriteGroup();
		ghostAnimButtons.cameras = [camHUD];
		animTab.add(ghostAnimButtons);

		var animList = char.animList;
		for(i in 0...animList.length)
		{
			var animButton = new FlxButton(10, 30 + (20 * i), animList[i], function() {
				char.playAnim(animList[i], true);
				updateFrameSlider(0);
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

		var charList = CharacterUtil.charList();

		var charButton = new FlxUIButton(10, 25, curChar, function() {
			openSubState(new ChooserSubState(charList, CHARACTER, function(pick:String) {
				Main.switchState(new CharacterEditorState(pick));
			}));
		});
		charButton.resize(125, 20);
		charButton.cameras = [camHUD];

		/*var charDropDown = new FlxUIDropDownMenu(10, 25, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			var choice = charList[Std.parseInt(character)];
			Main.switchState(new CharacterEditorState(choice));
		});
		charDropDown.selectedLabel = curChar;
		charDropDown.cameras = [camHUD];*/

		var checkFlipGhost = new FlxUICheckBox(140, 50, null, null, "Ghost FlipX", 100);
		var checkShowGhost = new FlxUICheckBox(140, 75, null, null, "Show Ghost", 100);
		var ghostButton = new FlxUIButton(140, 25, ghost.curChar, function() {
			openSubState(new ChooserSubState(charList, CHARACTER, function(pick:String) {
				ghost = reloadChar(ghost, pick, true);
				checkFlipGhost.callback();
				checkShowGhost.callback();
				reloadGhostButtons();
				setCharPos(ghost);
			}));
		});
		ghostButton.resize(125, 20);
		ghostButton.cameras = [camHUD];
		/*var ghostDropDown = new FlxUIDropDownMenu(140, 25, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(character:String)
		{
			ghost = reloadChar(ghost, charList[Std.parseInt(character)], true);
			checkFlipGhost.callback();
			checkShowGhost.callback();
			reloadGhostButtons();
			setCharPos(ghost);
		});
		ghostDropDown.selectedLabel = ghost.curChar;
		ghostDropDown.cameras = [camHUD];*/

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
		var thoseButtons:Array<String> = ["animation", "global", "camera"];
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
		charsTab.add(charButton);
		charsTab.add(new FlxText(140,10,0,"Ghost: "));
		charsTab.add(ghostButton);
	}

	function updateFrameSlider(i:Int = 0)
	{
		var slider = frameSliders[i];
		var daChar:Character = (i == 0 ? char : ghost);
		slider.maxValue = (!daChar.isAnimateAtlas ?
			daChar.animation.curAnim.numFrames :
			daChar.anim.curSymbol.length
		);
		slider.maxLabel.text = '${slider.maxValue}';
		resetSlider(slider, true);
	}
	function resetSlider(slider:DoidoSlider, force:Bool = false)
	{
		if(FlxG.keys.pressed.SHIFT && !force)
			return;
		
		slider.valueLabel.alpha = 0.0;
		@:privateAccess
			slider._value = -1;
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
									char.animOffsets.get(char.curAnimName)[0] = inputNum;
								else
									char.animOffsets.get(char.curAnimName)[1] = inputNum;
								char.playAnim(char.curAnimName, true);
								
								if(char.curAnimName == ghost.curAnimName
								&& char.curChar == ghost.curChar)
								{
									ghost.playAnim(char.curAnimName, true);
									ghost.animOffsets = char.animOffsets;
								}
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
			CoolUtil.playMusic();
			FlxG.mouse.visible = false;
			if(wasPlayState)
				Main.switchState(new LoadingState());
			else
				Main.switchState(new states.menu.MainMenuState());
		}
			
		if(FlxG.mouse.wheel != 0)
		{
			camZoom += (FlxG.mouse.wheel * 10 * elapsed);
			if(camZoom < 0.4)
				camZoom = 0.4;
			
			camMain.zoom = Math.floor(camZoom / 0.1) * 0.1;
			updateTxt();
		}
		
		// you can drag the camera
		if(FlxG.mouse.pressedMiddle)
		{
			if(FlxG.mouse.justPressedMiddle)
			{
				//camMain.followLerp = 1;
				checkCamFollow.checked = false;
				dragCam = [camFollow.x, camFollow.y, FlxG.mouse.x, FlxG.mouse.y];
			}
			camFollow.setPosition(
				dragCam[0] + (dragCam[2] - FlxG.mouse.x) * 0.8,
				dragCam[1] + (dragCam[3] - FlxG.mouse.y) * 0.8
			);
		}
		else // or just use the keyboard keys ig
		{
			if(FlxG.keys.anyJustPressed([I, J, K, L]))
			{
				//camMain.followLerp = 1;
				checkCamFollow.checked = false;
			}
			var speed:Float = elapsed * 400;
			if(FlxG.keys.pressed.J) camFollow.x -= speed;
			if(FlxG.keys.pressed.L) camFollow.x += speed;
			if(FlxG.keys.pressed.I) camFollow.y -= speed;
			if(FlxG.keys.pressed.K) camFollow.y += speed;
		}
		// follows the character
		if(checkCamFollow.checked)
		{
			//camMain.followLerp = elapsed * 3;
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
		if(FlxG.keys.justPressed.SPACE && selectedChange == "animation")
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
		} else if(Controls.pressed(CONTROL)) {
			x*=100;
			y*=100;
		}

		var isSpace:Bool = (x + y == 0);
		
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
				if(char.isPlayer)
					x *= -1;
				char.cameraOffset.x += x;
				char.cameraOffset.y += y;
		
			case "animation":
				char.animOffsets.get(char.curAnimName)[0] += -x;
				char.animOffsets.get(char.curAnimName)[1] += -y;
				if(isSpace)
					resetSlider(frameSliders[0]);
				if(frameSliders[0].value >= 0.0) {
					char.playAnim(char.curAnimName, true, false, Math.floor(frameSliders[0].value));
					char.pauseAnim();
				} else
					char.playAnim(char.curAnimName, true);
				
				if(char.curAnimName == ghost.curAnimName
				&& char.curChar == ghost.curChar)
				{
					ghost.animOffsets = char.animOffsets;
					if(isSpace)
						resetSlider(frameSliders[1]);
					if(frameSliders[1].value >= 0.0) {
						ghost.playAnim(char.curAnimName, true, false, Math.floor(frameSliders[1].value));
						ghost.pauseAnim();
					} else
						ghost.playAnim(char.curAnimName, true);
				}
		}
		updateInputTxt();
		
		updateTxt();
	}

	function updateTxt()
	{
		exportTxt.text = "";
		for(anim in char.animList)
		{
			if(!char.animOffsets.exists(anim))
				char.addOffset(anim);

			var offsets:Array<Float> = char.animOffsets.get(anim);

			exportTxt.text += '$anim ${offsets[0]} ${offsets[1]}\n';
		}
		exportTxt.text
		+='\nGlobal Offset: ${char.globalOffset.x} ${char.globalOffset.y}'
		+ '\nCamera Offset: ${char.cameraOffset.x} ${char.cameraOffset.y}'
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
				//Logs.print(char.curAnimName);
				var daAnim = char.animOffsets.get(char.curAnimName);
				
				changeInputX.text = Std.string(daAnim[0]);
				changeInputY.text = Std.string(daAnim[1]);
		}
	}

	function saveOffsets()
	{
		var exportData = CharacterUtil.defaultOffsets();
		
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