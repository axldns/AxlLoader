
package
{
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import axl.utils.LiveAranger;

	public class LegacyController
	{
		private var tname:String;
		private var binAgentDetectorID:uint;
		private var classLoader:String = "axl.utils::Ldr"
		private var classBinAgent:String="axl.utils.binAgent::BinAgent";
		private var classAranger:String="axl.utils::LiveAranger";
		public function LegacyController()
		{
			tname = '[PromoLoader - LegacyController]';
		}
		
		public function onSwfLoaded(swfLoaderInfo:LoaderInfo, overlap:String, overlap2:String):void
		{
			PromoLoader.classDict.U.log(tname,"MERGE LIBRARIES ATTEMPT");
			var ldr:Class;
			if(swfLoaderInfo.applicationDomain.hasDefinition(classLoader))
				ldr= swfLoaderInfo.applicationDomain.getDefinition(classLoader) as Class;
			if(ldr)
			{
				PromoLoader.classDict.U.log(tname,"Ldr CLASS detected");
				ldr.defaultPathPrefixes.unshift(overlap);
				ldr.defaultPathPrefixes.unshift(overlap2);
				PromoLoader.classDict.U.log(tname,"NOW swfLoaderInfo PATH PREFIXES:\n# ", ldr.defaultPathPrefixes.join('\n# '));
			}
			else
			{
				PromoLoader.classDict.U.log(tname,"Ldr CLASS NOT FOUND");
			}
			
			var bac:Class;
			if(swfLoaderInfo.applicationDomain.hasDefinition(classBinAgent))
				bac= swfLoaderInfo.applicationDomain.getDefinition(classBinAgent) as Class;
			
			if(bac)
			{
				PromoLoader.classDict.U.log(tname,"BinAgent CLASS detected", bac, bac.instance);
				if(bac.instance)
				{
					PromoLoader.classDict.U.log(tname,"BinAgent instance exists, merge attempt");
					mergeBinAgent(bac.instance);
				}
				else
				{
					PromoLoader.classDict.U.log(tname,"BinAgent instance DOES NOT exists, legacy detector interval");
					binAgentDetectorID = setInterval(binAgentDetectorTICK,500,bac);
				}
			}
			else
			{
				PromoLoader.classDict.U.log(tname,"BinAgent CLASS NOT FOUND");
			}
			var arang:Class;
			if(swfLoaderInfo.applicationDomain.hasDefinition(classAranger))
				arang= swfLoaderInfo.applicationDomain.getDefinition(classAranger) as Class;
			
			if(arang)
			{
				PromoLoader.classDict.U.log(tname, classAranger, "CLASS detected", arang, arang.instance);
				if(arang.instance)
				{
					PromoLoader.classDict.U.log(tname,classAranger,"instance exists, too late to kill it");
				}
				else
				{
					PromoLoader.classDict.U.log(tname,classAranger, "instance DOES NOT exists, TRY TU STUFF IT");
					arang.instance = new LiveAranger();
				}
			}
			else
			{
				PromoLoader.classDict.U.log(tname,classAranger,"CLASS NOT FOUND");
			}
		}
	
		private function mergeBinAgent(ba:Object):void
		{
			if(ba.hasOwnProperty('VERSION'))
			{
				//trace('found new one, nothing to ddo');
			}
			else
			{
				if(ba.hasOwnProperty('allowGestureOpen'))
					ba.allowGestureOpen = false;
				if(ba.hasOwnProperty('allowKeyboardOpen'))
					ba.allowKeyboardOpen = false;
				if(ba.numChildren > 0)
				{
					var s:String = '[MERGED]\n';
					for(var i:int = 0; i < ba.numChildren; i++)
					{
						var t:TextField = ba.getChildAt(i) as TextField;
						if(t)
						{
							s+= t.text;
						}
					}
					s += '\n[/MERGED]';
					PromoLoader.classDict.U.log(s);
				}
				if(ba.hasOwnProperty('regularTraceToo'))
					ba.regularTraceToo = false;
				if(ba.hasOwnProperty('externalTrace'))
					ba.externalTrace = PromoLoader.classDict.U.log;
				if(ba.hasOwnProperty('isOpen'))
					ba.isOpen = false;
				if(ba.parent)
					ba.parent.removeChild(ba);
			}
		}
		
		private function binAgentDetectorTICK(bac:Class):void
		{
			PromoLoader.classDict.U.log(tname, bac.instance);
			if(bac.instance)
			{
				clearInterval(this.binAgentDetectorID);
				//dump on stage to get stack trace;
				bac.instance.addEventListener(Event.ADDED_TO_STAGE, iats);
				PromoLoader.classDict.U.STG.addChild(bac.instance as DisplayObject);
			}
			function iats(e:Event):void {
				bac.instance.removeEventListener(Event.ADDED_TO_STAGE, iats);
				mergeBinAgent(bac.instance);
			}
		}
		
		public function onSwfUnload():void
		{
			flash.utils.clearInterval(this.binAgentDetectorID);
		}
	}
}