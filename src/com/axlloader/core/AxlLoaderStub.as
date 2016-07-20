package com.axlloader.core
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.clearTimeout;
	
	import axl.utils.LibraryLoader;
	
	public class AxlLoaderStub extends Sprite
	{
		/** Loads library to specific application domain according the rule:
		 * <ul>
		 * <li><b>negative values</b> (default): new ApplicationDomain(ApplicationDomain.currentDomain) - This allows the loaded SWF file to use the parent's classes directly, 
		 * for example by writing new MyClassDefinedInParent(). The parent, however, cannot use this syntax; if the parent wishes 
		 * to use the child's classes, it must call ApplicationDomain.getDefinition() to retrieve them. The advantage of this choice is that, 
		 * if the child defines a class with the same name as a class already defined by the parent, no error results; the child simply 
		 * inherits the parent's definition of that class, and the child's conflicting definition goes unused unless either child or parent 
		 * calls the ApplicationDomain.getDefinition() method to retrieve it.</li>
		 * <li><b>0 value</b>: ApplicationDomain.currentDomain - When the load is complete, parent and child can use each other's classes directly.
		 * If the child attempts to define a class with the same name as a class already defined by the parent, the parent class is used and the child class is ignored.
		 * <li><b>positive values</b>: new ApplicationDomain(null) - This separates loader and loadee entirely, allowing them to define separate versions of classes 
		 * with the same name without conflict or overshadowing. The only way either side sees the other's classes is by calling the ApplicationDomain.getDefinition() method.</li>
		 * </ul>
		 * */
		public var domainType:int = -1;
		private var cookie:SharedObject;
		private var newVersion:Boolean;
		private var version:String;
		private var cb:String =  "?cb="+String(new Date().time);
		private var versionURL:String = "http://axldns.com/axlloader/version.json" + cb;
		
		private var lloader:LibraryLoader;
		private var net:String = "http://axldns.com/axlloader/AxlLoader.swf" + cb;
		private var local:String = File.applicationStorageDirectory.resolvePath('AxlLoader.swf').nativePath;
		
		private var log:Function = trace;
		
		public function AxlLoaderStub()
		{
			cookie = SharedObject.getLocal('axlloader2');
			version = cookie.data.version || '0';
			super();
			checkVersion(loadProgram);
			//log = function(...args):void{}
		}
		
		private function checkVersion(callback:Function):void
		{
			var timeout:int = 3000;
			var urlr:URLRequest = new URLRequest(versionURL);
			var urll:URLLoader = new URLLoader();
			urll.addEventListener(IOErrorEvent.IO_ERROR, onError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			urll.addEventListener(Event.COMPLETE, onComplete);
			urll.addEventListener(Event.CANCEL, onError);
			urll.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpResponseStatus);
			urll.addEventListener(Event.OPEN, onOpen);
			var tid:int;// = flash.utils.setTimeout(manualCancel, timeout);
			urll.load(urlr);
			
			function onHttpResponseStatus(e:HTTPStatusEvent):void
			{
				log(e.status,e);
			}
			function manualCancel():void
			{
				urll.close();
				urll.dispatchEvent(new Event(Event.CANCEL));
			}
			function onOpen(e:Object=null):void
			{
				log("OPEN",versionURL);
				flash.utils.clearTimeout(tid);
			}
			function onError(e:Object=null):void
			{
				log("version check error", e);
				newVersion = false;
				removeListeners();
				callback();
			}
			
			function onComplete(e:Object=null):void
			{
				log("COMPLETE",e? e.target.data :null);
				var versionInfo:String;
				try { versionInfo = JSON.parse(e.target.data).v; } 
				catch (je:*) { }
				if(versionInfo == null)
					return onError();
				newVersion = version != versionInfo;
				log("versionInfo", versionInfo, "new?", newVersion);
				removeListeners();
				callback();
			}
			
			function removeListeners():void
			{
				urll.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				urll.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				urll.removeEventListener(Event.CANCEL, onError);
				urll.removeEventListener(Event.COMPLETE, onComplete);
				urll.removeEventListener(Event.OPEN, onOpen);
				urll = null;
			}
		}
		
		private function loadProgram():void
		{
			lloader= new LibraryLoader(this,log);
			lloader.domainType = domainType;
			lloader.mapOnlyClasses = [];
			lloader.libraryURLs = newVersion ? [net,local] : [local,net];
			log("urls:", lloader.libraryURLs);
			lloader.onReady = onProgramLoaded;
			lloader.currentLibraryVersion = version;
			lloader.onNewVersion = onNewVersion;
			lloader.load();
		}
		
		private function onProgramLoaded():void
		{
			var l:DisplayObject = lloader.libraryLoader ? lloader.libraryLoader.content : null;
			if(l)
			{
				addChild(l);
			}
			else
			{
				var tf:TextField = new TextField();
				tf.wordWrap = true;
				tf.multiline = true;
				tf.border = true;
				tf.text = "Can't load libs:\n# " + lloader.libraryURLs.join('\n# ');
				tf.height = tf.textHeight + 5;
				tf.width = stage? stage.stageWidth : 640;
				addChild(tf);
			}
		}
		private function onNewVersion(newVersion:String):void
		{
			var f:File = File.applicationStorageDirectory.resolvePath('AxlLoader.swf');
			log("SAVING", f.nativePath);
			var fs:FileStream = new FileStream();
			fs.open(f,'write');
			fs.writeBytes(lloader.bytes);
			fs.close();
			
			cookie.data.version = newVersion;
			cookie.flush();
		}
	}
}