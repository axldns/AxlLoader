package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fl.controls.List;
	import fl.controls.TextInput;
	import fl.controls.listClasses.CellRenderer;
	import fl.data.DataProvider;
	
	public class Recent extends Sprite
	{
		private var list:List;
		private var dp:DataProvider;
		private var xsize:Point = new Point();
		private var searcher:TextInput;
		private var ca:Array;
		private var xselectedUrl:String;
		public function Recent()
		{
			super();
			list = new List();
			list.doubleClickEnabled = true;
			list.addEventListener(MouseEvent.DOUBLE_CLICK, mdc);
			dp = new DataProvider();
			searcher = new TextInput();
			searcher.width = 800;
			searcher.addEventListener(KeyboardEvent.KEY_UP, ku);
			addChild(searcher);
			list.y = searcher.height;
			addChild(list);
			this.addEventListener(Event.ADDED_TO_STAGE, stageAdded);
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
	}
}