package
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.utils.describeType;

	public class HtmlEmbeder
	{
		private var hloader:HTMLLoader;
		private var temp:String;
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
			api.message = messageInterpreter;
			api.log = log;
		}
		
		private function messageInterpreter(...args):void
		{
			PromoLoader.classDict.U.log("[PromoLoader][html][api][message]:", args);
			var type:String = args.shift();
			switch(type)
			{
				case "[Bridge][ready]":
				hloader.window.loadswf(cururl,JSON.stringify(pl.contextParameters));
					break;
				case "[Bridge][dimensions]":
					var o:Object = JSON.parse(args.pop());
					pl.resizeWithRules(o.w, o.h);
					break;
			}
		}
		private function log(...args):void
		{
			PromoLoader.classDict.U.log("[PromoLoader][html][api][LOG]:", args);
		}
		
		private function setDimensions(w:Number, h:Number):void
		{
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
		public function get htmlloader():HTMLLoader {return hloader }

		protected function onHtmlComplete(e:Event):void
		{
			temp = temp.replace(/data=".+"/, 'data="'+cururl+'"');
			PromoLoader.classDict.U.log("htmltemplated");
			
			hloader.window.promoloaderAPI = api; 
			hloader.window.as3Reload = as3Reload;
			
			PromoLoader.classDict.U.log(e);
			if('init' in hloader.window || hloader.window.hasOwnProperty('init'))
				hloader.window.init();
			else
				PromoLoader.classDict.U.log("init out of scope");
			
			/*if('loadswf' in hloader.window || hloader.window.hasOwnProperty('loadswf'))
				hloader.window.loadswf(cururl);
			else
				PromoLoader.classDict.U.log("loadswf out of scope");*/
			
		
			this.hloader.width = this.hloader.contentWidth;
			this.hloader.height = this.hloader.contentHeight;
		}
		
		
		public function load(url:String):void
		{
			var f:File = File.desktopDirectory.resolvePath(htmlFileName);
			cururl = url;
			PromoLoader.classDict.Ldr.load(f.url, templateLoaded);
			function templateLoaded():void
			{
			
				var str:Object = PromoLoader.classDict.Ldr.getAny(htmlFileName);
				if(str is String || str is XML)
				{
					if(str is XML)
						str  = str.toXMLString();
					temp = str as String;
					
					hloader.loadString(temp);
				}
				else
					PromoLoader.classDict.U.log("htmltemplate COULD NOT BE FOUND", flash.utils.describeType(str));
			}
		}
		
		public function unload():void
		{
			if(hloader.parent)
				hloader.parent.removeChild(hloader);
		}
	}
}