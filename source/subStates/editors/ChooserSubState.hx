package subStates.editors;

import flixel.util.FlxColor;
import gameObjects.hud.note.Note;
import gameObjects.hud.HealthIcon;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import data.GameData.MusicBeatSubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

enum ChooserType{
    NONE;
    CHARACTER;
    EVENT;
    NOTETYPE;
}
class ChooserSubState extends MusicBeatSubState
{
    var options:Array<String> = [];
    var type:ChooserType = NONE;
    var sendTo:String->Void;

    var scrollY:Float = 0;
    var minScrollY:Float = 0;
    var maxScrollY:Float = 0;

    var cardsGrp:FlxTypedGroup<ChooserCard>;

    var searchBG:FlxSprite;
    var searchInput:FlxUIInputText;
    static var lastSearch:Map<ChooserType, String> = [
        NONE        => "",
        CHARACTER   => "",
        EVENT       => "",
        NOTETYPE    => "",
    ];

    public function new(options:Array<String>, type:ChooserType, sendTo:String->Void)
    {
        super();
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        this.options = options;
        this.type = type;
        this.sendTo = sendTo;
        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.alpha = 0.0001;
        add(bg);
        FlxTween.tween(bg, {alpha: 0.7}, 0.4);

        add(cardsGrp = new FlxTypedGroup<ChooserCard>());

        searchBG = new FlxSprite().makeGraphic(FlxG.width, 64, 0xFF000000);
        searchBG.alpha = 0.7;
        add(searchBG);

        var searchTxt = new FlxText(10, 15, 0,"Search: ", 24);
        searchTxt.setFormat(Main.gFont, 24, 0xFFFFFFFF, LEFT);
        add(searchTxt);

        searchInput = new FlxUIInputText(
            searchTxt.x + searchTxt.width, 15,
            Math.floor(FlxG.width - (searchTxt.x + searchTxt.width) - 20),
            lastSearch.get(type), 24
        );
		searchInput.name = "search_input";
		add(searchInput);
        
        for(item in members)
            if(Std.isOfType(item, FlxSprite))
                cast(item, FlxSprite).scrollFactor.set();
        reloadOptions();
    }

    function reloadOptions()
    {
        var daOptions:Array<String> = [];
        for(i in options)
            if(i.toLowerCase().contains(searchInput.text.toLowerCase()))
                daOptions.push(i);

        cardsGrp.clear();

        for(i in 0...daOptions.length)
        {
            var card = new ChooserCard(daOptions[i], type, i);
            card.x = 10 + ((20 + 140) * (i % 8));
            card.yTo = Math.floor(i / 8) * (10 + 140);
            cardsGrp.add(card);
            if(i == 0)
                minScrollY = card.yTo;
            if(i == daOptions.length - 1)
                maxScrollY = card.yTo;

            for(item in card.members)
                item.scrollFactor.set();
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        Controls.setSoundKeys(searchInput.hasFocus);
        // cancel
        if(FlxG.keys.justPressed.ESCAPE)
            close();

        scrollY -= FlxG.mouse.wheel * 20;
        scrollY = FlxMath.lerp(
            scrollY,
            FlxMath.bound(scrollY, minScrollY, maxScrollY),
            elapsed * 12
        );

        for(card in cardsGrp.members)
        {
            card.y = FlxMath.lerp(card.y, 74 + card.yTo - scrollY, elapsed * 12);
            if(!FlxG.mouse.overlaps(searchBG, cameras[0]))
                card.hovered = FlxG.mouse.overlaps(card, cameras[0]);
            else
                card.hovered = false;

            if(card.hovered)
            {
                card.bg.color = 0xFF777777;
                if(FlxG.mouse.justPressed)
                {
                    if(sendTo != null)
                        sendTo(card.text.text);
                    close();
                }
            }
            else
                card.bg.color = 0xFFFFFFFF;
        }
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        switch(id)
        {
            case FlxUIInputText.CHANGE_EVENT:
				var input:FlxUIInputText = cast sender;
				switch(input.name)
				{
					case 'search_input':
                        lastSearch.set(type, input.text);
                        reloadOptions();
				}
        }
    }
}
class ChooserCard extends FlxSpriteGroup
{
    public var bg:FlxSprite;
    public var icon:FlxSprite;
    public var text:FlxText;

    public var yTo:Float = 0;

    public var hovered:Bool = false;

    public function new(name:String, type:ChooserType, gradID:Int)
    {
        super();
        bg = new FlxSprite().makeGraphic(140, 140,
            FlxColor.interpolate(0xFFFC6060, 0xFF9440E2, (gradID % 8) / 8)
        );
        add(bg);

        icon = new FlxSprite();
        switch(type)
        {
            case CHARACTER:
                var uhhh = new HealthIcon();
                uhhh.setIcon(name, false);
                icon.loadGraphicFromSprite(uhhh);

            case EVENT:
                var eventName:String = name.toLowerCase().replace(' ', '_');

                if(!Paths.fileExists('images/notes/events/$eventName.png'))
                    eventName = "unknown_event";

                icon.loadGraphic(Paths.image('notes/events/$eventName'));

            case NOTETYPE:
                var note = new Note();
                note.updateData(0, FlxG.random.int(0, 3), name, "base");
                note.reloadSprite();
                icon.loadGraphicFromSprite(note);

            default: icon.visible = false; // leave it without a icon ig
        }
        icon.setGraphicSize(100, 100);
        icon.updateHitbox();
        icon.x = bg.x + (bg.width - icon.width) / 2;
        icon.y = bg.y + 10;
        add(icon);

        text = new FlxText(10, 15, bg.width, name, 8);
        text.setFormat(Main.gFont, 16, 0xFFFFFFFF, CENTER);
        text.setBorderStyle(OUTLINE, 0xFF000000, 1.5);
        text.x = bg.x + (bg.width - text.width) / 2;
        text.y = bg.y + bg.height - text.height - 8;
        add(text);
    }
}