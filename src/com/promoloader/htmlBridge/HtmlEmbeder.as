package com.promoloader.htmlBridge
{
	import com.promoloader.core.PromoLoader;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;

	public class HtmlEmbeder
	{
		private var hloader:HTMLLoader;
		private var template:String;
		private var cururl:String;
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
			hloader = new HTMLLoader();
			hloader.placeLoadStringContentInApplicationSandbox = true;
			hloader.addEventListener(Event.COMPLETE, onHtmlComplete);
			api.getParam = getParamApi;
			api.setDimensions = setDimensions;
			api.message = onIncommingMessage;
			api.log = log;
		}
		
		private function onIncommingMessage(...args):void
		{
			log2("[PromoLoader][html][api][message]:", args);
			var type:String = args.shift();
			switch(type)
			{
				case "[Bridge][ready]":
					if('loadswf' in hloader.window || hloader.window.hasOwnProperty('loadswf'))
					{
						hloader.window.loadswf(cururl,JSON.stringify(pl.contextParameters));
					}
					else
					{
						log("loadswf is not a function?");
					}
					break;
				case "[Bridge][dimensions]":
					var o:Object = JSON.parse(args.pop());
					pl.resizeWithRules(o.w, o.h);
					break;
			}
		}
		
		private function getParamApi(p:String):Object
		{
			var f:Object = pl.contextParameters[p];
			log2("GET PARAM IN AS3",p, 'found in context as', p);
			return f;
		}
		
		private function as3Reload():void
		{
			log2("RELOAD FROM JS");
			PromoLoader.classDict.Ldr.unload(htmlFileName);
			load(cururl);
		}
		private function log(...args):void
		{
			log2("[PromoLoader][html-LOG]:", args);
		}
		private function log2(...args):void
		{
			PromoLoader.classDict.U.log.apply(null, args)
		}
		
		
		private function setDimensions(w:Number, h:Number):void
		{
		}

		protected function onHtmlComplete(e:Event):void
		{
			template = template.replace(/data=".+"/, 'data="'+cururl+'"');
			log2("htmltemplated");
			
			hloader.window.promoloaderAPI = api; 
			hloader.window.as3Reload = as3Reload;
			
			log2(e);
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
		}
		
		public function get htmlloader():HTMLLoader {return hloader }
		
		public function load(url:String):void
		{
			cururl = url;
			PromoLoader.classDict.Ldr.load();
			//var cbs:String = '?cb=' + String(new Date().time);
			
			
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
					log2("template file read", template.length);
					//template = template.replace(/data=".+"/, 'data="'+f2.nativePath+'"');
					//log2("now template:\n", template);
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
	}
}