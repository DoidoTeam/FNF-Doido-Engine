package doido.util;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import java.io.File;
import org.haxe.extension.Extension;

public class FolderUtil
{
    /**
   * A method that opens the Application's data folder for browsing through the Storage Access Framework.
   * It's highly based on some code borrowed from Mterial Files
   * https://github.com/zhanghai/MaterialFiles
   */
  public static void openFolder(String folder, int requestCode)
  {
    if (Extension.mainActivity == null) return;
    
    Intent intent = new Intent(Intent.ACTION_VIEW);
    intent.setDataAndType(DocumentsContract.buildDocumentUri("com.android.externalstorage.documents", "primary:" + folder), "vnd.android.document/directory");
    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
    intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
    Extension.mainActivity.startActivityForResult(intent, requestCode);
  }
}