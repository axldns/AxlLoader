package com.promoloader.htmlBridge
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.utils.describeType;
	import com.promoloader.core.PromoLoader;

	public class HtmlEmbeder
	{
		private var hloader:HTMLLoader;
		private var template:String;
		private var cururl:String;
		private var htmlFileName:String = 'htmlTemplate.html';
		private var api:Object = {};
		private var pl:PromoLoader;
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
			PromoLoader.classDict.U.log("[PromoLoader][html][api][message]:", args);
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
			PromoLoader.classDict.U.log("GET PARAM IN AS3",p, 'found in context as', p);
			return f;
		}
		
		private function as3Reload():void
		{
			PromoLoader.classDict.U.log("RELOAD FROM JS");
			PromoLoader.classDict.Ldr.unload(htmlFileName);
			load(cururl);
		}
		private function log(...args):void
		{
			PromoLoader.classDict.U.log("[PromoLoader][html-LOG]:", args);
		}
		
		private function setDimensions(w:Number, h:Number):void
		{
		}
		
		
		

		protected function onHtmlComplete(e:Event):void
		{
			template = template.replace(/data=".+"/, 'data="'+cururl+'"');
			PromoLoader.classDict.U.log("htmltemplated");
			
			hloader.window.promoloaderAPI = api; 
			hloader.window.as3Reload = as3Reload;
			
			PromoLoader.classDict.U.log(e);
			if('init' in hloader.window || hloader.window.hasOwnProperty('init'))
				hloader.window.init();
			else
				PromoLoader.classDict.U.log("init out of scope");	
		
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
		}
		
		
		
		
		
		
		public function get htmlloader():HTMLLoader {return hloader }
		
		public function load(url:String):void
		{
			cururl = url;
			var f:File = File.desktopDirectory.resolvePath(htmlFileName);
			var fs:FileStream = new FileStream();
				fs.open(f, FileMode.READ);
			try {
				template = fs.readUTFBytes(fs.bytesAvailable);
				PromoLoader.classDict.U.log("template file read", template.length);
				hloader.loadString(template); 
			}
			catch(e:Object) {
				PromoLoader.classDict.U.log("html template could not be read", e);
			}
		}
		
		public function unload():void
		{
			if(hloader.parent)
				hloader.parent.removeChild(hloader);
		}
	}
}