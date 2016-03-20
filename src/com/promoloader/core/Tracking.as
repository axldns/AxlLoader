package com.promoloader.core
{
	import flash.filesystem.File;
	

	public class Tracking
	{
		
		private var exit:*;
		private var exitObject:Object;
		private var tracking:String = null;
		private var appUrl:String;
		
		private var userAgentData:String;
		private var netObject:Object;
		private var session:Number;
		private var version:String;
		
		
		public function Tracking(gatewayURL:String,appVersion:String)
		{
			tracking = gatewayURL;
			version = appVersion;
			exit = new PromoLoader.classDict.ConnectPHP('event');
			exitObject = getNetObject('exit');
			track_event('launch',null);
		}
		
		public function track_event(type:String,url:String=null):void
		{
			if(tracking == null)
				return;
			var p:* = new PromoLoader.classDict.ConnectPHP('event');
			p.sendData(getNetObject(type,url),completed,tracking);
			function completed():void { p.destroy(true); p = null}
		}
		private function get getAppUrl():String
		{
			if(appUrl == null)
				appUrl = File.applicationDirectory.nativePath;
			return appUrl;
		}
		private function get getUserAgentData():String
		{
			if(userAgentData == null)
				userAgentData = File.userDirectory.nativePath;
			return userAgentData;
		}
		private function get getSession():Number
		{
			if(isNaN(session))
				session = new Date().time;
			return session;
		}
		
		private function getNetObject(type:String,subURL:String=null):Object
		{
			if(netObject == null)
			{
				netObject = {
					appURL: getAppUrl,
					version : version,
					userAgent : getUserAgentData,
					session  : getSession
				}
			}
			netObject.subjectURL = subURL;
			netObject.type = type;
			return netObject;
		}
		
		
	}
}