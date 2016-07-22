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
		private var cookie:SharedObject;
		private var newVersion:Boolean;
		private var version:String;
		private var cb:String =  "?cb="+String(new Date().time);
		private var versionURL:String = "http://axldns.com/axlloader/version.json" + cb;
		
		private var net:String = "http://axldns.com/axlloader/AxlLoader.swf" + cb;
		private var local:String = File.applicationStorageDirectory.resolvePath('AxlLoader.swf').nativePath;
		private var lloader:LibraryLoader;
		
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
			lloader.domainType = lloader.domain.coppyOfCurrent;
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