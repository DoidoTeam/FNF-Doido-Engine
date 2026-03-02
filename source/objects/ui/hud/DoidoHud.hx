package objects.ui.hud;

class DoidoHud extends BaseHud
{
    public function new()
    {
        super("doido");

        add(ratingGrp);
        
        scoreTxt = new FlxText(10, 0, 0, '');
		scoreTxt.setFormat(Main.globalFont, 18, 0xFFFFFFFF, CENTER);
		scoreTxt.setOutline(0xFF000000, 1.5);
		scoreTxt.antialiasing = false;
		add(scoreTxt);
    }

    override function popUpRating(ratingName:String = ""):RatingSprite
    {
        var rating = super.popUpRating(ratingName);
        
        rating.screenCenter();
        rating.defaultAnim();

        return rating;
    }

    override function popUpCombo(comboNum:Int):Array<ComboSprite>
    {
        var numberArray = super.popUpCombo(comboNum);
        
        for (number in numberArray)
        {
            number.y += 100;
            number.defaultAnim();
        }

        return numberArray;
    }

    override function updateScoreTxt()
    {
        scoreTxt.text = "";
        scoreTxt.text += 'Score: ' + FlxStringUtil.formatMoney(Timings.score, false, true) + separator;
		scoreTxt.text += 'Accuracy: ' + Timings.accuracy + "%" + ' [${Timings.getRank()}]' + separator;
		scoreTxt.text += 'Misses: ' + Timings.misses;

        scoreTxt.y = (playState.playField.bfStrumline.downscroll ? 50 : FlxG.height - scoreTxt.height - 50);
        scoreTxt.screenCenter(X);
        scoreTxt.floorPos();
    }
}