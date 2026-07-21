package substates.editors;

import doido.objects.ui.PsychUIInputText;
import flixel.text.FlxBitmapText;
import doido.objects.ui.buttons.DoidoTextButton;
import states.editors.CharacterEditor.Hitbox;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import objects.ui.HealthIcon;
import flixel.util.FlxColor;

class IconEditorSubState extends PopupSubState
{
	var iconSheet:IconSheet;

	public function new(char:String)
	{
		super("!! WORK IN PROGRESS !!", 500, 350, []);

		var uhhh = new HealthIcon();
		uhhh.setIcon(char, false);

		iconSheet = new IconSheet(uhhh.graphic, uhhh.gridFrames);
		iconSheet.scale.set(uhhh.scale.x, uhhh.scale.y);
		iconSheet.updateHitbox();
		iconSheet.antialiasing = uhhh.antialiasing;
		iconSheet.screenCenter();
		iconSheet.y -= 50;
		iconSheet.color = uhhh.barColor;
		add(iconSheet);

		var stuffY = (FlxG.height / 2) - 22 - 5;

		/*add(createText((FlxG.width / 2) - (145) - 5, stuffY, "Image:", 0xFFD8DAF6));
			add(createText((FlxG.width / 2) + 5, stuffY, "Color:", 0xFFD8DAF6));

			var songField:PsychUIInputText;
			songField = new PsychUIInputText((FlxG.width / 2) - (145) - 5, stuffY, 145, "", 14);
			songField.onChange.add((old, cur, input) -> {});
			add(songField);

			var diffField:PsychUIInputText;
			diffField = new PsychUIInputText((FlxG.width / 2) + 5, stuffY, 145, "", 14);
			diffField.onChange.add((old, cur, input) -> {});
			add(diffField);
		 */

		var ok = new DoidoTextButton("Open", "small");
		ok.screenCenter();
		ok.x -= (ok.width / 2) + 5;
		ok.y += 152;
		add(ok);

		var reload = new DoidoTextButton("Save", "small");
		reload.screenCenter();
		reload.x += (reload.width / 2) + 5;
		reload.y += 152;
		add(reload);
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
}

class IconSheet extends FlxSprite
{
	public var gridWidth(default, set):Int;
	public var gridFrames(default, set):Int;
	public var boxes:FlxTypedGroup<Hitbox>;

	public function new(graphic:FlxGraphic, frames:Int)
	{
		super();
		boxes = new FlxTypedGroup<Hitbox>();
		reload(graphic, frames);
	}

	public function reload(graphic:FlxGraphic, frames:Int)
	{
		loadGraphic(graphic);
		gridFrames = frames;
	}

	override function draw()
	{
		super.draw();

		boxes.killMembers();

		for (i in 0...gridFrames)
		{
			var box:Hitbox = boxes.recycle(Hitbox);
			box.setGraphicSize(gridWidth * scale.x, graphic.height * scale.y);
			box.updateHitbox();
			box.setPosition(x + ((gridWidth * scale.x) * i), y);
			box.lineColor = color;
			boxes.add(box);
		}

		boxes.draw();
	}

	public function set_gridWidth(i:Int)
	{
		gridWidth = i;
		@:bypassAccessor gridFrames = Math.floor(graphic.width / i);
		return gridWidth;
	}

	public function set_gridFrames(i:Int)
	{
		gridFrames = i;
		@:bypassAccessor gridWidth = Math.floor(graphic.width / i);
		return gridFrames;
	}
}
