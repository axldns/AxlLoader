package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.display.NativeMenuItem;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.KeyboardEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	
	import axl.utils.LibraryLoader;
	
	import fl.events.ComponentEvent;
	
	import nativeWindows.WindowConsole;
	import nativeWindows.WindowRecent;
	import nativeWindows.WindowTimestamp;
	
	public class PromoLoader extends Sprite
	{
		
		[Embed(source='../../promo-rsl/promo/bin-debug/axl.swf', mimeType='application/octet-stream')]
		public var AXL_LIBRARY:Class;
		
		public static var classDict:Object = {};
		//loading
		private var openFile:File;
		private var clickFile:File;
		private var currentName:String;
		private var currentUrl:String;
		private var swfLoaderInfo:LoaderInfo;
		private var overlap:String;
		private var LOADABLEURL:URLRequest;
		
		//parsing
		private var xmlPool:Array=[];
		private var xconfig:XML;
		private var configProcessor:ConfigProcessor;
		
		//flags
		public var clearLogEveryLoad:Boolean = true;
		public var changeConsoleContextToLoadedContent:Boolean=true;
		
		//windows
		private var windowTimestamp:WindowTimestamp;
		private var windowConsole:WindowConsole;
		private var windowRecent:WindowRecent;
		
		//elements
		private var bar:TopBar;
		//private var liveAranger:xLiveAranger;
		
		//tracking
		private var xVERSION:String = '0.2.2';
		private var trackingURL:String;
		private var tracker:Tracking;
		private var OBJECT:DisplayObject;
		private var OBJECTREC:Rectangle = new Rectangle();
		private var lastScale:Number;
		
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
		private var context:LoaderContext;
		private var tname:String;
		private var barDesiredHeight:Number = 22;
		private var xbgColour:uint=0xeeeeee;
		private var bg:Sprite;
		private var delegatesLock:Boolean=true;
		private var delegates:Vector.<Function>;
		
		public function PromoLoader()
		{
			super();
			delegates = new Vector.<Function>();
			var lloader:LibraryLoader = new LibraryLoader(this);
			lloader.domainType = 1;
			lloader.libraryURLs = [
				AXL_LIBRARY,
				"axl.swf",
				"https://static.gamesys.co.uk/jpj//promotions/AXLDNS_test/libs/axl.swf",
				"https://static.gamesys.co.uk/jpj//promotions/AXLDNS_test/libs/promo.swf",
				"http://axldns.com/axl.swf"
			];
			lloader.onReady = go;
			lloader.load();
			function go():void
			{
				classDict = lloader.classDictionary;
				initApp();
			}
		}
		
		public function get VERSION():String { return xVERSION }

		public function get bgColour():uint { return xbgColour; }
		public function set bgColour(value:uint):void
		{
			xbgColour = value;
			updateBg();
		}

		private function initApp():void
		{
			tname = '[PromoLoader ' + VERSION + ']';
			classDict.U.fullScreen=false;
			classDict.U.onResize = onResize;
			classDict.U.init(this, 800,600);
			classDict.U.log(tname);
			
			buildBar();
			setupApp();
			buildWindows();
			this.addChild(bar);
			delegatesEmpty();
		}
		
		private function delegatesEmpty():void
		{
			delegatesLock = false;
			while(delegates.length)
				delegates.shift()();
		}
		
		public function onVersionUpdate(oldVersion:String):void
		{
			delegate(function():void {classDict.U.msg("Your PromoLoader has been updated to:", VERSION ) });
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
		
		private function onResize():void
		{
			arangeBar();
			updateBg();
			if(OBJECT != null && this.bar.cboxAutoSize.selectedLabel == 'scale')
			{
				OBJECTREC.width = swfLoaderInfo.width;
				OBJECTREC.height = swfLoaderInfo.height + barDesiredHeight;
				classDict.U.resolveSize(OBJECTREC, classDict.U.REC);
				lastScale = OBJECTREC.width / swfLoaderInfo.width;
				OBJECT.scaleX =lastScale;
				OBJECT.scaleY = lastScale;
			}
		}
		
		private function updateBg():void
		{
			if(!bg)
			{
				bg = new Sprite();
				this.addChildAt(bg,0);
			}
			bg.graphics.clear();
			bg.graphics.beginFill(bgColour);
			bg.graphics.drawRect(0,0, stage.stageWidth, stage.stageHeight);
		}
		
		//__________________________________________________________________ INSTANTIATION
		private function buildWindows():void
		{
			windowConsole = new WindowConsole('console');
			windowTimestamp = new WindowTimestamp('timestamp generator');
			windowRecent = new WindowRecent('recently loaded');
			windowRecent.addEventListener(Event.SELECT, recentSelectEvent);
		}
		
		private function setupApp():void
		{
			openFile = new File();
			openFile.addEventListener(Event.SELECT, fileSelected);
			configProcessor = new ConfigProcessor(getConfigXML);
			classDict.Ldr.addExternalProgressListener(somethingLoaded);
			
			tracker = new Tracking(trackingURL, VERSION);
			
			if(Capabilities.version.substr(0,3).toLowerCase() == "mac")
				NativeApplication.nativeApplication.menu.addEventListener(Event.SELECT, niKeyMac);
			NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, niKey);
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, exitingEvent);
			
			stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);

		}		
		
		
		protected function onDragDrop(e:NativeDragEvent):void
		{
			trace(e);
			var arr:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			
			//grab the files file
			if(arr && arr.length > 0)
			{
				LOADABLEURL = new URLRequest(arr.pop().url); 
				loadContent();
			}
		}
		
		private function onDragIn(e:NativeDragEvent):void
		{
			trace(e);
			//check and see if files are being drug in
			if(e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				//get the array of files
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				
				//make sure only one file is dragged in (i.e. this app doesn't
				//support dragging in multiple files)
				if(files.length == 1)
				{
					//accept the drag action
					NativeDragManager.acceptDragDrop(this);
				}
			}
		}
		
		private function buildBar():void
		{
			bar = new TopBar();
			bar.dates.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			bar.tfCompVal.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			bar.tfData.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			bar.tfMember.textField.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			bar.btnLoad.addEventListener(ComponentEvent.BUTTON_DOWN, btnLoadDown);
			bar.btnConsole.addEventListener(ComponentEvent.BUTTON_DOWN, btnConsoleDown);
			bar.btnRecent.addEventListener(ComponentEvent.BUTTON_DOWN, btnRecentDown);
			bar.btnReload.addEventListener(ComponentEvent.BUTTON_DOWN, btnReloadDown);
		}
		
		private function btnConsoleDown(e:*=null):void { windowConsole.wappear() }
		private function btnRecentDown(e:*=null):void { windowRecent.wappear() }
		private function btnTimestampDown(e:*=null):void { windowTimestamp.wappear() }
		private function btnReloadDown(e:*=null):void { loadContent() }
		private function btnLoadDown(e:*=null):void { openFile.browseForOpen("select promo swf") }
		
		
		//__________________________________________________________________  events handling
		protected function fileSelected(e:Event):void
		{
			classDict.U.log("DIRECTORY", openFile ?  openFile.parent.url : null);
			LOADABLEURL = new URLRequest(openFile.url); 
			loadContent();
		}
		protected function asyncError(e:Event):void
		{
			classDict.U.msg("Async error occured: " + e.toString());
			e.preventDefault();
		}
		
		protected function keyUp(e:KeyboardEvent):void
		{
			if(e.charCode == 13)
				btnReloadDown()
		}
		private function recentSelectEvent(e:Event):void
		{
			LOADABLEURL = new URLRequest(windowRecent.selectedURL); 
			btnReloadDown();
		}
		protected function onInvokeEvent(e:InvokeEvent):void
		{
			var uu:URLRequest, u:String
			if(e.arguments.length > 0)
			{
				u = e.arguments.pop();
				try {
					clickFile = new File(u);
					uu = new URLRequest(clickFile.url);
				}
				catch (e:Error) { classDict. U.msg(e.message) };
				if(uu == null)
				{
					classDict.U.msg("Can't open " + u);
					return
				}
				LOADABLEURL = uu;
				btnReloadDown();
			}
		}
		
		protected function niKey(e:KeyboardEvent):void
		{
			if(e.ctrlKey || e.commandKey)
			{
				var keyp:String = String.fromCharCode(e.charCode).toLowerCase();
				switch(keyp)
				{
					case 'v': pasteEventParse(); break;
					case 's': configProcessor.saveConfig(e.shiftKey); break;
					case 'l': (bar.parent != null) ? bar.parent.removeChild(bar) : addChild(bar); break;
					case 'r': btnReloadDown(); break;
					case 't': btnTimestampDown() ; break;
					case 'h': btnRecentDown() ; break;
					case 'c': e.shiftKey ? btnConsoleDown() : null ; break;
					default:
						var n:Number = Number(keyp);
						if(!isNaN(n))
							windowRecent.selectListItemUrlAt(n-1);
						break;
				}
			}
		}
		protected function niKeyMac(e:Event):void
		{
			var menuItem:NativeMenuItem = e.target as NativeMenuItem; 
			switch(menuItem.label.toLowerCase())
			{
				case "paste": pasteEventParse();break;
			}
		}
		protected function syncEventReceived(e:Event):void
		{
			classDict.U.log(classDict.U.bin.structureToString(e));
		}
		protected function exitingEvent(e:Event):void
		{
			if(bar != null)
				bar.exiting();
		}
		
		// __________________________________________________________________ LOADING AND PARSING
		protected function loadContent():void
		{
			if(LOADABLEURL == null)
			{
				classDict.U.msg("Nothing to load?");
				return
			}
			if(OBJECT && OBJECT.parent)
				OBJECT.parent.removeChild(OBJECT);
			OBJECT= null;
			if(this.clearLogEveryLoad && classDict. U.bin != null)
				classDict.U.bin.clear();
			classDict.U.msg("loading: " +LOADABLEURL.url);
			var ts:Number = bar.dates.timestampSec;
			classDict.Ldr.unloadAll();
			if(context && context.applicationDomain)
			{ 
				try { context.applicationDomain.domainMemory.clear() } catch(e:*) {}
			}
			classDict.Ldr.defaultPathPrefixes = [];
			var contextParameters:Object = {};
			classDict.Ldr.defaultPathPrefixes = [];
			classDict.U.bin.parser.changeContext(this);
			context =new LoaderContext(classDict.Ldr.policyFileCheck);
			if(bar.tfMember.text.match(/^\d+$/g).length > 0)
				contextParameters.memberId = bar.tfMember.text;
			if(bar.tfCompVal.text.match(/^\d+$/g).length > 0)
				contextParameters.fakeComp = bar.tfCompVal.text;
			contextParameters.fakeTimestamp = String(ts);
			if(bar.tfData.text != 'dataParameter' && bar.tfData.text.length > 1)
				contextParameters.dataParameter = bar.tfData.text;
			contextParameters.fileName = classDict.U.fileNameFromUrl(LOADABLEURL.url,true);
			contextParameters.loadedURL =LOADABLEURL.url;
			
			context.parameters  = contextParameters;
			if(domainType < 0)
			{
				context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
				classDict.U.log("[PL] LOADING TO COPY OF CURRENT APPLICATION DOMAIN (loaded content can use parent classes, parent can't use childs classes other way than via class dict)")
			}
			else if(domainType > 0)
			{
				context.applicationDomain = new ApplicationDomain(null);
				classDict.U.log("[PL] LOADING TO BRAND NEW APPLICATION DOMAIN (loaded content can't use parent's classes, parent can't use childs classes other way than via class dict. Watch your fonts.")
			}
			else if(domainType == 0)
			{
				context.applicationDomain = ApplicationDomain.currentDomain;
				classDict.U.log("[PL] LOADING TO CURRENT APPLICATION DOMAIN (all shared, conflicts may occur)")
			}
			classDict.U.log("[PL] LOADING WITH PARAMETERS:", classDict. U.bin.structureToString(context.parameters));
			classDict.Ldr.load(LOADABLEURL.url,null,swfLoaded,null,{},classDict.Ldr.behaviours.loadOverwrite,classDict.Ldr.defaultValue,classDict.Ldr.defaultValue,0,context);
			xmlPool = [];
		}
		
		private function swfLoaded(v:String):void
		{
			classDict.U.log('swf loaded', v);
			configProcessor.saveFile = null;
			swfLoaderInfo = classDict.Ldr.loaderInfos[v];
		
			//overlap = f.parent.resolvePath('..');
			overlap = LOADABLEURL.url;
			var i:int = overlap.lastIndexOf('/');
			var j:int = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			overlap = overlap.substring(0,i);
			i = overlap.lastIndexOf('/');
			j = overlap.lastIndexOf("\\");
			i = (i > j ? i : j);
			var overlap2:String = overlap.substring(0,i);
			classDict.U.log('resolved dir overlap', overlap);
			
			if(swfLoaderInfo != null) // this assumes concept of loading swfs with
									// library embded in. the one which load own
									// on runtime - merge can't be done as at insantiation
									// time the don't have it
			{
				classDict.U.log("MERGE LIBRARIES ATTEMPT");
				var ldr:Class;
				if(swfLoaderInfo.applicationDomain.hasDefinition("axl.utils::Ldr"))
					ldr= swfLoaderInfo.applicationDomain.getDefinition("axl.utils::Ldr") as Class;
				if(ldr)
				{
					classDict.U.log("Ldr CLASS detected");
					ldr.defaultPathPrefixes.unshift(overlap);
					ldr.defaultPathPrefixes.unshift(overlap2);
					classDict.U.log("NOW swfLoaderInfo PATH PREFIXES", ldr.defaultPathPrefixes);
				}
				else
				{
					classDict.U.log("Ldr CLASS NOT FOUND");
				}
			}
			
			classDict.Ldr.defaultPathPrefixes.unshift(overlap);
			classDict.Ldr.defaultPathPrefixes.unshift(overlap2);
			classDict.U.log("NOW PromoLoader PATH PREFIXES", classDict.Ldr.defaultPathPrefixes);
			
			var u:* = classDict.Ldr.getAny(v);
			var o:DisplayObject = u as DisplayObject;
			if(o == null)
			{
				classDict.U.msg("Loaded content is not displayable");
				classDict.Ldr.unload(v);
				tracker.track_event('fail',LOADABLEURL.url);
				windowRecent.removeRowContaining(LOADABLEURL.url);
				return;
			}
			
			if(swfLoaderInfo != null)
			{
				OBJECT = o;
				OBJECT.y = barDesiredHeight;
				OBJECT.addEventListener(Event.ADDED, oElementAdded);
				classDict.U.msg(LOADABLEURL.url + ' LOADED!');
				windowRecent.registerLoaded(LOADABLEURL.url);
				
				if(changeConsoleContextToLoadedContent && classDict. U.bin != null)
					classDict.U.bin.parser.changeContext(o);
				tracker.track_event('loaded',LOADABLEURL.url);
				if(bar.cboxAutoSize.selectedLabel == 'auto')
				{
					this.stage.stageWidth = swfLoaderInfo.width;
					this.stage.stageHeight = swfLoaderInfo.height + barDesiredHeight;
				}
				else if(bar.cboxAutoSize.selectedLabel == 'scale')
				{
					onResize();
				}
				if(swfLoaderInfo.contentType == 'application/x-shockwave-flash')
				{
				}
			}
			this.addChildAt(o,bg && bg.parent ? 1 : 0);
		}
		
		protected function oElementAdded(e:Event):void
		{
			var cn:String = flash.utils.getQualifiedClassName(e.target);
			if(cn.match('MainCallback') || cn.match('OfferRoot'))
			{
				OBJECT.removeEventListener(Event.ADDED, oElementAdded);
				classDict.U.bin.parser.changeContext(e.target);
			}
		}		
		
		private function pasteEventParse():void
		{
			var ff:File, uu:URLRequest;
			if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{ 
				var arr:Array = Clipboard.generalClipboard.formats;
				var o:Array = Clipboard.generalClipboard.getData(arr[0]) as Array;
				if(o != null && o.length == 1)
				{
					ff = o.pop();
					ff.resolvePath('.');
					LOADABLEURL = new URLRequest(ff.url); 
					loadContent();
				}
				else
				{
					classDict.U.msg("Can't read this file");
					return;
				}
			}
			else if(Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
			{ 
				var text:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String; 
				classDict.U.log('link paste', text);
				text = text.replace(/^\s*/i,'');
				text = text.replace(/\s*$/i,'');
				var matched:Array = text.match(/\S+.swf($|\s)/i);
				if(matched && matched.length > 0)
				{
					try {uu= new URLRequest(text) }
					catch (e:Error) { classDict. U.msg(e.message) };
					if(uu == null)
					{
						classDict.U.msg("Can't read this link");
						return 
					}
					LOADABLEURL = uu;
					loadContent();
				}
				else
					classDict.U.msg('no link found');
			} 
		}
		
		private function getConfigXML():XML { return xconfig }
		private function somethingLoaded():void
		{
			var xmls:Vector.<String> = classDict.Ldr.getNames(/\.xml/);
			for(var i:int = 0; i < xmls.length; i++)
			{
				var xn:String = xmls[i];
				var j:int = xmlPool.indexOf(xn);
				if(j < 0) // if its new
				{
					xmlPool.push(xn);
					var pt:XML = classDict.Ldr.getXML(xn);
					if(pt is XML && pt.hasOwnProperty('root') && pt.hasOwnProperty('additions'))
					{
						classDict.U.log(this, "NEW CONFIG DETECTED");
						xconfig = pt;
						break;
					}
				}
			}
		}
		
		// __________________________________________________________________ helpers
		public static function addGrouop(where:DisplayObjectContainer, ...args):void
		{
			while(args.length)
				where.addChild(args.shift());
		}
		private function arangeBar():void
		{
			if(bar != null && bar.parent != null)
				bar.arangeBar();
		}
	}
}