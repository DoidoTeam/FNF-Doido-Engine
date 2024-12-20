package objects.menu;

import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class DoidoSlider extends FlxSpriteGroup
{
    public var bar:FlxSprite;
    public var handle:FlxSprite;

    public var nameLabel:FlxText;
    public var minLabel:FlxText;
    public var maxLabel:FlxText;
    public var valueLabel:FlxText;

    public var onChange:Void->Void;

    private var _value(default, set):Float = 0.0;
    public var value:Float = 0;

    public var minValue:Float = 0;
    public var maxValue:Float = 10;
    public var decimals:Int = 1;

    public function new(name:String = "", x:Float, y:Float, startValue:Float = 0, minValue:Float = 0, maxValue:Float = 10, decimals:Int = 1)
    {
        super(x, y);
        this.minValue = minValue;
        this.maxValue = maxValue;
        this.decimals = decimals;
        _value = value = FlxMath.roundDecimal(startValue, decimals);

        bar = new FlxSprite(6, 0).makeGraphic(168, 8, 0xFFFFFFFF);
        add(bar);

        add(nameLabel   = new FlxText(6 + bar.width/2, -20, 0, name, 8));
        add(minLabel    = new FlxText(6,                16,  0, '$minValue', 8));
        add(maxLabel    = new FlxText(6 + bar.width,    16,  0, '$maxValue', 8));
        add(valueLabel  = new FlxText(6 + bar.width/2,  16,  0, '$value',    8));
        for(i in [nameLabel, minLabel, maxLabel, valueLabel])
            i.x -= i.width / 2;

        handle = new FlxSprite().loadGraphic(Paths.image('menu/sliderHandle'));
        handle.y = (bar.height - handle.height) / 2;
        handle.offset.x = handle.width / 2;
        add(handle);
    }
    
    public var isPressed:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.mouse.overlaps(bar, cameras[0]) && FlxG.mouse.justPressed)
            isPressed = true;
        if(FlxG.mouse.justReleased)
            isPressed = false;
        // moving the handle
        if(isPressed)
            handle.x = FlxG.mouse.getPositionInCameraView(cameras[0]).x;
        // capping the handle
        if(handle.x < bar.x)
            handle.x = bar.x;
        if(handle.x > bar.x + bar.width)
            handle.x = bar.x + bar.width;
        // updating the value
        if(isPressed)
            _value = FlxMath.remapToRange(handle.x, bar.x, bar.x + bar.width, minValue, maxValue);
        // instead of running on every frame, onChange() only runs when the rounded decimal updates
        if(value != FlxMath.roundDecimal(_value, decimals))
        {
            value = FlxMath.roundDecimal(_value, decimals);
            valueLabel.text = '$value';
            valueLabel.x = bar.x + (bar.width - valueLabel.width) / 2;
            //Logs.print('updated!! $value');
            if(onChange != null)
                onChange();
        }
    }

    public function set__value(v:Float):Float
    {
        _value = v;
        try {
            handle.x = FlxMath.remapToRange(_value, minValue, maxValue, bar.x, bar.x + bar.width);
        } catch(e) {
            // avoid crashing
        }
        return _value;
    }
}