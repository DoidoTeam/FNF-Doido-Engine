package objects.ui.hud;

class BaseHud extends FlxGroup
{
    public var playState:PlayState;
    public var hudName:String = "base";

    public var separator:String = " | ";
    public var scoreTxt:FlxText;

    public var ratingGrp:FlxGroup;

    public function new(hudName:String) {
        super();
        this.hudName = hudName;
        ratingGrp = new FlxGroup();
    }

    public function init()
    {
        updateScoreTxt();
    }

    public function updateScoreTxt() {}

    var ratingCount:Int = 0;
    public function popUpRating(ratingName:String = ""):RatingSprite
    {
        var rating:RatingSprite = cast ratingGrp.recycle(RatingSprite);
        rating.setUp(ratingName);

        if (!ratingGrp.members.contains(rating)) ratingGrp.add(rating);

        rating.setZ(ratingCount);
        ratingCount++;
        ratingGrp.members.sort(ZIndex.sortAscending);
        return rating;
    }

    var comboCount:Int = 0;
    public function popUpCombo(comboNum:Int):Array<ComboSprite>
    {
        var comboStr:String = '${Math.abs(comboNum)}'.lpad("0", 3);
        if (comboNum < 0) comboStr = '-$comboStr';
        var stringArr = comboStr.split("");

        var numberArray:Array<ComboSprite> = [];
        for(i in 0...stringArr.length)
        {
            var number:ComboSprite = cast ratingGrp.recycle(ComboSprite);
            number.setUp(stringArr[i]);

            if (comboNum <= 0)
                number.color = number.badColor;

            if (!ratingGrp.members.contains(number)) ratingGrp.add(number);

            number.setZ(comboCount);
            numberArray.push(number);
        }

        // ordering the numbers
        var numWidth:Float = numberArray[0].width - 8;
        for (i in 0...numberArray.length)
        {
            var number = numberArray[i];
			
            number.screenCenter();
			number.x += numWidth * i;
			number.x -= (numWidth * (numberArray.length - 1)) / 2;
        }

        comboCount++;
        ratingGrp.members.sort(ZIndex.sortAscending);
        return numberArray;
    }
}