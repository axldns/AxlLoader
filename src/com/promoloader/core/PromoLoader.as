package com.promoloader.core
{
	import com.promoloader.htmlBridge.HtmlEmbeder;
	import com.promoloader.nativeWindows.WindowConsole;
	import com.promoloader.nativeWindows.WindowRecent;
	import com.promoloader.nativeWindows.WindowTimestamp;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.html.HTMLLoader;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	
	import axl.utils.LibraryLoader;
	
	public class PromoLoader extends Sprite
	{
		
		[Embed(source='../../../../../promo-rsl/promo/bin-debug/axl.swf', mimeType='application/octet-stream')]
		private var AXL_LIBRARY:Class;
		
		[Embed(source='../../../../assets/bg-logo.png', mimeType='image/png')]
		private var bgImage:Class;
		
		public static var classDict:Object = {};
		private static var xinstance:PromoLoader;
		//loading
		private var swfLoaderInfo:LoaderInfo;
		private var overlap:String;
		private var overlap2:String;
		private var LOADABLEURL:URLRequest;
		private var xcontextParameters:Object;
		private var context:LoaderContext;
		private var delegatesLock:Boolean=true;
		private var delegates:Vector.<Function>;
		
		//flags
		public var clearLogEveryLoad:Boolean = true;
		public var changeConsoleContextToLoadedContent:Boolean=true;
		public var limitUnrecognizedFilesLength:uint=80000;
		public var preferHTMLLoader:Boolean;
		
		//windows
		private var xwindowTimestamp:WindowTimestamp;
		private var xwindowConsole:WindowConsole;
		private var xwindowRecent:WindowRecent;
		private var xmainWindow:NativeWindow;
		
		//elements
		private var xbar:TopBar;
		private var bg:Sprite;
		private var bgLogo:Bitmap;
		private var legacyController:LegacyController;
		public var htmlContent:HtmlEmbeder;
		private var eventsManager:EventsManager;
		private var openFile:File;
		private var displayableText:TextField;
		
		private var xbarDesiredHeight:Number = 22;
		private var xbgColour:uint=0xeeeeee;
		
		
		//tracking
		private var xVERSION:String = '0.2.13';
		private var tname:String = '[PromoLoader ' + xVERSION + ']';
		private var trackingURL:String;
		private var tracker:Tracking;
		private var OBJECT:DisplayObject;
		private var OBJECTREC:Rectangle = new Rectangle();
		private var lastScale:Number;
		private var U:Class;
		
		
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

		public function PromoLoader()
		{
			xinstance = this;
			delegates = new Vector.<Function>();
			legacyController = new LegacyController();
			axlLoadAndBuild();
		}	

		private function axlLoadAndBuild():void
		{
			
			var lloader:LibraryLoader = new LibraryLoader(this);
			lloader.domainType = 1;
			lloader.libraryURLs = [AXL_LIBRARY];
			lloader.onReady = go;
			lloader.load();
			function go():void
			{
				classDict = lloader.classDictionary;
				onAXLAvailable();
			}
		}
		
		private function onAXLAvailable():void
		{
			U = classDict.U;
			U.fullScreen=false;
			U.onResize = onResize;
			U.init(this, 800,600,ready);
			U.log(tname);
			
			buildBar();
			buildDisplayableTextField();
			buildWindows();
			runEventManager();
			
			Updater.updateFunction();
		}
		
		private function buildWindows():void
		{
			xwindowConsole = new WindowConsole('console');
			xwindowTimestamp = new WindowTimestamp('timestamp generator');
			xwindowRecent = new WindowRecent('recently loaded');
		}
		
		private function buildBar():void
		{
			xbar = new TopBar();
			addChild(bar);
		}
		
		private function runEventManager():void
		{
			eventsManager = new EventsManager();
			openFile = new File();
			openFile.addEventListener(Event.SELECT, eventsManager.onFileSelected);
		}
		
		private function ready():void
		{
			new classDict.LiveAranger();
		}
		
		private function delegatesEmpty():void
		{
			delegatesLock = false;
			while(delegates.length)
				delegates.shift()();
		}
		//------------------------ END OF INITIAL SETUP -------------------------- // 
		public function onVersionUpdate(oldVersion:String):void
		{
			delegate(Updater.updateFunction);
		}
		
		private function delegate(func:Function):void
		{
			if(delegatesLock)
			{
				if(delegates.indexOf(func) < 0)
					delegates.push(func);
			}
			else
				func();
		}		
		
		private function sizeObject():void
		{
			//U.log("SIZE OBJCT", OBJECT);
			if(OBJECT == null)
				return;
			switch(bar.cboxAutoSize.selectedLabel)
			{
				case 'scale': sizeScale(); break;
				case 'auto': sizeAuto(); break;
				case 'free': scaleFree(); break;
			}
		}		
		
		private function scaleFree():void
		{
			
			if(OBJECT is TextField)
			{
				displayableText.scaleX = displayableText.scaleY = 1;
				displayableText.wordWrap = false;
				displayableText.width = displayableText.textWidth + 5;
				displayableText.height =  stage.stageHeight-barDesiredHeight;
			}
			//OBJECT.scaleX = OBJECT.scaleY = 1;
		}
		
		private function sizeAuto():void
		{
			if(swfLoaderInfo != null)
			{
				OBJECT.scaleX = OBJECT.scaleY = 1;
				stage.stageWidth = swfLoaderInfo.width;
				stage.stageHeight = swfLoaderInfo.height + barDesiredHeight;
			}
			else if(OBJECT is TextField)
			{
				displayableText.scaleX = displayableText.scaleY = 1;
				displayableText.wordWrap = true;
				displayableText.width = stage.stageWidth;
				displayableText.height =  stage.stageHeight-barDesiredHeight;
			}
			else if(OBJECT is HTMLLoader)
			{
				if(this.htmlContent.htmlloader.width > 0 && this.htmlContent.htmlloader.height > 0)
				{
					stage.stageWidth = this.htmlContent.htmlloader.width;
					stage.stageHeight = this.htmlContent.htmlloader.height + barDesiredHeight;
				}
			}
			else
			{
				stage.stageWidth = OBJECT.width
				stage.stageHeight = OBJECT.height +barDesiredHeight;
			}
		}
		
		private function sizeScale():void
		{
			var rec:Object = { width : U.REC.width, height: U.REC.height - barDesiredHeight}
			if(OBJECT is HTMLLoader)
			{
				this.htmlContent.sizeScale(this.stage.stageWidth,this.stage.stageHeight-barDesiredHeight);
			}
			else if(swfLoaderInfo!=null)
			{
				OBJECTREC.width = swfLoaderInfo.width;
				OBJECTREC.height = swfLoaderInfo.height;
				
				U.resolveSize(OBJECTREC, rec);
				lastScale = OBJECTREC.width / swfLoaderInfo.width;
				OBJECT.scaleX =lastScale;
				OBJECT.scaleY = lastScale;
			}
			else if(OBJECT is TextField)
			{
				displayableText.wordWrap = false;
				displayableText.scaleX = displayableText.scaleY = 1;
				displayableText.height = (displayableText.textHeight + 5);
				displayableText.width = (displayableText.textWidth + 5);
				
				OBJECTREC.width = displayableText.width;
				OBJECTREC.height = displayableText.height;
				U.resolveSize(OBJECTREC, rec);
				lastScale = OBJECTREC.width/displayableText.width;
				OBJECT.scaleY =  lastScale ;
				OBJECT.scaleX =lastScale;
				
			}
		}
		
		// __________________________________________________________________ LOADING AND PARSING
		public function loadContent():void
		{
			if(LOADABLEURL == null)
			{
				U.msg("Nothing to load?");
				return;
			}
			var f:File = new  File(LOADABLEURL.url);
			if(!f.exists)
			{
				U.msg("File doesn't exist");
				return;
			}
			unloadAndReset();
			setupContext();
			setupDomain();
			U.log(tname," LOADING WITH PARAMETERS:", classDict. U.bin.structureToString(context.parameters));
			if(preferHTMLLoader)
				this.loadWithHTMLBridge();
			else
				classDict.Ldr.load(LOADABLEURL.url,null,contentLoaded,null,{},classDict.Ldr.behaviours.loadOverwrite,classDict.Ldr.defaultValue,classDict.Ldr.defaultValue,0,context);
			
		}
		
		private function setupDomain():void
		{
			if(domainType < 0)
			{
				context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
				U.log(tname," LOADING TO COPY OF CURRENT APPLICATION DOMAIN (loaded content can use parent classes, parent can't use childs classes other way than via class dict)")
			}
			else if(domainType > 0)
			{
				context.applicationDomain = new ApplicationDomain(null);
				U.log(tname,"LOADING TO BRAND NEW APPLICATION DOMAIN (loaded content can't use parent's classes, parent can't use childs classes other way than via class dict. Watch your fonts.")
			}
			else if(domainType == 0)
			{
				context.applicationDomain = ApplicationDomain.currentDomain;
				U.log(tname," LOADING TO CURRENT APPLICATION DOMAIN (all shared, conflicts may occur)")
			}
		}
		
		private function setupContext():void
		{
			context =new LoaderContext(classDict.Ldr.policyFileCheck);
			if(bar.tfMember.text.match(/^\d+$/g).length > 0)
				contextParameters.memberId = bar.tfMember.text;
			if(bar.tfCompVal.text.match(/^\d+$/g).length > 0)
				contextParameters.fakeComp = bar.tfCompVal.text;
			contextParameters.fakeTimestamp = String(bar.dates.timestampSec);
			if(bar.tfData.text != 'dataParameter' && bar.tfData.text.length > 1)
				contextParameters.dataParameter = bar.tfData.text;
			contextParameters.fileName = U.fileNameFromUrl(LOADABLEURL.url,true);
			contextParameters.loadedURL =LOADABLEURL.url;
			context.parameters = contextParameters;
		}
		
		private function unloadAndReset():void
		{
			if(OBJECT && OBJECT.parent)
			{
				if(OBJECT.parent is Loader &&  OBJECT.parent.parent)
				{
					OBJECT.parent.parent.removeChild(OBJECT.parent);
				}
				else
					OBJECT.parent.removeChild(OBJECT);
			}
			OBJECT= null;
			if(this.clearLogEveryLoad && classDict. U.bin != null)
				U.bin.clear();
			legacyController.onSwfUnload()
			classDict.Ldr.unloadAll();
			if(swfLoaderInfo)
				swfLoaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, eventsManager.onLoaderError);
			if(context && context.applicationDomain)
			{ 
				try { context.applicationDomain.domainMemory.clear() } catch(e:*) {}
			}
			if(htmlContent)
			{
				htmlContent.unload();
			}
			classDict.Ldr.defaultPathPrefixes = [];
			xcontextParameters = {};
			U.bin.parser.changeContext(this);
			for(var i:int = 0; i< stage.numChildren;i++)
			{
				var c:DisplayObject = stage.getChildAt(i);
				if(c != this && c != this.parent)
					stage.removeChildAt(i--);
			}
		}
		
		
		private function contentLoaded(v:String):void
		{
			//INFO
			var u:* = classDict.Ldr.getAny(v);
			
			log('content LOADED', LOADABLEURL.url, "\nTYPE:",flash.utils.describeType(u).@name,"\nINFO:",swfLoaderInfo ? swfLoaderInfo.contentType : 'not available');
			windowRecent.registerLoaded(LOADABLEURL.url);
			resolveDirOverlap();
			resolveSWFLoaderInfo(v);
			
			OBJECT = u as DisplayObject;
			if(OBJECT == null)
			{
				OBJECT = resolveNonDisplayableObject(v,u) as DisplayObject;
			}
			if(OBJECT == null)
			{
				onContentNotDisplayable();
				return;
			}
			// BY THIS POINT OBJECT IS VALID DIPLAY OBJECT
		
			OBJECT.y = barDesiredHeight;
			addToDisplayList(OBJECT);
			onResize();
			if(changeConsoleContextToLoadedContent && classDict. U.bin != null)
				U.bin.parser.changeContext(OBJECT);
		}
		
		private function addToDisplayList(OBJECT:DisplayObject):void
		{
			try { 
				this.addChildAt(OBJECT,bg && bg.parent ? 1 : 0);
			}
			catch(e:*)
			{
				U.log("AS2.0?", e);
				if(swfLoaderInfo != null)
				{
					OBJECT = swfLoaderInfo.loader;
					OBJECT.y = barDesiredHeight;
					this.addChildAt(OBJECT,bg && bg.parent ? 1 : 0);
				}
				else
				{
					onContentNotDisplayable();
				}
			}
		}
		
		private function onContentNotDisplayable():void
		{
			U.msg("Loaded content is not displayable.");
		}
		
		private function resolveSWFLoaderInfo(v:String):void
		{
			swfLoaderInfo = classDict.Ldr.loaderInfos[v];
			if(swfLoaderInfo != null)
			{
				U.log("got loader info", swfLoaderInfo.width, swfLoaderInfo.height);
				swfLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, eventsManager.onLoaderError);
				if(legacyController)
					legacyController.onSwfLoaded(swfLoaderInfo, overlap, overlap2);
			}
		}
		
		private function resolveNonDisplayableObject(objName:String,obj:Object):DisplayObject
		{
			var d:String;
			if(obj is ByteArray)
			{
				var ba:ByteArray = obj as ByteArray;
				d= ba.readUTFBytes(ba.bytesAvailable);
				if(d.length == 0)
				{
					ba.position = 0;
					d= String(ba);
				}
				if(d.length < limitUnrecognizedFilesLength)
				{
					displayableText.text = d;
					return displayableText;
				}
			}
			else if(obj is String || obj is XML || obj is XMLList)
			{
				if(obj is XML || obj is XMLList)
					d = obj.toXMLString();
				displayableText.text = d;
				return displayableText;
			}
			else if(obj is Sound)
			{
				return SoundParser.newSound(obj as Sound);
			}
			else
			{
				classDict.Ldr.unload(objName);
				return loadWithHTMLBridge();
			}
			return null;
		}		
		
		private function buildDisplayableTextField():void
		{
			displayableText = new TextField();
			displayableText.multiline = true;
			displayableText.border = true;
			displayableText.background = true;
			displayableText.backgroundColor = 0xeeeeee;
			displayableText.defaultTextFormat = new TextFormat("Arial", 12);
		}
		
		private function resolveDirOverlap():void
		{
			overlap = LOADABLEURL.url;
			var i:int = overlap.lastIndexOf('/');
			var j:int = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap = overlap.substring(0,i);
			i = overlap.lastIndexOf('/');
			j = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap2 = overlap.substring(0,i);
			U.log(tname,'resolved dir overlap:\n#1:', overlap,'\n#2:', overlap2);
			
		}
		
		private function loadWithHTMLBridge():HTMLLoader
		{
			U.log("trying htmlloaderzz");
			if(!htmlContent)
				htmlContent = new HtmlEmbeder(this);
			htmlContent.load(LOADABLEURL.url);
			htmlContent.htmlloader.y =barDesiredHeight;
			return htmlContent.htmlloader;
		}
		
		private function arangeBar():void
		{
			if(bar != null && bar.parent != null)
				bar.arangeBar();
		}
		
		private function updateBg():void
		{
			if(!bg)
			{
				bg = new Sprite();
				this.addChildAt(bg,0);
				if(!bgLogo)
				{
					bgLogo = new bgImage();
					bg.addChild(bgLogo)
				}
			}
			bg.graphics.clear();
			bg.graphics.beginFill(xbgColour);
			bg.graphics.drawRect(0,0, this.stage.stageWidth, this.stage.stageHeight);
			if(bgLogo)
			{
				var ls:Number = (this.stage.stageWidth > this.stage.stageHeight ? this.stage.stageHeight : this.stage.stageWidth) * 0.20;
				bgLogo.width = ls;
				bgLogo.scaleY = bgLogo.scaleX;
				U.center(bgLogo, U.REC);
			}
		}
		
		public function onResize():void
		{
			sizeObject();
			arangeBar();
			updateBg();
		}
		
		public function setLoadableURL(invokedFileUrlRequest:URLRequest):void
		{
			LOADABLEURL = invokedFileUrlRequest;
		}
		
		public function setupMainWindow():void
		{
			if(mainWindow == null)
				xmainWindow = this.stage.nativeWindow;
			if(mainWindow.closed)
			{
				var wop:NativeWindowInitOptions = new NativeWindowInitOptions();
				wop.type = NativeWindowType.NORMAL;
				xmainWindow = new NativeWindow(wop);
				mainWindow.stage.stageWidth = U.REC.width;
				mainWindow.stage.stageHeight = U.REC.height;
				mainWindow.stage.scaleMode = this.stage.scaleMode;
				mainWindow.stage.align =this.stage.align;
				mainWindow.stage.addChild(this);
				U.init(this,800,600);
			}
			mainWindow.activate();
			mainWindow.visible = true;
			mainWindow.restore();
		}
		
		public function switchToHTMLLoader():void
		{
			U.log("SWITCHING TO HTMLLOADER");
			legacyController.onSwfUnload()
			classDict.Ldr.unloadAll();
			classDict.Ldr.defaultPathPrefixes = [];
			if(swfLoaderInfo)
				swfLoaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, eventsManager.onLoaderError);
			swfLoaderInfo = null;
			OBJECT = loadWithHTMLBridge();
			OBJECT.y = barDesiredHeight;
			addToDisplayList(OBJECT);
			onResize();
			if(changeConsoleContextToLoadedContent && classDict. U.bin != null)
				U.bin.parser.changeContext(OBJECT);
		}
		
		public function browseForFile():void
		{
			openFile.browseForOpen("select promo swf")
		}
		
		public function log(...args):void {	U.log.apply(null,args) }
		public function get bar():TopBar { return xbar }
		public function get contextParameters():Object { return xcontextParameters }
		public function get VERSION():String { return xVERSION }
		public function get barDesiredHeight():Number {	return xbarDesiredHeight }
		
		public function get mainWindow():NativeWindow { return xmainWindow  }
		public function get windowTimestamp():WindowTimestamp { return xwindowTimestamp }
		public function get windowRecent():WindowRecent { return xwindowRecent }
		public function get windowConsole():WindowConsole { return xwindowConsole }
		public static function get instance():PromoLoader { return xinstance }
		
	}
}