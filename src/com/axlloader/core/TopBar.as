package com.axlloader.core
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	
	import fl.controls.Button;
	import fl.controls.ComboBox;
	import fl.controls.TextInput;
	import fl.data.DataProvider;
	import fl.events.ComponentEvent;
	
	public class TopBar extends Sprite
	{
		private var xbtnConsole:Button;
		private var xbtnRecent:Button;
		private var xbtnReload:Button;
		private var xbtnLoad:Button;
		
		private var xdates:DateComponent;
		private var xcboxAutoSize:ComboBox;
		private var cookie:SharedObject;
		private var scaleModes:Array = [{label : "auto"}, {label : "scale"}, {label: "free"}];
		private var xbtnParameters:Button;
		private var xbtnInfo:Button;
		
		public function TopBar()
		{
			super();
			cookie = SharedObject.getLocal('bar');
			xdates = new DateComponent();
			
			xbtnLoad = new Button();
			btnLoad.label = 'Open';
			btnLoad.width = btnLoad.textField.textWidth + 15;
			
			
			xbtnReload = new Button();
			btnReload.label = 'Reload';
			btnReload.width = btnReload.textField.textWidth + 15;
			
			
			xbtnConsole = new Button();
			btnConsole.label = 'Console';
			btnConsole.width = xbtnConsole.textField.textWidth + 15;
			
			
			xbtnRecent = new Button();
			btnRecent.label = 'History';
			btnRecent.width =  btnRecent.textField.textWidth + 15;
			
			xbtnParameters = new Button();
			xbtnParameters.label = 'FlashVars';
			xbtnParameters.width =  xbtnParameters.textField.textWidth + 15;
			
			xbtnInfo = new Button();
			xbtnInfo.label = 'info';
			xbtnInfo.width =  xbtnInfo.textField.textWidth + 15;
			
			
			xcboxAutoSize = new ComboBox();
			cboxAutoSize.dataProvider = new DataProvider(scaleModes);
			xcboxAutoSizeMode = cookie.data.autoSize || 'auto';
			
			cboxAutoSize.width = 55;
			cboxAutoSize.drawNow();
			
			addEventListeners();
			
			AxlLoader.classDict.U.addChildGroup(this, btnLoad,btnConsole,btnRecent,xbtnParameters,dates,xbtnInfo,cboxAutoSize,btnReload);
			arangeBar();
		}
		
		private function addEventListeners():void
		{
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			
			dates.addEventListener(KeyboardEvent.KEY_UP, onTopBarKeyUp);
			btnLoad.addEventListener(ComponentEvent.BUTTON_DOWN, btnLoadDown);
			btnConsole.addEventListener(ComponentEvent.BUTTON_DOWN, btnConsoleDown);
			btnRecent.addEventListener(ComponentEvent.BUTTON_DOWN, btnRecentDown);
			btnReload.addEventListener(ComponentEvent.BUTTON_DOWN, btnReloadDown);
			xbtnParameters.addEventListener(ComponentEvent.BUTTON_DOWN, btnParametersDown);
			xbtnInfo.addEventListener(ComponentEvent.BUTTON_DOWN, btnInfoDown);
			cboxAutoSize.addEventListener(Event.CHANGE, onAutoSizeChange);
		}
		
		
		protected function onAutoSizeChange(e:Event):void
		{
			AxlLoader.instance.onResize();
		}
		
		protected function set xcboxAutoSizeMode(v:String):void { 
			for(var i:int = scaleModes.length;i-->0;)
				if(scaleModes[i].label ==v)
					xcboxAutoSize.selectedIndex = i;
		}
		
		// --------------------- EVENTS --------------------- //
		private function fout(e:FocusEvent):void {  dates.timestampSec }
		protected function ats(event:Event):void { 	arangeBar()	}
		
		protected function onTopBarKeyUp(e:KeyboardEvent):void
		{
			if(e.charCode == 13)
				AxlLoader.instance.loadContent();
		}
		
		public function btnConsoleDown(e:*=null):void { AxlLoader.instance.windowConsole.wappear() }
		public function btnRecentDown(e:*=null):void { AxlLoader.instance.windowRecent.wappear() }
		public function btnTimestampDown(e:*=null):void { AxlLoader.instance.windowTimestamp.wappear() }
		public function btnReloadDown(e:*=null):void { AxlLoader.instance.loadContent() }
		public function btnLoadDown(e:*=null):void { AxlLoader.instance.browseForFile(); }
		public function btnParametersDown(e:*=null):void { AxlLoader.instance.windowParameters.wappear() }
		public function btnInfoDown(e:ComponentEvent):void { AxlLoader.instance.windowInfo.wappear() }		
		
		// --------------------- public api --------------------- //
		public function arangeBar():void
		{
			if(btnReload == null)
				return;
			AxlLoader.classDict.U.distribute(this,0);
			AxlLoader.classDict.U.align(btnReload, AxlLoader.classDict.U.REC, 'right', 'top');
			if(cboxAutoSize == null)
				return;
			cboxAutoSize.x = btnReload.x - cboxAutoSize.width;
			xbtnInfo.x = cboxAutoSize.x - xbtnInfo.width;
		}

		public function get btnConsole():Button { return xbtnConsole }
		public function get btnRecent():Button { return xbtnRecent }
		public function get btnReload():Button { return xbtnReload }
		public function get btnLoad():Button { return xbtnLoad }
		public function get dates():DateComponent {	return xdates }
		public function get cboxAutoSize():ComboBox	{ return xcboxAutoSize }

		public function exiting():void
		{
			cookie.data.autoSize = cboxAutoSize.selectedLabel;
			cookie.flush();
		}
	}
}