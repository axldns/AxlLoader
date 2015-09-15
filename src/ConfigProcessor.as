/**
 * Created by ddd on 26/07/2015.
 */
package {
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import axl.utils.U;
	
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
	            return U.msg("Nothing to save");
	        saveString = xml.toString();
	        var replaced:String =  saveString.replace(/\"/g, "'");
			saveString = replaced.replace(/\&quot;/g, '"');
			U.log("saveString", saveString);
	        if(newFile || (saveFile == null))
	        {
	            saveFile = new File();
				saveFile.addEventListener(Event.SELECT, fileSelected);
				saveFile.browseForSave("Choose config saving path");
	        }
	        else
	            saveFileSelected();
	
	    }
		
		protected function fileSelected(e:Event):void
		{
			U.log(e);
			U.log(saveFile.nativePath);
			U.log(e.target.url);
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
			U.log('SAVED', saveFile.nativePath);
			} catch(e:Error){U.log("ERROR WHILE SAVING")};
	    }
	}
}
