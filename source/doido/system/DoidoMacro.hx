package doido.system;

#if macro
class DoidoMacro
{
	/**
	 * A macro to be called targeting the `FlxBasic` class.
	 * @return An array of fields that the class contains.
	 */
	public static macro function buildFlxBasic():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();

		var hasZIndex:Bool = false;

		for (f in fields)
		{
			if (f.name == "zIndex")
			{
				hasZIndex = true;
				break;
			}
		}

		if (!hasZIndex)
		{
			// Here, we add the zIndex attribute to all FlxBasic objects.
			// This has no functional code tied to it, but it can be used as a target value
			// for the FlxTypedGroup.sort method, to rearrange the objects in the scene.
			fields.push({
				name: "zIndex", // Field name.
				access: [haxe.macro.Expr.Access.APublic], // Access level
				kind: haxe.macro.Expr.FieldType.FVar(macro :Int, macro $v{0}), // Variable type and default value
				pos: haxe.macro.Context.currentPos(), // The field's position in code.
			});
		}

		return fields;
	}
}
#end
