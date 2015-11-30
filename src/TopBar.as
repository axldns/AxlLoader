package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	
	import axl.utils.U;
	
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.TextInput;
	
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
		private var xcboxAutoSize:CheckBox;
		private var cookie:SharedObject;
		
		public function TopBar()
		{
			super();
			cookie = SharedObject.getLocal('bar');
			xdates = new DateComponent();
			
			xtfMember = new TextInput();
			tfMember.text =  cookie.data.memberId || 'memberId';
			
			
			tfMember.textField.restrict = '0-9';
			tfMember.width = 60;
			
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
			
			
			xcboxAutoSize = new CheckBox();
			cboxAutoSize.label = '↔';
			cboxAutoSize.labelPlacement ='left';
			cboxAutoSize.width = 70;
			cboxAutoSize.selected = true;
			cboxAutoSize.drawNow();
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			
			tfMember.addEventListener(MouseEvent.CLICK, fin);
			tfCompVal.addEventListener(MouseEvent.CLICK, fin);
			this.addEventListener(FocusEvent.FOCUS_OUT, fout);
			
			PromoLoader.addGrouop(this, btnLoad,btnRecent,tfMember,btnConsole,tfCompVal,dates,cboxAutoSize,tfData,btnReload);
		}
		
		protected function ats(event:Event):void { 	arangeBar()	}
		private function fout(e:FocusEvent):void {  dates.timestampSec }
		private function fin(e:MouseEvent):void {	e.target.setSelection(0, e.target.text.length) }

		
		public function arangeBar():void
		{
			if(btnReload == null)
				return;
			U.distribute(this,0);
			U.align(btnReload, U.REC, 'right', 'top');
			if(cboxAutoSize == null)
				return;
			cboxAutoSize.x = btnReload.x - cboxAutoSize.width;
		}

		public function get tfMember():TextInput
		{
			return xtfMember;
		}

		public function get tfCompVal():TextInput
		{
			return xtfCompVal;
		}

		public function get btnConsole():Button
		{
			return xbtnConsole;
		}

		public function get btnRecent():Button
		{
			return xbtnRecent;
		}

		public function get btnReload():Button
		{
			return xbtnReload;
		}

		public function get btnLoad():Button
		{
			return xbtnLoad;
		}

		public function get dates():DateComponent
		{
			return xdates;
		}

		public function get tfData():TextInput
		{
			return xtfData;
		}

		public function get cboxAutoSize():CheckBox
		{
			return xcboxAutoSize;
		}


		public function exiting():void
		{
			cookie.data.dataParameter =tfData.text;
			cookie.data.compValue = tfCompVal.text;
			cookie.data.memberId = tfMember.text;
			cookie.flush();
			U.log(this,'cooke saved');
		}
	}
}