package doido.system.android;

#if android
import extension.androidtools.jni.JNICache;

/**
 * A Utility class to manage the Application's Data folder on Android.
 */
class Android
{
	/**
	 * Opens the data folder on an Android device using JNI.
	 */
	public static function openFolder(?path:String, requestCode:Int = 1):Void
	{
		final openFolder:Null<Dynamic> = JNICache.createStaticMethod('doido/util/FolderUtil', 'openFolder', '(Ljava/lang/String;I)V');

		if (openFolder != null)
			openFolder('${Main.sysPath}${path == null ? '' : '/$path'}', requestCode);
	}
}
#end
