package backend.game.paths;

import flixel.math.FlxPoint;
import flixel.math.FlxMath;

class BasePath
{
	public var points:Array<FlxPoint> = [];
	public var percent:Float = 0;
	
	public function new(points:Array<FlxPoint>)
	{
		this.points = (points ?? []);
	}
	
	public function addPoint(x:Float, y:Float):Void
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
            var startPos = points[0];
            var dir = tangentStart();
			
            var extra = percent;

            return FlxPoint.get(
                startPos.x + dir.x * extra,
                startPos.y + dir.y * extra
			);
        }

        var segments = count - 1;
        var t = percent * segments;
        var seg = Math.floor(t);

        // exact end fix
        if (seg >= segments)
            seg = segments - 1;

        var localT = t - seg;

        var a = points[seg];
        var b = points[seg + 1];

        return FlxPoint.get(
            FlxMath.lerp(a.x, b.x, localT),
            FlxMath.lerp(a.y, b.y, localT)
        );
	}
	
	inline function getPoint(index:Int):FlxPoint
    {
        var count:Int = points.length;

        return points[
            Math.floor(FlxMath.bound(index, 0, count - 1))
        ];
    }

	function tangentStart():FlxPoint
	{
		var a = points[0];
		var b = points[1];

		return FlxPoint.get(b.x - a.x, b.y - a.y);
	}
	
	function tangentEnd():FlxPoint
	{
		var n = points.length;
		var a = points[n - 2];
		var b = points[n - 1];

		return FlxPoint.get(b.x - a.x, b.y - a.y);
	}
}