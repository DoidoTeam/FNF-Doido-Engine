package gameObjects.menu.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

class OptionSelector extends FlxTypedGroup<FlxSprite>
{
    public var arrowL:FlxSprite;
    public var text:Alphabet;
    public var arrowR:FlxSprite;

    public var holdTimer:Float = 0;

    public var label:String = '';
    public var value:Dynamic;
    public var options:Array<Dynamic> = [];

    public function new(label:String, ?isSaveData:Bool = true)
    {
        super();
        this.label = label;
        if(isSaveData)
        {
            this.value = SaveData.data.get(label);
            this.options = SaveData.displaySettings.get(label)[3];
        }
        else
            this.value = label;

        arrowL = getArrow('left');
        arrowR = getArrow('right');

        text = new Alphabet(0, 0, value, true);
        text.scale.set(0.75,0.75);
        text.updateHitbox();

        add(arrowL);
        add(text);
        add(arrowR);
        setX(0);
    }

    private function getArrow(direc:String = 'left'):FlxSprite
    {
        var arrow = new FlxSprite();
        arrow.frames = Paths.getSparrowAtlas("menu/menuArrows");
		arrow.animation.addByPrefix("idle", 'arrow $direc', 0, false);
		arrow.animation.addByPrefix("push", 'arrow push $direc', 0, false);
		arrow.scale.set(0.6,0.6); arrow.updateHitbox();
		arrow.animation.play("idle");
        return arrow;
    }

    public function changeSelection(change:Int = 0):Void
    {
        if(Std.isOfType(options[0], Int))
        {
            value += change;
            value = FlxMath.wrap(value, options[0], options[1]);
        }
        else
        {
            var curSelected = options.indexOf(value);
            curSelected += change;
            curSelected = FlxMath.wrap(curSelected, 0, options.length - 1);
            value = options[curSelected];
        }
        var oldWidth = getWidth();
        text.text = Std.string(value);
        text.updateHitbox();
        setX(arrowL.x);
        setX(arrowL.x + oldWidth - getWidth());
    }

    public function setX(x:Float):Void
    {
        arrowL.x = x;
        text.x = arrowL.x + arrowL.width;
        arrowR.x = text.x + text.width;
    }
    public function setY(y:Float):Void
    {
        for(item in [arrowL, text, arrowR])
            item.y = y - (item.height / 2);
    }

    public function getWidth():Float
        return (arrowR.x + arrowR.width - arrowL.x);
}