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
		private var xtfMember:TextInput;
		private var xtfCompVal:TextInput;
		
		private var xbtnConsole:Button;
		private var xbtnRecent:Button;
		private var xbtnReload:Button;
		private var xbtnLoad:Button;
		
		private var xdates:DateComponent;
		private var xtfData:TextInput;
		private var xcboxAutoSize:ComboBox;
		private var cookie:SharedObject;
		private var scaleModes:Array = [{label : "auto"}, {label : "scale"}, {label: "free"}];
		
		public function TopBar()
		{
			super();
			cookie = SharedObject.getLocal('bar');
			xdates = new DateComponent();
			
			xtfMember = new TextInput();
			tfMember.text =  cookie.data.memberId || 'memberId';
			
			tfMember.textField.restrict = '0-9';
			tfMember.width = 60;
			tfMember.addEventListener(MouseEvent.MOUSE_WHEEL, tfMemberWheelEvent);
			
			xtfCompVal = new TextInput();
			
			tfCompVal.text = cookie.data.compValue ||'compValue';
			tfCompVal.width = 60;
			tfCompVal.textField.restrict = '0-9';
			xtfData = new TextInput();
			tfData.text = cookie.data.dataParameter || 'dataParameter';
			
			xbtnLoad = new Button();
			btnLoad.label = 'select swf';
			btnLoad.width = btnLoad.textField.textWidth + 15;
			
			
			xbtnReload = new Button();
			btnReload.label = 'reload';
			btnReload.width = btnReload.textField.textWidth + 15;
			
			
			xbtnConsole = new Button();
			btnConsole.label = 'C';
			btnConsole.width = btnConsole.height;
			
			
			xbtnRecent = new Button();
			btnRecent.label = 'R';
			btnRecent.width = btnRecent.height;
			
			
			xcboxAutoSize = new ComboBox();
			cboxAutoSize.dataProvider = new DataProvider(scaleModes);
			xcboxAutoSizeMode = cookie.data.autoSize || 'auto';
			
			cboxAutoSize.width = 55;
			cboxAutoSize.drawNow();
			
			addEventListeners();
			
			AxlLoader.classDict.U.addChildGroup(this, btnLoad,btnRecent,tfMember,btnConsole,tfCompVal,dates,cboxAutoSize,tfData,btnReload);
		}
		
		private function addEventListeners():void
		{
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			tfMember.addEventListener(MouseEvent.CLICK, fin);
			tfCompVal.addEventListener(MouseEvent.CLICK, fin);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			
			dates.addEventListener(KeyboardEvent.KEY_UP, onTopBarKeyUp);
			tfCompVal.textField.addEventListener(KeyboardEvent.KEY_UP, onTopBarKeyUp);
			tfData.textField.addEventListener(KeyboardEvent.KEY_UP, onTopBarKeyUp);
			tfMember.textField.addEventListener(KeyboardEvent.KEY_UP, onTopBarKeyUp);
			btnLoad.addEventListener(ComponentEvent.BUTTON_DOWN, btnLoadDown);
			btnConsole.addEventListener(ComponentEvent.BUTTON_DOWN, btnConsoleDown);
			btnRecent.addEventListener(ComponentEvent.BUTTON_DOWN, btnRecentDown);
			btnReload.addEventListener(ComponentEvent.BUTTON_DOWN, btnReloadDown);
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
		private function fin(e:MouseEvent):void {	e.target.setSelection(0, e.target.text.length) }
		protected function ats(event:Event):void { 	arangeBar()	}

		protected function tfMemberWheelEvent(e:MouseEvent):void
		{
			var n:Number = Number(tfMember.text);
			if(!isNaN(n))
				tfMember.text = String(n += e.delta > 0 ? 1 : -1);
			else
				tfMember.text = '1';
		}
		
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
			xtfData.x = xdates.x + xdates.width;
			xtfData.width = cboxAutoSize.x - xtfData.x;
		}

		public function get tfMember():TextInput { return xtfMember }
		public function get tfCompVal():TextInput { return xtfCompVal }
		public function get btnConsole():Button { return xbtnConsole }
		public function get btnRecent():Button { return xbtnRecent }
		public function get btnReload():Button { return xbtnReload }
		public function get btnLoad():Button { return xbtnLoad }
		public function get dates():DateComponent {	return xdates }
		public function get tfData():TextInput { return xtfData }
		public function get cboxAutoSize():ComboBox	{ return xcboxAutoSize }

		public function exiting():void
		{
			cookie.data.dataParameter =tfData.text;
			cookie.data.compValue = tfCompVal.text;
			cookie.data.memberId = tfMember.text;
			cookie.data.autoSize = cboxAutoSize.selectedLabel;
			cookie.flush();
			AxlLoader.classDict.U.log(this,'cooke saved');
		}
	}
}