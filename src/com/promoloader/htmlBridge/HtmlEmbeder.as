package com.promoloader.htmlBridge
{
	import com.promoloader.core.PromoLoader;
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;

	public class HtmlEmbeder
	{
		private var tname:String = '[HTMLLoader'+version+']';
		public const version:String='0.1'
			
		private var hloader:HTMLLoader;
		private var template:String;
		private var requestedAssetToEmbedURL:String;
		private var artefactsAddress:String = "http://axldns.com/test/";
		private var htmlFileName:String = 'htmlTemplate.html';
		private var bridgeFileName:String = 'Bridge.swf';
		private var api:Object = {};
		private var pl:PromoLoader;
		private var bridgeAddress:String;
		private var htmlTemplateAddress:String;

		private var templateDownloader:URLLoader;
		private var bridgeDownloader:URLLoader;
		
		public function HtmlEmbeder(instance:PromoLoader)
		{
			pl = instance;
			setupAPI();
			setupHTMLLoader();
		}
		
		private function setupAPI():void
		{
			log2(tname,"setupAPI");
			api.getParam = api_getParam;
			api.message = api_message;
			api.log = api_log;
			api.reload = api_reload;
			
		}
		
		private function setupHTMLLoader():void
		{
			log2(tname,"setupHTMLLoader");
			hloader = new HTMLLoader();
			hloader.placeLoadStringContentInApplicationSandbox = true;
			hloader.useCache = false;
			hloader.addEventListener(Event.COMPLETE, onHtmlComplete);
			hloader.addEventListener(Event.HTML_BOUNDS_CHANGE, onHtmlBoundsChange);
			hloader.addEventListener(Event.HTML_DOM_INITIALIZE, onHTMLDOMInitialize);
			hloader.addEventListener(HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, onJSException);
		}
		
		
		protected function onHtmlComplete(e:Event):void
		{
			log2(tname,"onHtmlComplete",e);
			
			
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
			hloader.window.console = {log : api_log};
			hloader.window.getParam = api_getParam;
			//hloader.window.loadBridge(JSON.stringify(pl.contextParameters));
		}
		
		protected function onHTMLDOMInitialize(e:Event):void
		{
			log2(tname,"onHTMLDOMInitialize",e);
			hloader.window.api_promoloader = api; 
		}
		
		protected function onHtmlBoundsChange(e:Event):void
		{
			log2(tname,"onHtmlBoundsChange",e, hloader.contentWidth, 'x', hloader.contentHeight);
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
		}
		
		protected function onJSException(e:HTMLUncaughtScriptExceptionEvent):void
		{
			log2(tname,"onJSException", e, e.exceptionValue, PromoLoader.classDict.U.bin.structureToString(e.stackTrace));
		}
		
		private function api_message(...args):void
		{
			log2(tname,"[API][message]:", args);
			var type:String = args.shift();
			switch(type)
			{
				case "[Bridge][ready]":
					if('loadswf' in hloader.window || hloader.window.hasOwnProperty('loadswf'))
					{
						log2(".window.loadswf");
						hloader.window.loadswf(requestedAssetToEmbedURL,JSON.stringify(pl.contextParameters));
					}
					else
					{
						log2("loadswf is not a function?");
					}
					break;
				case "[Bridge][dimensions]":
					var o:Object = JSON.parse(args.pop());
					pl.resizeWithRules(o.w, o.h);
					break;
			}
		}
		
		private function api_getParam(p:String):Object
		{
			log2(tname,"[api_getParam]", p);
			var f:Object = pl.contextParameters[p];
			return f;
		}
		
		private function api_reload():void
		{
			log2(tname,"[api_reload]");
			load(requestedAssetToEmbedURL);
			//hloader.reload();
			
		}
		private function api_log(...args):void
		{
			log2(tname,"[api_log]:", args);
		}
		
		private function log2(...args):void
		{
			PromoLoader.classDict.U.log.apply(null, args)
		}
		
		public function load(url:String):void
		{
			requestedAssetToEmbedURL = url;
			PromoLoader.classDict.Ldr.load();
			
			var f:File = File.applicationStorageDirectory.resolvePath(htmlFileName);
			var f2:File = File.applicationStorageDirectory.resolvePath(bridgeFileName);
			if(f.exists && f2.exists)
				readTemplate();
			else
				updateArtefacts(readTemplate);
			
			function readTemplate():void
			{
				if(!f.exists || !f2.exists)
				{
					PromoLoader.classDict.U.msg("html template could not be read");
					return
				}
				var fs:FileStream = new FileStream();
				try {
					fs.open(f, FileMode.READ);
					template = fs.readUTFBytes(fs.bytesAvailable);
					log2("template file read", f.nativePath);
					hloader.loadString(template); 
				}
				catch(e:Object) {
					log2("html template could not be read", e);
				}
			}
		}
		
		
		public function updateArtefacts(onComplete:Function=null):void
		{
			PromoLoader.classDict.Ldr.load([htmlFileName,bridgeFileName], onComplete,null,null,artefactsAddress,PromoLoader.classDict.Ldr.behaviours.downloadOnly,/.*/);
		}
		
		public function unload():void
		{
			if(hloader.parent)
				hloader.parent.removeChild(hloader);
		}
		
		public function get htmlloader():HTMLLoader {return hloader }
	}
}