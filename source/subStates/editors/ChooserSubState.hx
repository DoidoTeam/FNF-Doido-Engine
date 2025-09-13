package subStates.editors;

import flixel.FlxSprite;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUISubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import objects.note.EventNote;
import objects.note.Note;
import objects.hud.HealthIcon;

enum ChooserType{
    NONE;
    CHARACTER;
    EVENT;
    NOTETYPE;
}
class ChooserSubState extends FlxUISubState
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

    var chooseAlready:Bool = false;

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
        var daOptions:Array<Array<String>> = [];
        for(i in options)
            if(i.toLowerCase().contains(searchInput.text.toLowerCase()))
                daOptions.push([i, "false"]);

        if(searchInput.text != "") {
            var addCustom:Bool = true;
            for(i in options)
                if(i.toLowerCase() == searchInput.text.toLowerCase()) {
                    addCustom = false;
                    break;
                }

        
            if(addCustom)
                daOptions.push([searchInput.text, "true"]);
        }

        cardsGrp.clear();

        for(i in 0...daOptions.length)
        {
            var card = new ChooserCard(daOptions[i][0], type, i, daOptions[i][1] == "true");
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
        if(!chooseAlready)
        {
            if(FlxG.keys.justPressed.ESCAPE && !searchInput.hasFocus)
            {
                chooseAlready = true;
                new FlxTimer().start(0.05, function(tmr) {
                    close();
                });
                return;
            }
            
            scrollY -= FlxG.mouse.wheel * 5000 * elapsed;
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
                        chooseAlready = true;
                        new FlxTimer().start(0.05, function(tmr) {
                            if(sendTo != null)
                                sendTo(card.text.text);
                            close();
                        });
                    }
                }
                else
                    card.bg.color = 0xFFFFFFFF;
            }
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

    public function new(name:String, type:ChooserType, gradID:Int, searched:Bool = false)
    {
        super();
        bg = new FlxSprite().makeGraphic(140, 140,
            FlxColor.interpolate(0xFFFC6060, 0xFF9440E2, (gradID % 8) / 8)
        );
        add(bg);

        var graphicName:String = (searched && type == NOTETYPE) ? "Event Note" : name;

        if(graphicName == "Event Note")
            type = EVENT;

        icon = new FlxSprite();
        switch(type)
        {
            case CHARACTER:
                var uhhh = new HealthIcon();
                uhhh.setIcon(graphicName, false);
                icon.loadGraphicFromSprite(uhhh);

            case EVENT:
                icon.loadGraphic(Paths.image(EventNote.getEventSprite(graphicName)));

            case NOTETYPE:
                var note = new Note();
                note.updateData(0, FlxG.random.int(0, 3), graphicName, "base");
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