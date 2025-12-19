package mobile.util;

#if android
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Environment;
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
#end

import lime.system.System;
import lime.app.Application;
import openfl.Assets;
import haxe.io.Bytes;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/** 
* @Authors MaysLastPlay, MarioMaster (MasterX-39), Dechis (dx7405)
* @version: 0.3.0
**/

class MobileUtil {
  public static var currentDirectory:String = null;
  private static var useAlternativePath:Bool = false;

  /**
   * Get the directory for the application. (External for Android Platform and Internal for iOS Platform.)
   * Now with automatic fallback to Android/media path if permissions fail.
   */
public static function getDirectory():String {
    #if android
    var preferredPath = "/storage/emulated/0/.FNF Doors/";
    var fallbackPath = "/storage/emulated/0/Android/media/com.glasshat.glasshatengine/";
    
    if (FileSystem.exists(preferredPath + "assets") && FileSystem.isDirectory(preferredPath + "assets")) {
        useAlternativePath = false;
        return preferredPath;
    }
    
    try {
        if (!FileSystem.exists(preferredPath)) {
            FileSystem.createDirectory(preferredPath);
        }
        var testFile = preferredPath + ".permission_test";
        File.saveContent(testFile, "test");
        FileSystem.deleteFile(testFile);
        useAlternativePath = false;
        return preferredPath;
    } catch (e:Dynamic) {
        useAlternativePath = true;
        return fallbackPath;
    }
    #elseif ios
    return System.documentsDirectory;
    #else
    return "";
    #end
}


  /**
   * Requests Storage Permissions on Android Platform.
   */
  public static function getPermissions():Void {
    try {
        #if android
        //if (VERSION.SDK_INT >= 30) {
            if (!Environment.isExternalStorageManager()) {
                Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
            }
        /*}
        else if (VERSION.SDK_INT == 29) {
            try {
                if (!Environment.isExternalStorageManager()) {
                    Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
                }
            } catch (e1:Dynamic) {
                trace('Fallback 1 failed: $e1');
            }

            try {
                Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
            } catch (e2:Dynamic) {
                trace('Fallback 2 failed: $e2');
            }

            try {
                if (!FileSystem.exists(MobileUtil.getDirectory())) {
                    FileSystem.createDirectory(MobileUtil.getDirectory());
                }
            } catch (e3:Dynamic) {
                trace('Fallback 3 failed: $e3');
            }
        }
        else {
            Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
        }*/
        #end

        var targetDir = MobileUtil.getDirectory();
        if (!FileSystem.exists(targetDir)) {
            try {
                FileSystem.createDirectory(targetDir);
                trace('Successfully created directory: $targetDir');
            } catch (e:Dynamic) {
                trace('Failed to create directory $targetDir: $e');
            }
        }
    } catch (e:Dynamic) {
        trace('Error on creating directory: $e');
        var finalDir = MobileUtil.getDirectory();
        if (!FileSystem.exists(finalDir)) {
            try {
                FileSystem.createDirectory(finalDir);
            } catch (e2:Dynamic) {
                Application.current.window.alert(
                    'Uncaught Error',
                    "It seems you did not enable the required permissions to run the game. " +
                    "Please enable them and add files to ${finalDir}. Press OK to close the game."
                );
                System.exit(0);
            }
        }
    }
  }

  /**
   * Saves a file to the external storage.
   */
  public static function save(fileName:String = 'Ye', fileExt:String = '.txt', fileData:String = 'Nice try, but you failed, try again!') {
    var savesDir:String = MobileUtil.getDirectory() + 'saves/';

    if (!FileSystem.exists(savesDir))
      FileSystem.createDirectory(savesDir);

    File.saveContent(savesDir + fileName + fileExt, fileData);
  }

  public static function copySpesificFileFromAssets(filePathInAssets:String, copyTo:String, ?changeable:Bool)
	{
		try {
			if (Assets.exists(filePathInAssets)) {
				var fileData:Bytes = Assets.getBytes(filePathInAssets);
				if (fileData != null) {
					if (FileSystem.exists(copyTo) && changeable) {
						var existingFileData:Bytes = File.getBytes(filePathInAssets);
						if (existingFileData != fileData && existingFileData != null)
							File.saveBytes(copyTo, fileData);
					}
					else if (!FileSystem.exists(copyTo))
						File.saveBytes(copyTo, fileData);

					trace('Copied: $filePathInAssets -> $copyTo');
				} else {
					var textData = Assets.getText(filePathInAssets);
					if (textData != null) {
						if (FileSystem.exists(copyTo) && changeable) {
							var existingTxtData = File.getContent(filePathInAssets);
							if (existingTxtData != textData && existingTxtData != null)
								File.saveContent(copyTo, textData);
						}
						else if (!FileSystem.exists(copyTo))
							File.saveContent(copyTo, textData);
						trace('Copied (text): $filePathInAssets -> $copyTo');
					}
				}
			}
		} catch (e:Dynamic) {
			trace('Error copying file $filePathInAssets: $e');
		}
  }
}
