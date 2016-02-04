package nativeWindows
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.ui.Keyboard;
	
	import fl.controls.List;
	import fl.controls.TextInput;
	import fl.controls.listClasses.CellRenderer;
	import fl.data.DataProvider;
	
	public class WindowRecent extends WindowOwner
	{
		private var list:List;
		private var dp:DataProvider;
		private var xsize:Point = new Point();
		private var searcher:TextInput;
		private var ca:Array;
		private var xselectedUrl:String;
		private var cookie:SharedObject;
		public function WindowRecent(windowTitle:String)
		{
			super(windowTitle);
			cookie = SharedObject.getLocal('recent');
			if(!(cookie.data.recent is Array))
				cookie.data.recent = [];
			list = new List();
			list.doubleClickEnabled = true;
			list.addEventListener(MouseEvent.DOUBLE_CLICK, mdc);
			list.addEventListener(KeyboardEvent.KEY_UP, listKeyUp);
			dp = new DataProvider();
			searcher = new TextInput();
			searcher.width = 800;
			searcher.addEventListener(KeyboardEvent.KEY_UP, ku);
			addChild(searcher);
			list.y = searcher.height;
			addChild(list);
			this.addEventListener(Event.ADDED_TO_STAGE, stageAdded);
			reRead(cookie.data.recent);
			
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,manualyResized);
		}
		
		protected function manualyResized(e:NativeWindowBoundsEvent):void
		{
			reResize(e.afterBounds);
		}
		
		protected function listKeyUp(e:KeyboardEvent):void
		{
			PromoLoader.classDict.U.log(e.keyCode == flash.ui.Keyboard.DELETE, list.selectedItem != null)
			if(e.keyCode == flash.ui.Keyboard.DELETE && list.selectedItem != null)
				this.removeRowContaining(list.selectedItem.label);
		}
		public function selectListItemUrlAt(index:int):void
		{
			if(index >= list.length)
				index = list.length -1;
			if(index < 0)
				index = 0;
			var o:Object = list.getItemAt(index);
			if(o&&o.hasOwnProperty('label'))
			{
				list.selectedItem = o;
				xselectedUrl = list.selectedItem.label;
				this.dispatchEvent(new Event(Event.SELECT));
			}
			
		}
		
		public function get selectedURL():String { return xselectedUrl }
		public function get size():Point { return xsize }

		protected function mdc(e:MouseEvent):void
		{
			if(e.target is CellRenderer && list.selectedItem != null && list.selectedItem.hasOwnProperty('label'))
			{
				xselectedUrl = list.selectedItem.label;
				this.dispatchEvent(new Event(Event.SELECT));
			}
		}
		
		protected function ku(e:KeyboardEvent):void
		{
			dp.removeAll();
			for(var i:int = 0; i < ca.length; i++)
			{
				var reg:RegExp = new RegExp(searcher.text, "i");
				if(String(ca[i]).match(reg))
					dp.addItem( { label:ca[i] } );
			}
			list.rowCount = dp.length;
			list.dataProvider = dp;
			list.setSize(800,list.rowHeight * list.rowCount * 1.2);
			list.drawNow();
			xsize.x = list.width;
			xsize.y = list.height;
			
			this.dispatchEvent(new Event('resize'));
		}
		
		protected function stageAdded(event:Event):void
		{
			stage.stageWidth = list.width;
			stage.stageHeight = list.height;
			this.dispatchEvent(new Event('resize'));
		}
		
		public function reRead(v:Array):void
		{
			ca = v;
			dp.removeAll();
			for(var i:int = 0; i < v.length; i++)
				dp.addItem( { label:v[i] } );
			list.rowCount = v.length;
			list.dataProvider = dp;
			list.setSize(800,list.rowHeight * list.rowCount * 1.2);
			list.drawNow();
			xsize.x = list.width;
			xsize.y = list.height;
			this.dispatchEvent(new Event('resize'));
		}
		
		public function reResize(afterBounds:Rectangle):void
		{
			list.setSize(afterBounds.width,afterBounds.height);
			list.drawNow();
			xsize.x = list.width;
			xsize.y = list.height;
		}
		
		public function removeRowContaining(url:String):void
		{
			var i:int = cookie.data.recent.indexOf(url);
			if(i > -1)
				cookie.data.recent.splice(i,1);
			cookie.flush();
			reRead(cookie.data.recent)
		}
		
		public function registerLoaded(url:String):void
		{
			var i:Object = cookie.data.recent.indexOf(url);
			if(i < 0)
				cookie.data.recent.push(url);
			else
				cookie.data.recent.unshift(cookie.data.recent.splice(i,1)[0]);
			cookie.flush();
			reRead(cookie.data.recent)
		}
	}
}