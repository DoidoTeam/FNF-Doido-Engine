package objects.ui.hud;

import objects.ui.Rating.RatingSprite;
import objects.ui.Rating.ComboSprite;

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
    public function addRating(ratingName:String = "")
    {
        var rating:RatingSprite = cast ratingGrp.recycle(RatingSprite);
        rating.setUp();

        rating.playAnim(ratingName);

        if (ratingGrp.members.contains(rating)) ratingGrp.remove(rating);
        ratingGrp.add(rating);

        rating.setZ(ratingCount);
        ratingCount++;
        ratingGrp.members.sort(ZIndex.sortAscending);
    }
    //public function addCombo() {}
}