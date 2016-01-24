package
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class LibraryLoader
	{
		private var xfileName:String;
		private var rootObj:Object;
		private var isLocal:Boolean;
		private var classDict:Object;
		
		
		public var onReady:Function;
		public var libraryURLs:Array = [
			"https://static.gamesys.co.uk/jpj//promotions/AXLDNS_test/libs/promolib.swf",
			"http://axldns.com/promolib.swf",
		];
		private var libraryLoader:Loader;
		private var urlLoader:URLLoader;
		private var urlReq:URLRequest;
		private var URLIndex:int;
		private var context:LoaderContext;
		private var params:Object;
		private var lInfo:LoaderInfo;
		private var getStageTimeout:uint;
		protected var tname:String = '[LibraryLoader]';
		public function LibraryLoader(rootObject:Object)
		{
			rootObj = rootObject;
		}
		public function get fileName():String { return xfileName}
		public function get classDictionary():Object { return classDict }
		public function load():void
		{
			findFilename();
		}
		private function findFilename():void
		{
			getStageTimeout= flash.utils.setTimeout(notFound,500);
			if(rootObj.stage)
				onStageAvailable();
			else
				rootObj.addEventListener(Event.ADDED_TO_STAGE, onStageAvailable);
		}
		
		private function onStageAvailable(e:Event=null):void
		{
			rootObj.removeEventListener(Event.ADDED_TO_STAGE, onStageAvailable);
			flash.utils.clearTimeout(getStageTimeout);
			trace(tname,'fileName:',fileName,'\nrootObj.loaderInfo.parameters.fileName:',  rootObj.loaderInfo.parameters.fileName,'\nrootObj.loaderInfo.url:',rootObj.loaderInfo.url);
			isLocal = rootObj.loaderInfo.url.match(/^(file|app):/i);
			xfileName = fileName || rootObj.loaderInfo.parameters.fileName || fileNameFromUrl(rootObj.loaderInfo.url);
			trace(tname,"filename =", fileName, 'local:', isLocal);
			fileNameFound();
		}
		private function notFound():void {trace(tname, "stage not found, filename unknown") }
		
		private function fileNameFound():void
		{
			runApp();
		}
		
		private function runApp():void
		{
			try { Security.allowDomain("*"); }
			catch(e:*) { trace(tname, e)};
			getLibrary(run);
		}
		
		private function run():void
		{
			if(onReady)
				onReady();
		}
		
		private function getLibrary(onReady:Function):void
		{
			for(var i:int,c:String='', a:Vector.<String> = ApplicationDomain.currentDomain.getQualifiedDefinitionNames(); i < a.length; i++)
				c+='\n'+i+': '+a[i];
			
			URLIndex = -1;
			loadNext();
		}
		
		private function loadNext():void
		{
			if(++URLIndex < libraryURLs.length)
			{
				loadURL(libraryURLs[URLIndex]);
			}
			else
				trace(tname,"[CRITICAL ERROR] no alternative library paths last [APPLICATION FAIL]");
		}
		
		private function loadURL(url:String):void
		{
			if(urlReq == null)
			{
				urlReq = new URLRequest();
			}
			urlReq.url = url + '?caheBust=' + String(new Date().time);
			trace(tname,"loadURL",  urlReq.url );
			if(urlLoader == null)
			{
				urlLoader = new URLLoader(urlReq);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				addListeners(urlLoader,onURLComplete,onError);
			}
			urlLoader.load(urlReq);
		}
		
		private function onURLComplete(e:Event):void
		{
			var bytes:ByteArray =urlLoader.data;
			if(libraryLoader == null)
			{
				libraryLoader = new Loader();
				
				lInfo = libraryLoader.contentLoaderInfo;
				lInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
				this.addListeners(lInfo,onLoaderComplete,onError);
				
				
				params = new Object();
				params.fileName = fileName;
				params.whatEver = "test";
				context = new LoaderContext(false);
				context.allowCodeImport = true;
				context.parameters = params;
			}
			
			trace(tname,"onURLComplete. Loadying bytes. context.parameters.fileName:", context.parameters.fileName);
			libraryLoader.loadBytes(bytes, context);
		}
		
		private function onLoaderComplete(e:Event):void 
		{
			trace(tname, 'onLoaderComplete');
			mapClasses();
			destroy();
		}
		
		private function mapClasses():void
		{
			trace(tname, 'mapClasses');
			var an:Vector.<String> = libraryLoader.contentLoaderInfo.applicationDomain.getQualifiedDefinitionNames();
			var len:int = an.length;
			var n:String='';
			var cn:String;
			var cls:Class;
			if(!classDict)
				classDict = {}
			for(var i:int =0; i <len; i++)
			{
				cn = an[i];
				try {
					cls = libraryLoader.contentLoaderInfo.applicationDomain.getDefinition(cn) as Class;
					cn = cn.substr(cn.lastIndexOf(':')+1);
					classDict[cn] = cls;
					n+='\n'+i+': '+cn;
				}
				catch(e:*)
				{
					n+= '\n' + cn + " can not be included" +  e;
				}
				
			}
			if(classDict.U)
			{
				classDict.U.log(this,"[LIBRARY LOADED-CLASSES MAPPED]. VERSION:\nAXL -", 
					classDict.U.version, classDict.xRoot ? "\nAXLX -" + classDict.xRoot.version : "");
				onReady();
			}
			else
			{
				trace(tname,"[FATAL ERROR]: class U not mapped");
			}
		}
		
		private function onError(e:*=null):void
		{
			trace(tname,"[CAN'T LOAD LIBRARY]", urlReq.url, "\n", e);
			if(libraryLoader)
			{
				libraryLoader.unload();
				libraryLoader.unloadAndStop();
			}
			loadNext();
		}
		
		private function addListeners(dispatcher:IEventDispatcher,onUrlLoaderComplete:Function,onError:Function):void
		{
			if(dispatcher == null) return;
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, onError);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			dispatcher.addEventListener(Event.COMPLETE, onUrlLoaderComplete);
		}
		
		private function removeListeners(dispatcher:IEventDispatcher,onUrlLoaderComplete:Function,onError:Function):void
		{
			if(dispatcher == null) return;
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			dispatcher.removeEventListener(Event.COMPLETE, onUrlLoaderComplete);
		}
		
		private function destroy():void
		{
			trace(tname, 'destroy');
			removeListeners(libraryLoader, onLoaderComplete, onError);
			removeListeners(urlLoader, onURLComplete, onError);
			libraryLoader = null;
			urlLoader = null;
			if(lInfo)
				lInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
			lInfo = null;
		}
		
		public static function fileNameFromUrl(v:String,removeQuerry:Boolean=false,removeExtension:Boolean=false):String
		{
			var fileName:String = v||"";
			var q:int = fileName.indexOf('?');
			if(q > -1&&removeQuerry)
				fileName = fileName.substr(0,q).split('/').pop();
			else
				fileName = fileName.split('/').pop();
			return removeExtension ? fileName.replace(/.\w+$/i, "") : fileName;
		}
	}
}