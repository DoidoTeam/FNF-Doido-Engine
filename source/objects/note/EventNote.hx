package objects.note;

import flixel.FlxSprite;

class EventNote extends Note
{
    public var eventName:String = '';
    public var value1:String = '';
    public var value2:String = '';
    public var value3:String = '';

    public function new()
    {
        super();
    }

    override public function reloadSprite():Note
    {
        loadGraphic(Paths.image('notes/_other/events/event_note'));
        return this;
    }

    public var eventDataStuff:Array<String>  = [];
    public var eventSprites:Array<FlxSprite> = [];

    public function reloadSprites()
    {
        for(spr in eventSprites)
            spr.destroy();

        eventSprites = [];
        for(name in eventDataStuff)
        {
            var icon = new FlxSprite();
            icon.loadGraphic(Paths.image(EventNote.getEventSprite(name)));
            icon.setGraphicSize(width + 10, height + 10);
            icon.updateHitbox();
            eventSprites.push(icon);
        }
    }

    override function draw() {
        super.draw();
        if(eventSprites.length > 0)
        {
            var lastSpr:FlxSprite = this;
            for(icon in eventSprites)
            {
                var daOffset:Float = 0;
                if(lastSpr != this)
                {
                    if(eventSprites.length > 9)
                        daOffset += 16;
                    if(eventSprites.length > 13)
                        daOffset += 14;
                }
                icon.x = lastSpr.x + lastSpr.width - daOffset;
                icon.y = this.y + (this.height - icon.height) / 2;
                icon.draw();
                lastSpr = icon;
            }
        }
    }

    // funny
    public static function getEventSprite(name:String):String
    {
        var eventName:String = name.toLowerCase().replace(' ', '_');

        if(!Paths.fileExists('images/notes/_other/events/$eventName.png'))
            eventName = "unknown_event";

        return 'notes/_other/events/$eventName';
    }
}