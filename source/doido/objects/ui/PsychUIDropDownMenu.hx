package doido.objects.ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import doido.objects.ui.buttons.DoidoAnimatedButton;
import doido.utils.EditorUtil;

/*
 *
 * Code adapted from FNF: Psych Engine, with permission.
 * https://github.com/ShadowMario/FNF-PsychEngine
 *
 */
class PsychUIDropDownMenu extends PsychUIInputText
{
	public static final CLICK_EVENT = "dropdown_click";

	public var list(default, set):Array<String> = [];
	public var button:FlxSprite;
	public var onSelect:Int->String->Void;

	public var selectedIndex(default, set):Int = -1;
	public var selectedLabel(default, set):String = null;

	public var up:Bool = false;

	var _curFilter:Array<String>;
	var _itemWidth:Float = 0;
	var bgHeight:Float;

	var bgX:Float = 0;
	var bgY:Float = 0;

	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Int = 100, ?up:Bool = false)
	{
		super(x, y, width, "", 14);
		this.up = up;

		if (list == null)
			list = [];

		_itemWidth = width;
		bgHeight = bg.height;

		var ups:String = (up ? "up" : "down");
		button = new DoidoAnimatedButton('editors/charting/drop$ups', 'buttondrop$ups');
		button.x = bg.width - button.width;
		button.y = -1;
		button.zIndex = 10;
		add(button);

		fieldWidth -= Std.int(button.width);

		onSelect = callback;

		onChange.add((old, cur, btn) ->
		{
			if (old != cur)
			{
				_curFilter = EditorUtil.doidoSearch(list, cur);
				showDropDown(true, 0, _curFilter);
			}
		});

		unfocus = function()
		{
			showDropDownClickFix();
			showDropDown(false);
		}

		for (option in list)
			addOption(option);

		sort(ZIndex.sort);
		bgX = bg.x;
		bgY = bg.y;

		selectedIndex = 0;
		showDropDown(false);
	}

	function set_selectedIndex(v:Int)
	{
		selectedIndex = v;
		if (selectedIndex < 0 || selectedIndex >= list.length)
			selectedIndex = -1;

		@:bypassAccessor selectedLabel = list[selectedIndex];
		text = (selectedLabel != null) ? selectedLabel : '';
		return selectedIndex;
	}

	function set_selectedLabel(v:String)
	{
		var id:Int = list.indexOf(v);
		if (id >= 0)
		{
			@:bypassAccessor selectedIndex = id;
			selectedLabel = v;
			text = selectedLabel;
		}
		else
		{
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
			text = '';
		}
		return selectedLabel;
	}

	var _items:Array<PsychUIDropDownItem> = [];

	public var curScroll:Int = 0;

	override function update(elapsed:Float)
	{
		var lastFocus = PsychUIInputText.focusOn;
		super.update(elapsed);
		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(button, camera))
			{
				if (lastFocus != this)
					PsychUIInputText.focusOn = this;
				else if (PsychUIInputText.focusOn == this)
					PsychUIInputText.focusOn = null;
			}
		}

		if (lastFocus != PsychUIInputText.focusOn)
		{
			showDropDown(PsychUIInputText.focusOn == this);
		}
		else if (PsychUIInputText.focusOn == this)
		{
			var wheel:Int = FlxG.mouse.wheel;
			if (FlxG.keys.justPressed.UP)
				wheel++;
			if (FlxG.keys.justPressed.DOWN)
				wheel--;
			if (wheel != 0)
				showDropDown(true, curScroll - wheel, _curFilter);
		}
	}

	private function showDropDownClickFix()
	{
		if (FlxG.mouse.justPressed)
		{
			for (item in _items) // extra update to fix a little bug where it wouldnt click on any option if another input text was behind the drop down
				if (item != null && item.active && item.visible)
					item.update(0);
		}
	}

	public function showDropDown(vis:Bool = true, scroll:Int = 0, onlyAllowed:Array<String> = null)
	{
		if (!vis)
		{
			text = selectedLabel;
			_curFilter = null;
		}

		curScroll = Std.int(Math.max(0, Math.min(onlyAllowed != null ? (onlyAllowed.length - 1) : (list.length - 1), scroll)));
		if (vis)
		{
			var n:Int = 0;
			for (item in _items)
			{
				if (onlyAllowed != null)
				{
					if (onlyAllowed.contains(item.label))
					{
						item.active = item.visible = (n >= curScroll);
						n++;
					}
					else
						item.active = item.visible = false;
				}
				else
				{
					item.active = item.visible = (n >= curScroll);
					n++;
				}
			}

			if (up)
			{
				var txtY:Float = behindText.y - 3;
				var itemCount:Int = 0;
				for (num => item in _items)
				{
					if (!item.visible)
						continue;
					txtY -= item.height;
					item.x = behindText.x;
					item.y = txtY;
					item.forceNextUpdate = true;
					itemCount++;
				}
				bg.y = txtY - 3;
				bg.scale.y = (behindText.y + behindText.height) - txtY + 3;
				if (itemCount > 0)
					bg.scale.y += 3;
				bg.updateHitbox();
			}
			else
			{
				var txtY:Float = behindText.y + behindText.height + 3;
				var itemCount:Int = 0;
				for (num => item in _items)
				{
					if (!item.visible)
						continue;
					item.x = behindText.x;
					item.y = txtY;
					txtY += item.height;
					item.forceNextUpdate = true;
					itemCount++;
				}
				bg.scale.y = txtY - behindText.y + 3;
				if (itemCount > 0)
					bg.scale.y += 3;
				bg.updateHitbox();
			}
		}
		else
		{
			for (item in _items)
				item.active = item.visible = false;

			bg.x = bgX;
			bg.y = bgY;
			bg.scale.y = bgHeight;
			bg.updateHitbox();
		}
	}

	function clickedOn(num:Int, label:String)
	{
		selectedIndex = num;
		showDropDown(false);
		if (onSelect != null)
			onSelect(num, label);
	}

	function addOption(option:String)
	{
		@:bypassAccessor list.push(option);
		var curID:Int = list.length - 1;
		var item:PsychUIDropDownItem = cast recycle(PsychUIDropDownItem, () -> new PsychUIDropDownItem(1, 1, this._itemWidth, curID % 2 != (up ? 1 : 0)), true);
		item.cameras = cameras;
		item.label = option;
		item.visible = item.active = false;
		item.onClick = function() clickedOn(curID, option);
		item.forceNextUpdate = true;
		_items.push(item);
		insert(1, item);
	}

	function set_list(v:Array<String>)
	{
		var selected:String = selectedLabel;
		showDropDown(false);

		for (item in _items)
			item.kill();

		_items = [];
		list = [];
		for (option in v)
			addOption(option);

		sort(ZIndex.sort);

		if (selectedLabel != null)
			selectedLabel = selected;
		return v;
	}
}

