package objects.menu;

import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class DoidoSlider extends FlxSpriteGroup
{
    public var bar:FlxSprite;
    public var hitbox:FlxSprite;
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

        hitbox = new FlxSprite(6, 0).makeGraphic(168, 8, 0xFFFFFFFF);
        hitbox.alpha = 0;
        add(hitbox);

        bar = new FlxSprite(6,2).makeGraphic(168, 4, 0xFFFFFFFF);
        add(bar);

        add(nameLabel   = new FlxText(6 + hitbox.width/2, -20, 0, name, 8));
        add(minLabel    = new FlxText(6,                16,  0, '$minValue', 8));
        add(maxLabel    = new FlxText(6 + hitbox.width,    16,  0, '$maxValue', 8));
        add(valueLabel  = new FlxText(6 + hitbox.width/2,  16,  0, '$value',    8));
        valueLabel.color = 0xFF000000;
        for(i in [nameLabel, minLabel, maxLabel, valueLabel])
            i.x -= i.width / 2;

        handle = new FlxSprite().loadGraphic(Paths.image('menu/sliderHandle'));
        handle.y = (hitbox.height - handle.height) / 2;
        handle.offset.x = handle.width / 2;
        add(handle);
    }
    
    public var isPressed:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(FlxG.mouse.justPressed)
            if(FlxG.mouse.overlaps(hitbox, cameras[0])
            || FlxG.mouse.overlaps(handle, cameras[0]))
                isPressed = true;
        
        if(FlxG.mouse.justReleased)
            isPressed = false;

        // moving the handle
        if(isPressed)
        {
            var handleX:Float = #if (flixel >= "5.9.0")
            FlxG.mouse.getViewPosition(cameras[0]).x; #else
            FlxG.mouse.getPositionInCameraView(cameras[0]).x; #end
            handle.x = handleX;
        }
        
        // capping the handle
        handle.x = FlxMath.bound(handle.x, hitbox.x, hitbox.x + hitbox.width);

        // updating the value
        if(isPressed)
            _value = FlxMath.remapToRange(handle.x, hitbox.x, hitbox.x + hitbox.width, minValue, maxValue);

        // instead of running on every frame, onChange() only runs when the rounded decimal updates
        if(value != FlxMath.roundDecimal(_value, decimals))
        {
            value = FlxMath.roundDecimal(_value, decimals);
            valueLabel.text = '$value';
            valueLabel.x = hitbox.x + (hitbox.width - valueLabel.width) / 2;
            if(onChange != null)
                onChange();
        }
    }

    public function set__value(v:Float):Float
    {
        _value = v;
        try {
            handle.x = FlxMath.remapToRange(_value, minValue, maxValue, hitbox.x, hitbox.x + hitbox.width);
        } catch(e) {}
        
        return _value;
    }
}