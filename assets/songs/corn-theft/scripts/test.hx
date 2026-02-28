import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.ui.PlayField;

function create() {
    trace("script test");
}

function update(elapsed:Float) {
    if(PlayField.modchartAllowed) {
        for(strumline in playField.strumlines)
        {
            for(strum in strumline.strums)
            {
                if (FlxG.keys.justPressed.NINE)
                {
                    FlxTween.completeTweensOf(strum);
                    var downMult:Int = (strumline.downscroll ? -1 : 1);
                    var angle:Float = [13, 5.2, -5.2, -13][strum.lane];
                    if (strum.strumAngle == angle) angle = 0;

                    FlxTween.tween(
                        strum, {
                            strumAngle: angle,
                            angle: angle * -downMult,
                            y: strum.initialPos.y + ((angle == 0) ? 0 : [12, 0, 0, 12][strum.lane]) * downMult,
                        },
                        0.4, { ease: FlxEase.cubeInOut }
                    );
                }
            }
            for(note in strumline.notes)
            {
                if (!note.isHold)
                    note.angle = strumline.strums[note.data.lane].angle;
            }
        }
    }
}