
package com.promoloader.core
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
		private var loaderClass:Class;
		private var binAgentClass:Class;
		private var liveArangerClass:Class;
		private var tickLimit:int=4
		public function LegacyController()
		{
			tname = '[PromoLoader - LegacyController 0.0.2]';
		}
		
		public function onSwfLoaded(swfLoaderInfo:LoaderInfo, overlap:String, overlap2:String):void
		{
			PromoLoader.classDict.U.log(tname,"MERGE LIBRARIES ATTEMPT");
			if(swfLoaderInfo.applicationDomain.hasDefinition(classLoader))
				loaderClass= swfLoaderInfo.applicationDomain.getDefinition(classLoader) as Class;
			if(loaderClass)
			{
				PromoLoader.classDict.U.log(tname,"Ldr CLASS detected");
				loaderClass.defaultPathPrefixes.unshift(overlap);
				loaderClass.defaultPathPrefixes.unshift(overlap2);
				PromoLoader.classDict.U.log(tname,"NOW swfLoaderInfo PATH PREFIXES:\n# ", loaderClass.defaultPathPrefixes.join('\n# '));
			}
			else
			{
				PromoLoader.classDict.U.log(tname,"Ldr CLASS NOT FOUND");
			}
			
			if(swfLoaderInfo.applicationDomain.hasDefinition(classBinAgent))
				binAgentClass= swfLoaderInfo.applicationDomain.getDefinition(classBinAgent) as Class;
			
			if(binAgentClass)
			{
				PromoLoader.classDict.U.log(binAgentClass,'BinAgent class detected.VERSION?', 'VERSION' in binAgentClass ? binAgentClass : undefined);
				if('VERSION' in binAgentClass)
					return
				PromoLoader.classDict.U.log(tname,"Legacy BinAgent CLASS detected", binAgentClass, binAgentClass.instance);
				if(binAgentClass.instance)
				{
					PromoLoader.classDict.U.log(tname,"Legacy BinAgent instance exists, merge attempt");
					mergeBinAgent(binAgentClass.instance);
				}
				else
				{
					PromoLoader.classDict.U.log(tname,"Legacy BinAgent class exist BUT instance DOES NOT exists, legacy detector interval");
					tickLimit = 4;
					binAgentDetectorID = setInterval(binAgentDetectorTICK,500,binAgentClass);
				}
			}
			else
			{
				PromoLoader.classDict.U.log(tname,"BinAgent CLASS NOT FOUND");
			}
			
			if(swfLoaderInfo.applicationDomain.hasDefinition(classAranger))
				liveArangerClass= swfLoaderInfo.applicationDomain.getDefinition(classAranger) as Class;
			
			if(liveArangerClass && !liveArangerClass.hasOwnProperty('VERSION'))
			{
				PromoLoader.classDict.U.log(tname, classAranger, "CLASS detected", liveArangerClass, liveArangerClass.instance);
				if(liveArangerClass.instance)
				{
					PromoLoader.classDict.U.log(tname,classAranger,"instance exists, too late to kill it");
				}
				else
				{
					PromoLoader.classDict.U.log(tname,classAranger, "instance DOES NOT exists, TRY TO STUFF IT");
					try { liveArangerClass.instance = new LiveAranger() }
					catch(e:*) {PromoLoader.classDict.U.log('stuffing failed')}
				}
			}
			else
			{
				PromoLoader.classDict.U.log(tname,classAranger,"CLASS NOT FOUND");
			}
		}
	
		private function mergeBinAgent(ba:Object):void
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
		
		private function binAgentDetectorTICK(bac:Class):void
		{
			PromoLoader.classDict.U.log(tname,'detectd bin agent instance:', bac.instance);
			if(bac.instance|| this.tickLimit-- < 0)
			{
				clearInterval(this.binAgentDetectorID);
				//dump on stage to get stack trace;
				if(bac.instance)
				{
					bac.instance.addEventListener(Event.ADDED_TO_STAGE, iats);
					PromoLoader.classDict.U.STG.addChild(bac.instance as DisplayObject);
				}
			}
			function iats(e:Event):void {
				bac.instance.removeEventListener(Event.ADDED_TO_STAGE, iats);
				mergeBinAgent(bac.instance);
			}
		}
		
		public function onSwfUnload():void
		{
			binAgentClass = null;
			loaderClass = null;
			liveArangerClass = null;
			if(loaderClass != null)
				loaderClass.defaultPathPrefixes = [];
			flash.utils.clearInterval(this.binAgentDetectorID);
		}
	}
}