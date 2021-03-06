/**
 *
 * AxlLoader
 * Copyright 2015-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package com.axlloader.htmlBridge
{
	import com.axlloader.core.AxlLoader;
	
	import flash.events.Event;
	import flash.events.HTMLUncaughtScriptExceptionEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.utils.setTimeout;

	public class HtmlEmbeder
	{
		public const version:String='0.3';
		private var tname:String = '[HTMLLoader'+version+']';
			
		private var hloader:HTMLLoader;
		private var template:String;
		private var requestedAssetToEmbedURL:String;
		private var artefactsAddress:String = AxlLoader.remoteAssetsURL;
		private var htmlFileName:String = 'htmlTemplate.html';
		private var bridgeFileName:String = 'Bridge.swf';
		private var api:Object = {};
		private var pl:AxlLoader;
		private var bridgeAddress:String;
		private var htmlTemplateAddress:String;

		private var templateDownloader:URLLoader;
		private var bridgeDownloader:URLLoader;
		private var U:Class;
		public function HtmlEmbeder(instance:AxlLoader)
		{
			pl = instance;
			U = AxlLoader.classDict.U;
			setupAPI();
			setupHTMLLoader();
		}
		
		private function setupAPI():void
		{
			U.log(tname,"setupAPI");
			api.getParam = api_getParam;
			api.message = api_message;
			api.log = api_log;
			api.reload = api_reload;
			api.dimensions = api_dimensions;
			api.resizeToBridge = api_resizeToBridge;
		}
		
		private function setupHTMLLoader():void
		{
			U.log(tname,"setupHTMLLoader");
			hloader = new HTMLLoader();
			hloader.placeLoadStringContentInApplicationSandbox = true;
			hloader.useCache = false;
			hloader.cacheResponse = false;
			hloader.paintsDefaultBackground = false;
			hloader.addEventListener(Event.COMPLETE, onHtmlComplete);
			hloader.addEventListener(Event.HTML_BOUNDS_CHANGE, onHtmlBoundsChange);
			hloader.addEventListener(Event.HTML_DOM_INITIALIZE, onHTMLDOMInitialize);
			hloader.addEventListener(HTMLUncaughtScriptExceptionEvent.UNCAUGHT_SCRIPT_EXCEPTION, onJSException);
		}
		
		protected function onHtmlComplete(e:Event):void
		{
			U.log(tname,"onHtmlComplete",e);
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
			hloader.window.console = {log : api_log};
			hloader.window.getParam = api_getParam;
			//hloader.window.loadBridge(JSON.stringify(pl.contextParameters));
		}
		
		protected function onHTMLDOMInitialize(e:Event):void
		{
			U.log(tname,"onHTMLDOMInitialize",e);
			hloader.window.api_promoloader = api; 
		}
		
		protected function onHtmlBoundsChange(e:Event):void
		{
			U.log(tname,"onHtmlBoundsChange",e, hloader.contentWidth, 'x', hloader.contentHeight);
			if(pl.bar.cboxAutoSize.selectedLabel == 'auto')
			{
				//this.hloader.width = this.hloader.contentWidth;
				//this.hloader.height = this.hloader.contentHeight;
				//pl.stage.stageWidth = hloader.x + hloader.width;
				//pl.stage.stageHeight = hloader.y + hloader.height + pl.barDesiredHeight;
				flash.utils.setTimeout(goOutside, 20); // bug !~if width and height is being set here, event is not fired!
			}
			else if(pl.bar.cboxAutoSize.selectedLabel == 'scale')
			{
				pl.onResize();
			}
		}
		
		private function goOutside():void
		{
			//U.log("OUTSIDE", hloader.width, hloader.height, hloader.contentWidth, hloader.contentHeight);
			hloader.width = hloader.contentWidth;
			hloader.height = hloader.contentHeight;
		}
		
		protected function onJSException(e:HTMLUncaughtScriptExceptionEvent):void
		{
			U.log(tname,"onJSException", e, e.exceptionValue, U.bin.structureToString(e.stackTrace));
		}
		
		private function api_message(...args):void
		{
			U.log(tname,"[API][message]:", args);
			var type:String = args.shift();
			switch(type)
			{
				case "[Bridge][ready]":
					if('loadswf' in hloader.window || hloader.window.hasOwnProperty('loadswf'))
					{
						hloader.window.loadswf(requestedAssetToEmbedURL,JSON.stringify(pl.contextParameters));
					}
					else
					{
						U.log("loadswf is not a function?");
					}
					break;
			}
		}
		
		private function api_getParam(p:String):Object
		{
			U.log(tname,"[api_getParam]", p);
			var f:Object = pl.contextParameters[p];
			return f;
		}
		
		private function api_reload():void
		{
			U.log(tname,"[api_reload]");
			load(requestedAssetToEmbedURL);
			//hloader.reload();
			
		}
		private function api_log(...args):void
		{
			U.log(tname,"[api_log]:", args);
		}
		
		private function api_dimensions():Array
		{
			var res:Array = [pl.bar.cboxAutoSize.selectedLabel, pl.stage.stageWidth, pl.stage.stageHeight - pl.barDesiredHeight];
			U.log(tname, '[api_dimensions]', res);
			return res;
		}
		
		private function api_resizeToBridge(w:Number,h:Number):void
		{
			U.log("api_resizeToBridge", w,h, pl.bar.cboxAutoSize.selectedLabel == 'auto');
			if(pl.bar.cboxAutoSize.selectedLabel == 'auto')
			{
				hloader.width = w;
				hloader.height = h;
				pl.onResize();
			}
		}
		
		public function load(url:String):void
		{
			requestedAssetToEmbedURL = url;
		
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
					U.msg("html template could not be read");
					return
				}
				var fs:FileStream = new FileStream();
				try {
					fs.open(f, FileMode.READ);
					template = fs.readUTFBytes(fs.bytesAvailable);
					template = template.replace('data="Bridge.swf"', 'data="app-storage:/Bridge.swf"');
					U.log("template file read", f.nativePath);
					hloader.loadString(template); 
				}
				catch(e:Object) {
					U.log("html template could not be read", e);
				}
			}
		}
		
		public function updateArtefacts(onComplete:Function=null):void
		{
			AxlLoader.classDict.Ldr.load([htmlFileName,bridgeFileName], onComplete,null,null,artefactsAddress,AxlLoader.classDict.Ldr.behaviours.downloadOnly,/.*/);
		}
		
		public function unload():void
		{
			if(hloader.parent)
				hloader.parent.removeChild(hloader);
		}
		
		public function get htmlloader():HTMLLoader {return hloader }
		
		public function sizeScale(w:Number, h:Number):void
		{
			hloader.width = w;
			hloader.height = h;
			if(hloader.window && 'promoloaderResize' in hloader.window)
			{
				hloader.window.promoloaderResize(w,h);
			}
		}
	}
}