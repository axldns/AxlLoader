/**
 * Created by ddd on 26/07/2015.
 */
package {
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	
	public class ConfigProcessor {
	    public var saveFile:File;
	    private var fs:FileStream;
	
	    private var saveString:String;
	    private var getConfigXML:Function;
	    public function ConfigProcessor(getConfigXMLFunc:Function) {
			getConfigXML = getConfigXMLFunc
	    }
	
	    public function saveConfig(newFile:Boolean=false):void
	    {
	        var xml:XML = getConfigXML() as XML;
	        if(xml == null)
			{
				PromoLoader.classDict.U.msg("Nothing to save");
				return;
			}
	        saveString = xml.toString();
	        var replaced:String =  saveString.replace(/\"/g, "'");
			saveString = replaced.replace(/\&quot;/g, '"');
	        if(newFile || (saveFile == null))
	        {
	            saveFile = new File();
				saveFile.addEventListener(Event.SELECT, fileSelected);
				saveFile.addEventListener(Event.CANCEL, fileSavingCanceled);
				saveFile.browseForSave("Choose config saving path");
	        }
	        else
	            saveFileSelected();
	    }
		
		protected function fileSavingCanceled(e:Event):void
		{
			saveFile.removeEventListener(Event.SELECT, fileSelected);
			saveFile.removeEventListener(Event.CANCEL, fileSavingCanceled);
			saveFile = null;
		}
		
		protected function fileSelected(e:Event):void
		{
			PromoLoader.classDict.U.log(e);
			PromoLoader.classDict.U.log(saveFile.nativePath);
			PromoLoader.classDict.U.log(e.target.url);
			saveFileSelected();
		}
		
	    protected function saveFileSelected(e:Event=null):void
	    {
			if(fs != null)
			{
				fs.close();
				fs = null;
			}
	     	fs = new FileStream();
	
			try{ fs.open(saveFile, FileMode.WRITE);
	        fs.writeUTFBytes(saveString);
	        fs.close();
			PromoLoader.classDict.U.log('SAVED', saveFile.nativePath);
			} catch(e:Error){PromoLoader.classDict.U.log("ERROR WHILE SAVING")};
	    }
	}
}
