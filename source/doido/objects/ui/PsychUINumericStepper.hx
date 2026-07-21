package doido.objects.ui;

import doido.objects.ui.buttons.DoidoAnimatedButton;
import flixel.FlxSprite;
import flixel.math.FlxMath;

/*
 *
 * Code adapted from FNF: Psych Engine, with permission.
 * https://github.com/ShadowMario/FNF-PsychEngine
 *
 */
class PsychUINumericStepper extends PsychUIInputText
{
	public static final CHANGE_EVENT = "numericstepper_change";

	public var step:Float = 0;
	public var defValue:Float = 0;
	public var min(default, set):Float = 0;
	public var max(default, set):Float = 0;
	public var decimals(default, set):Int = 0;
	public var isPercent(default, set):Bool = false;
	public var buttonPlus:DoidoAnimatedButton;
	public var buttonMinus:DoidoAnimatedButton;
	public var buttonReset:DoidoAnimatedButton;

	public var onValueChange:Void->Void;
	public var onValueStep:Float->Void;
	public var value(default, set):Float;

	public var disableSteppers:Bool = false;

	public function new(x:Float = 0, y:Float = 0, step:Float = 1, defValue:Float = 0, min:Float = -999, max:Float = 999, decimals:Int = 0, ?wid:Int = 100, ?isPercent:Bool = false, ?hasReset:Bool = false)
	{
		super(x, y, wid - 54, '', 14);
		@:bypassAccessor this.decimals = decimals;
		@:bypassAccessor this.isPercent = isPercent;
		@:bypassAccessor this.min = min;
		@:bypassAccessor this.max = max;
		this.step = step;
		this.defValue = defValue;
		_updateFilter();

		buttonPlus = new DoidoAnimatedButton("editors/charting/plus", "buttonplus", () -> stepValue(1));
		add(buttonPlus);

		buttonMinus = new DoidoAnimatedButton("editors/charting/minus", "buttonminus", () -> stepValue(-1));
		add(buttonMinus);

		if (hasReset)
		{
			buttonReset = new DoidoAnimatedButton("editors/charting/reset", "buttonreset", () -> resetValue());
			add(buttonReset);
		}

		positionButtons();

		unfocus = function()
		{
			_updateValue();
			_internalOnChange();
		}
		value = defValue;
	}

	final buttonSpacing:Float = 1;

	function positionButtons()
	{
		var wid = behindText.width;
		buttonPlus.x = x + wid + 8;
		buttonPlus.y = y - 1;
		buttonMinus.x = buttonPlus.x + buttonPlus.width + buttonSpacing;
		buttonMinus.y = buttonPlus.y;
		if (buttonReset != null)
		{
			buttonReset.x = buttonMinus.x + buttonMinus.width + buttonSpacing;
			buttonReset.y = buttonPlus.y;
		}
	}

	function resetValue()
	{
		value = defValue;
		_internalOnChange();
	}

	function stepValue(mult:Int = 0)
	{
		value += (step * mult);
		if (onValueStep != null)
			onValueStep(step * mult);
		_internalOnChange();
	}

	function set_value(v:Float)
	{
		value = Math.max(min, Math.min(max, v));
		text = Std.string(isPercent ? (value * 100) : value);

		buttonPlus.disabled = disableSteppers && (disableInput || value >= max);
		buttonMinus.disabled = disableSteppers && (disableInput || value <= min);
		if (buttonReset != null)
			buttonReset.disabled = disableSteppers && !disableInput && value == defValue;

		_updateValue();
		return value;
	}

	function set_min(v:Float)
	{
		min = v;
		@:bypassAccessor if (min > max)
			max = min;
		_updateFilter();
		_updateValue();
		return min;
	}

	function set_max(v:Float)
	{
		max = v;
		@:bypassAccessor if (max < min)
			min = max;
		_updateFilter();
		_updateValue();
		return max;
	}

	function set_decimals(v:Int)
	{
		decimals = v;
		_updateFilter();
		return decimals;
	}

	function set_isPercent(v:Bool)
	{
		var changed:Bool = (isPercent != v);
		isPercent = v;
		_updateFilter();

		if (changed)
		{
			text = Std.string(value * 100);
			_updateValue();
		}
		return isPercent;
	}

	function _updateValue()
	{
		var txt:String = text.replace('%', '');
		if (txt.indexOf('-') > 0)
			txt.replace('-', '');

		while (txt.indexOf('.') > -1 && txt.indexOf('.') != txt.lastIndexOf('.'))
		{
			var lastId = txt.lastIndexOf('.');
			txt = txt.substr(0, lastId) + txt.substring(lastId + 1);
		}

		var val:Float = Std.parseFloat(txt);
		if (Math.isNaN(val))
			val = 0;

		if (isPercent)
			val /= 100;

		if (val < min)
			val = min;
		else if (val > max)
			val = max;
		val = FlxMath.roundDecimal(val, decimals);
		@:bypassAccessor value = val;

		if (isPercent)
		{
			text = Std.string(val * 100);
			text += '%';
		}
		else
			text = Std.string(val);

		if (caretIndex > text.length)
			caretIndex = text.length;
		if (selectIndex > text.length)
			selectIndex = text.length;
	}

	function _updateFilter()
	{
		if (min < 0)
		{
			if (decimals > 0)
			{
				if (isPercent)
					customFilterPattern = ~/[^0-9.%\-]*/g;
				else
					customFilterPattern = ~/[^0-9.\-]*/g;
			}
			else
			{
				if (isPercent)
					customFilterPattern = ~/[^0-9%\-]*/g;
				else
					customFilterPattern = ~/[^0-9\-]*/g;
			}
		}
		else
		{
			if (decimals > 0)
			{
				if (isPercent)
					customFilterPattern = ~/[^0-9.%]*/g;
				else
					customFilterPattern = ~/[^0-9.]*/g;
			}
			else
			{
				if (isPercent)
					customFilterPattern = ~/[^0-9%]*/g;
				else
					customFilterPattern = ~/[^0-9]*/g;
			}
		}
	}

	function _internalOnChange()
	{
		if (onValueChange != null)
			onValueChange();
	}
}