class PsychUIDropDownItem extends FlxSpriteGroup
{
	public var hoverBg:FlxColor = 0xFF0066FF;
	public var hoverText:FlxColor = FlxColor.WHITE;

	public var normalBg:FlxColor = 0xFFEBEFFE;
	public var oddBg:FlxColor = 0xFFD7D9F6;
	public var normalText:FlxColor = FlxColor.BLACK;

	public var bg:FlxSprite;
	public var text:FlxText;

	var isOdd:Bool = false;

	public function new(x:Float = 0, y:Float = 0, width:Float = 100, isOdd:Bool = false)
	{
		super(x, y);
		this.isOdd = isOdd;

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.setGraphicSize(width - 6, 20);
		bg.updateHitbox();
		add(bg);

		text = new FlxText(0, 0, width, 14);
		text.font = Assets.font("phantommuff");
		text.color = FlxColor.BLACK;
		add(text);
	}

	public var onClick:Void->Void;
	public var forceNextUpdate:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed || forceNextUpdate)
		{
			var overlapped:Bool = (FlxG.mouse.overlaps(bg, camera));

			bg.color = overlapped ? hoverBg : (isOdd ? oddBg : normalBg);
			text.color = overlapped ? hoverText : normalText;
			bg.alpha = 1;
			forceNextUpdate = false;

			if (overlapped && FlxG.mouse.justPressed)
				onClick();
		}

		text.x = bg.x;
		text.y = bg.y + bg.height / 2 - text.height / 2;
	}

	public var label(default, set):String;

	function set_label(v:String)
	{
		label = v;
		text.text = v;
		bg.scale.y = text.height + 2;
		bg.updateHitbox();
		return v;
	}
}
