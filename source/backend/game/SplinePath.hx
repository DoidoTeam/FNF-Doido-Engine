package backend.game;

import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.FlxG;
import flixel.util.FlxColor;

class SplinePath //extends BasePath
{
	public var percent:Float = 0.0;
    public var points:Array<FlxPoint>;
	
    public function new(?points:Array<FlxPoint>)
    {
        this.points = (points ?? []);
    }

    public function add(x:Float, y:Float):Void
    {
        points.push(FlxPoint.get(x, y));
    }

    public function getPosition(?percent:Float):FlxPoint
    {
		if (percent == null) percent = this.percent;
		
        var count = points.length;
		if (count == 0)
			return new FlxPoint();
		if (count == 1)
			return points[0].clone();

		if (percent > 1)
		{
			var extra = percent - 1;
			var endPos = getPosition(1);
			var dir = tangentEnd();

			return new FlxPoint(
				endPos.x + dir.x * extra,
				endPos.y + dir.y * extra
			);
		}
		if (percent < 0)
		{
			var extra = percent;
			var startPos = getPosition(0);
			var dir = tangentStart();

			return new FlxPoint(
				startPos.x + dir.x * extra,
				startPos.y + dir.y * extra
			);
		}

		percent = FlxMath.bound(percent, 0, 1);

		var segments = count - 1;
		var t = percent * segments;
		var seg = Math.floor(t);
		var localT = t - seg;

		var p0 = getPoint(seg - 1);
		var p1 = getPoint(seg);
		var p2 = getPoint(seg + 1);
		var p3 = getPoint(seg + 2);

		return catmullRom(p0, p1, p2, p3, localT);
    }

    inline function getPoint(index:Int):FlxPoint
    {
        var count:Int = points.length;

        return points[
            Math.floor(FlxMath.bound(index, 0, count - 1))
        ];
    }

	function tangentEnd():FlxPoint
	{
		var n = points.length;
		var a = points[n - 2];
		var b = points[n - 1];

		return FlxPoint.get(b.x - a.x, b.y - a.y);
	}

	function tangentStart():FlxPoint
	{
		var a = points[0];
		var b = points[1];

		return FlxPoint.get(b.x - a.x, b.y - a.y);
	}

    inline function catmullRom(
        p0:FlxPoint,
        p1:FlxPoint,
        p2:FlxPoint,
        p3:FlxPoint,
        t:Float
    ):FlxPoint
    {
        var t2 = t * t;
        var t3 = t2 * t;

        return FlxPoint.get(
            0.5 * (
                (2 * p1.x) +
                (-p0.x + p2.x) * t +
                (2*p0.x - 5*p1.x + 4*p2.x - p3.x) * t2 +
                (-p0.x + 3*p1.x - 3*p2.x + p3.x) * t3
            ),
            0.5 * (
                (2 * p1.y) +
                (-p0.y + p2.y) * t +
                (2*p0.y - 5*p1.y + 4*p2.y - p3.y) * t2 +
                (-p0.y + 3*p1.y - 3*p2.y + p3.y) * t3
            )
        );
    }
}