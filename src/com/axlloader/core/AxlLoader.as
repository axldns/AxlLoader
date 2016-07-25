package com.axlloader.core
{
	import com.axlloader.htmlBridge.HtmlEmbeder;
	import com.axlloader.nativeWindows.WindowConsole;
	import com.axlloader.nativeWindows.WindowInfo;
	import com.axlloader.nativeWindows.WindowParameters;
	import com.axlloader.nativeWindows.WindowRecent;
	import com.axlloader.nativeWindows.WindowTimestamp;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.SyncEvent;
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
	
	import axl.utils.RSLLoader;

	[SWF(width="570")]
	
	public class AxlLoader extends Sprite
	{
		[Embed(source='../../../../axl.swf', mimeType='application/octet-stream')]
		private var AXL_LIBRARY:Class;
		
		[Embed(source='../../../../assets/bg-logo.png', mimeType='image/png')]
		private var bgImage:Class;
		
		//------------------------ VARIABLES -------------------------- //
		public static var classDict:Object = {};
		private static var xinstance:AxlLoader;
		//loading
		private var swfLoaderInfo:LoaderInfo;
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
		private var xwindowParameters:WindowParameters;
		private var xwindowInfo:WindowInfo;
		
		//elements
		private var xbar:TopBar;
		private var bg:Sprite;
		private var bgLogo:Bitmap;
		private var eventsManager:EventsManager;
		private var openFile:File;
		private var displayableText:TextField;
		private var dragNDrop:Sprite;
		public var htmlContent:HtmlEmbeder;
		
		private var OBJECT:DisplayObject;
		private var OBJECTREC:Rectangle = new Rectangle();
		
		private var xbarDesiredHeight:Number = 22;
		private var xbgColour:uint=0xf5f5f5;
		
		//tracking
		private var xVERSION:String = '0.2.23';
		private var tname:String = '[AxlLoader ' + xVERSION + ']';
		private var trackingURL:String;
		private var tracker:Tracking;
		
		//other
		private var lastScale:Number;
		private var U:Class;
		/** Determines to what application domain content is loaded. -1 copy of current; 0 current; 1 separate. */
		public var loadedContentDomainType:int = -1;
		
		//------------------------ VARIABLES -------------------------- //
		//------------------------ INITIAL SETUP -------------------------- //
		
		
		/** 1. Sets instance reference, requests AXL Library load. */
		public function AxlLoader()
		{
			xinstance = this;
			delegates = new Vector.<Function>();
			axlLoadAndBuild(); // 1.1
		}	
		
		/** 1.1 Loads AXL Library to separate application domain. */
		private function axlLoadAndBuild():void
		{
			var lloader:RSLLoader = new RSLLoader(this);
			lloader.domainType = lloader.domain.separated;
			lloader.libraryURLs = [AXL_LIBRARY];
			lloader.onReady = go;
			lloader.load();
			function go():void
			{
				classDict = lloader.classDictionary;
				onAXLAvailable(); // 2
			}
		}
		/** 2. Initializes project flow from loaded AXL Library classes, Builds GUI and runs delegates. */
		private function onAXLAvailable():void
		{
			U = classDict.U;
			U.fullScreen=false;
			U.onResize = onResize;
			U.init(this, 800,600, onAxlInitialised); // 2.a
			U.log(tname);
			
			buildBackground(); // 2.1
			buildBar(); // 2.2
			buildDisplayableTextField(); // 2.3
			buildWindows(); // 2.4
			runEventManager(); // 2.5
			delegatesEmpty(); // 2.6
		}
		
		/** 2.a Instantiates LiveArranger, starts listening for requestContextChange sync event */
		private function onAxlInitialised():void
		{
			new classDict.LiveArranger();
			stage.loaderInfo.sharedEvents.addEventListener("requestContextChange", onXrootSyncEvent);
		}
		/** Responds to <code>requestContextChange</code> SyncEvent. - changes console context to object passed in changeList */
		protected function onXrootSyncEvent(e:SyncEvent):void
		{
			log(tname + "SYNC EVENT requestContextChange:",e.changeList);
			U.bin.parser.changeContext(e.changeList.pop());
		}
		
		/** 2.1 Instantiates and adds to display list background sprite and logo */
		private function buildBackground():void
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
		}
		
		/** 2.2 Instantiates and top menu bar and adds it to display list. */
		private function buildBar():void
		{
			xbar = new TopBar();
			addChild(bar);
		}
		
		/** 2.3 Instantiates textfield that is used for displaying loaded textual files. */
		private function buildDisplayableTextField():void
		{
			displayableText = new TextField();
			displayableText.multiline = true;
			displayableText.border = true;
			displayableText.background = true;
			displayableText.backgroundColor = 0xeeeeee;
			displayableText.defaultTextFormat = new TextFormat("Arial", 12);
		}
		
		/** 2.4 Instantiates windows: Console, History, Timestamp Generator */
		private function buildWindows():void
		{
			xwindowConsole = new WindowConsole('Console');
			xwindowRecent = new WindowRecent('Recently loaded');
			xwindowParameters = new WindowParameters("Loader context parameters");
			//LAZY INSTANTIATION NOW
			//xwindowTimestamp = new WindowTimestamp('Timestamp Generator');
			//xwindowInfo = new WindowInfo("Info");
		}
		
		/** 2.5 Instantiates events manager (responds to various events related to loading and unloading content, hot keys etc.). Creates file instance
		 * for loading files. */
		private function runEventManager():void
		{
			eventsManager = new EventsManager();
			openFile = new File();
			openFile.addEventListener(Event.SELECT, eventsManager.onFileSelected);
		}
		
		/** 2.6 Executes all functions stacked in delegates vector and empties that vector. */
		private function delegatesEmpty():void
		{
			delegatesLock = false;
			while(delegates.length)
				delegates.shift()();
		}
		
		/** 2.6a Adds function to delegates vector if program is busy (delegatesLock flag) or executes it right away */
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
		
		/** Function to run from outside if new version detected ? This is wrong. Loaded content itself should detect if it's new version or not. */
		public function onVersionUpdate(oldVersion:String):void
		{
			delegate(Updater.updateFunction);
		}
		
		//------------------------ INITIAL SETUP -------------------------- //
		//------------------------ SIZING CONTENT -------------------------- //
		
		/** 3. SIZING<br>
		 * Sizes loaded content if available, re-arranges top bar, re-arranges background. 
		 * <br> Automatically called on:
		 * <ul>
		 * <li>stage / window resize event</li>
		 * <li>new content loaded</li>
		 * <li>changed value in top bar menu "auto-size" drop-down event</li>
		 * <li>on switching to html loader</li>
		 * <ul> */
		public function onResize():void
		{
			sizeObject(); // 3.1
			arangeBar(); // 3.2
			updateBg(); // 3.3
		}
		
		/**  3.1  Sizes loaded content according to current top bar menu auto size combo box value.
		 *  Distributes through sizeScale, sizeAuto, sizeFree methods. */
		private function sizeObject():void
		{
			if(OBJECT == null)
				return;
			switch(bar.cboxAutoSize.selectedLabel)
			{
				case 'scale': sizeScale(); break;
				case 'auto': sizeAuto(); break;
				case 'free': sizeFree(); break;
			}
		}
		/**  3.1.1 Responds to top bar menu auto size combo box value "free". Does not size loaded content, allows to resize window freely. */
		private function sizeFree():void
		{
			
			if(OBJECT is TextField)
			{
				displayableText.scaleX = displayableText.scaleY = 1;
				displayableText.wordWrap = false;
				displayableText.width = displayableText.textWidth + 5;
				displayableText.height =  stage.stageHeight-barDesiredHeight;
			}
		}
		/**  3.1.2 Responds to top bar menu auto size combo box value "auto". Sizes AxlLoader window to match loaded content dimensions (based on
		 * loaderInfo.width/height if available, htmlLoader width if available or scales the textfield if loaded content is textual. */
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
		
		/**  3.1.3 Responds to top bar menu auto size combo box value "scale". Modifies loaded content scale to match axl loader window dimensions.
		 * Resizing window causes resizng loaded content (aspect ratio is kept).  */
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
		
		/** 3.2 Requests bar re-arange */
		private function arangeBar():void
		{
			if(bar != null && bar.parent != null)
				bar.arangeBar();
		}
		
		/** 3.3 Re-draws background to cover stage, re-positiones logo on stage. */
		private function updateBg():void
		{
			if(bg == null) buildBackground();
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
		
		//------------------------ SIZING CONTENT -------------------------- //
		//------------------------ LOADING CONTENT -------------------------- //
		
		/**  4. LOADING<br>
		 * Checks request / file existance and returns or:<br>
		 *  <ul>
		 * <li>Requests unloading currently loaded content (<code>unloadAndReset</code>)</li>
		 * <li>Requests setting up loader context (<code>setupContext</code>)</li>
		 * <li>Requests setting up application domain for loading content(<code>setupDomain</code>)</li>
		 * <li>Requests loading content with either html bridge or reqular <code>axl.utils.Ldr.load</code> method</li>
		 * </ul> 
		 * Called automatically on: 
		 * <ul>
		 * <li>Invoke event (open associated file)</li>
		 * <li>(Drag and) Drop event</li>
		 * <li>File selection through top menu bar "open" option</li>
		 * <li>Selecting (double click) file from History Window</li>
		 * <li>On hot-keys pressed (ctrl/⌘ + r, ctrl/⌘  + [1-9])</li>
		 * <li>Paste link or paste file event</li>
		 * <li>Pressing ENTER key in one of the input fields in top bar menu</li>
		 * <ul>*/
		public function loadContent():void
		{
			if(LOADABLEURL == null)
			{
				U.msg("Nothing to load?");
				return;
			}
			if(!checkFileExistence()) // 4.1
			{
				U.msg("File doesn't exist");
				return;
			}
			unloadAndReset(); // 4.2
			setupContext(); // 4.3
			setupDomain(); // 4.4
			U.log(tname," LOADING WITH PARAMETERS:", classDict. U.bin.structureToString(context.parameters));
			if(preferHTMLLoader)
				this.loadWithHTMLBridge();
			else
				classDict.Ldr.load(LOADABLEURL.url,null,onContentLoaded,null,{},classDict.Ldr.behaviours.loadOverwrite,classDict.Ldr.defaultValue,classDict.Ldr.defaultValue,0,context);
			// 5
		}
		
		/** 4.1 <br>
		 * Checks if there is something to load. If it's web link - assumes file exists. 
		 * If it's file - checks its existence on disk. If it's directory - does non-recursive directory scan
		 * for files with "swf" extension, modifies URL to load if found, returns false otherwise */
		private function checkFileExistence():Boolean
		{
			if(LOADABLEURL.url.match("^http"))
				return true;
			var f:File = new  File(LOADABLEURL.url);
			if(!f.exists)
				return false;
			if(f.isDirectory)
			{
				var found:Boolean = false;
				var fil:Array;
				try {fil = f.getDirectoryListing() }
				catch(e:*){U.log(e)}
				if(!fil)
					return true;
				for(var i:int = fil.length; i-->0; )
				{
					var fa:File = fil[i] as File;
					if(fa == null)
						continue;
					if(fa.extension != null && fa.extension.toLowerCase() == 'swf')
					{
						setLoadableURL(new URLRequest(fa.url)); // 4.6
						return true;
					}
				}
				return false
			}
			return true;
		}
		
		/** 4.2 <br>
		 * Unloads loaded content (if loaded);
		 * <ul>
		 * <li>Removes loaded content from display list and nulls reference to it</li>
		 * <li>Clears Console Window if <code>clearLogEveryLoad = true</code></li>
		 * <li>Unloads all loaded contents via <code>axl.utils.Ldr.unloadAll</code> and htmlContent.unload. Disposes it. </li>
		 * <li>Changes console context back to AxlLoader</li>
		 * <li>Removes from stage anything that does not belong to AxlLoader</li>
		 * </ul> */
		public function unloadAndReset():void
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
			removeDragNDropOverlay();
			for(var i:int = 0; i< stage.numChildren;i++)
			{
				var c:DisplayObject = stage.getChildAt(i);
				if(c != this && c != this.parent)
					stage.removeChildAt(i--);
			}
		}
		
		/** 4.3 <br>
		 * Sets up brand new LoaderContext instance and assings standard and user defined LoaderContext.parameters;<br>
		 * <h4>Standard context parameters</h4>
		 * <ul>
		 * <li><b>fakeTimestamp</b> - timestamp taken from date set in top bar menu (bar displays time in local time, timestamp is UTC)</li>
		 * <li><b>loadedURL</b> - URL that loaded content has been loaded from. Deeply nested swfs or local context of assets may need it 
		 * - axlx framework xLauncher class uses it</li>
		 * <li><b>fileName</b> - file name of loaded content (query strings are removed)</li>
		 * </ul> 
		 * <h4>User defined context parameters</h4>
		 * User defined loader context parameters are taken from Context Parameters Window */
		private function setupContext():void
		{
			context =new LoaderContext(classDict.Ldr.policyFileCheck);
			var userParams:Object = windowParameters.getParams();
			for(var s:String in userParams)
				contextParameters[s] = userParams[s] is String ? userParams[s] : JSON.stringify(userParams[s]);
			contextParameters.fakeTimestamp = String(bar.dateComponent.timestampSec);
			contextParameters.fileName = U.fileNameFromUrl(LOADABLEURL.url,true);
			contextParameters.loadedURL =LOADABLEURL.url;
			context.parameters = contextParameters;
		}
		
		/** 4.4 <br>
		 * Sets up application domain for loader context. By defult loaded content is placed in copy of current application domain.
		 * This can cause an issues with fonts.<br> A.swf registers fonts under the name "fontsC", A.swf is unloaded, B.swf is loaded, B.swf tries
		 * to register different set of fonts under the same name "fontsC". This name is already taken, "fontsC" registered by A.swf are used in B.swf.
		 * It's beyond my knowledge how to free up applicationDomain from previously registered fonts. In this scenario user should restart AxlLoader
		 * before loading B.swf. Placing loaded content in separate application domain causes not rendering fonts at all. It's beyond my knowledge how 
		 * to overcome that harmlessly.
		 *  */
		private function setupDomain():void
		{
			if(loadedContentDomainType < 0)
			{
				context.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
				U.log(tname," LOADING TO COPY OF CURRENT APPLICATION DOMAIN (loaded content can use parent classes, parent can't use childs classes other way than via class dict)")
			}
			else if(loadedContentDomainType > 0)
			{
				context.applicationDomain = new ApplicationDomain(null);
				U.log(tname,"LOADING TO BRAND NEW APPLICATION DOMAIN (loaded content can't use parent's classes, parent can't use childs classes other way than via class dict. Watch your fonts.")
			}
			else if(loadedContentDomainType == 0)
			{
				context.applicationDomain = ApplicationDomain.currentDomain;
				U.log(tname," LOADING TO CURRENT APPLICATION DOMAIN (all shared, conflicts may occur)")
			}
		}
		
		/** 4.5 <br>
		 * Called from EventsManager when error occures during loading with regular Ldr. Unloads all contents, removes related event listeners, nulls out 
		 * loaderInfo, requests loading content with htmlLoader, adds htmlLoader to display lists, re-aranges stage, and changes console context to htmlLoader.*/
		public function switchToHTMLLoader():void
		{
			U.log("SWITCHING TO HTMLLOADER");
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
		
		/** 4.6 <br>
		 * Sets LOADABLEURL variable used for final load requests. Can be modfied on Dragging directory onto AxlLoader.<br>
		 * Automatiaclly called on:
		 * <ul>
		 * <li>Invoke event (open associated file)</li>
		 * <li>(Drag and) Drop event</li>
		 * <li>File selection through top menu bar "open" option</li>
		 * <li>Selecting (double click) file from History Window</li>
		 * <li>Paste link or paste file event</li>
		 * </ul>
		 *  */
		public function setLoadableURL(invokedFileUrlRequest:URLRequest):void
		{
			LOADABLEURL = invokedFileUrlRequest;
		}
		
		//------------------------ LOADING CONTENT -------------------------- //
		//------------------------ CONTENT LOADED -------------------------- //
		
		/** 5. Content Loaded<br>
		 * Parses loaded content to verify it's type and add it to display list.
		 * <ul>
		 * <li>Requests store content link in cookie for History Window</li>
		 * <li>Parses loaderInfo of loaded content (listens for uncaught error events, gets dimensions and content type info)</li>
		 * <li>If loaded content is not a display object - tries to turn it into one of supported forms (textual, sound). Returns and alerts user on fail</li>
		 * <li>If loaded content is displayable, adds it to the display list, resizes window or content (depending on settings), and changes 
		 * console context to that content's context</li>
		 * </ul>
		 * Called automatically from Ldr callback. Expects filename as a parameter.
		 * */
		private function onContentLoaded(v:String):void
		{
			//INFO
			var u:* = classDict.Ldr.getAny(v);
			
			log('content LOADED', LOADABLEURL.url, "\nTYPE:",flash.utils.describeType(u).@name,"\nINFO:",swfLoaderInfo ? swfLoaderInfo.contentType : 'not available');
			windowRecent.registerLoaded(LOADABLEURL.url);
			resolveSWFLoaderInfo(v); // 5.1
			
			OBJECT = u as DisplayObject;
			if(OBJECT == null)
			{
				OBJECT = resolveNonDisplayableObject(v,u) as DisplayObject; // 5.2
			}
			if(OBJECT == null)
			{
				onContentNotDisplayable(); // 5.3
				return;
			}
			// BY THIS POINT OBJECT IS VALID DIPLAY OBJECT
		
			OBJECT.y = barDesiredHeight;
			addToDisplayList(OBJECT); // 5.4
			onResize();
			if(changeConsoleContextToLoadedContent && classDict. U.bin != null)
				U.bin.parser.changeContext(OBJECT);
		}
		
		/** 5.1 <br>Looks for loaderInfo of loaded content, listens for uncaughtErrorEvents on it if found. */
		private function resolveSWFLoaderInfo(v:String):void
		{
			swfLoaderInfo = classDict.Ldr.loaderInfos[v];
			if(swfLoaderInfo != null)
			{
				U.log("got loader info", swfLoaderInfo.width, swfLoaderInfo.height);
				swfLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, eventsManager.onLoaderError);
			}
		}
		/** 5.2 <br>Tries tu turn loaded content that is not a display object to one of supported forms:
		 * <li>Puts raw data as unicode bytes in flash TextField</li>
		 * <li>Puts text, JSON and XML in flash TextField</li>
		 * <li>Puts Sound (mp3) in Sound spectrum container</li>
		 * <li>Unloads loaded with Ldr content and Falls back to htmlLoader if file content doesn't match supported forms</li>
		 *  */
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
				else
					d = String(obj);
				displayableText.text = d;
				return displayableText;
			}
			else if(obj is Sound)
			{
				return SoundParser.newSound(obj as Sound);
			}
			else
			{
				try {d = JSON.stringify(obj)}
				catch(e:*) { d = null}
				if(d != null && d != "null")
				{
					displayableText.text = d;
					return displayableText;
				}
			}
			classDict.Ldr.unload(objName);
			return loadWithHTMLBridge(); // 5.2.1
		}
		
		/** 5.2.1 <br>Instantiates and pre-sets up htmlLoader, passes load request to it*/
		private function loadWithHTMLBridge():HTMLLoader
		{
			if(!htmlContent)
				htmlContent = new HtmlEmbeder(this);
			htmlContent.load(LOADABLEURL.url);
			htmlContent.htmlloader.y =barDesiredHeight;
			return htmlContent.htmlloader;
		}
		
		/** 5.3 <br>Alerts user that requested content is not displayable */
		private function onContentNotDisplayable():void
		{
			U.msg("Loaded content is not displayable.");
		}
		
		/** 5.4 <br>Attempts to add loaded content to display list. For ActionScript 2 projects Loader instance is added,
		 * content itself in other cases. Alerts user on failure. */
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
		
		//------------------------ CONTENT LOADED -------------------------- //
		//------------------------ OTHER EVENTS MANAGER HANDLERS -------------------------- //
		
		/** Allows to restore main window if closed while other windows are on */
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
		
		/** Adds drag / drop events receiver on top of html content */
		public function addDragNDropOverlay():void
		{
			if(!htmlContent || !htmlContent.htmlloader.parent)
				return
			if(!dragNDrop)
			{
				dragNDrop = new Sprite();
				dragNDrop.y = barDesiredHeight;
			}
			dragNDrop.graphics.clear();
			dragNDrop.graphics.beginFill(0xff5500,0.05);
			dragNDrop.graphics.drawRect(0,0,htmlContent.htmlloader.width, htmlContent.htmlloader.height);
			if(!this.contains(dragNDrop))
				this.addChild(dragNDrop);
		}
		/** removes drag / drop events receiver from display list. */
		public function removeDragNDropOverlay():void
		{
			if(dragNDrop && dragNDrop.parent)
			{
				dragNDrop.parent.removeChild(dragNDrop);
			}
		}
		/** Opens up file browser to select content for loading */
		public function browseForFile():void
		{
			openFile.browseForOpen("open");
		}
		
		//------------------------ OTHER EVENTS MANAGER HANDLERS -------------------------- //
		//------------------------ OTHER PUBLIC API -------------------------- //
		
		public function log(...args):void {	U.log.apply(null,args) }
		public function get bar():TopBar { return xbar }
		public function get contextParameters():Object { return xcontextParameters }
		public function get VERSION():String { return xVERSION }
		public function get barDesiredHeight():Number {	return xbarDesiredHeight }
		
		public function get mainWindow():NativeWindow { return xmainWindow  }
		public function get windowRecent():WindowRecent { return xwindowRecent }
		public function get windowConsole():WindowConsole { return xwindowConsole }
		public function get windowParameters():WindowParameters	{ return xwindowParameters}
		
		public function get windowTimestamp():WindowTimestamp 
		{ 
			if(xwindowTimestamp==null){xwindowTimestamp = new WindowTimestamp('Timestamp Generator')} 
			return xwindowTimestamp
		}
		
		public function get windowInfo():WindowInfo
		{ 
			if(xwindowInfo==null){xwindowInfo = new WindowInfo('Info')} 
			return xwindowInfo
		}
		public static function get instance():AxlLoader { return xinstance }
		
	}
}