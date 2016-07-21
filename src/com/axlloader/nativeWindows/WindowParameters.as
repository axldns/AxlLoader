package com.axlloader.nativeWindows
{
	import com.axlloader.core.AxlLoader;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	
	import fl.controls.Button;
	import fl.events.ComponentEvent;

	public class WindowParameters extends CoreWindow
	{
		private var cookie:SharedObject;
		public static var wid:Number;
		private var list:Object;
		private var selector:Sprite;
		private var selectedRow:Row;
		private var btnRemove:Button;
		private var rowBounds:Rectangle;
		private var btnAdd:Button;
		public function WindowParameters(windowTitle:String)
		{
			super(windowTitle);
			cookie = SharedObject.getLocal('params');
			
			try { cookie.data.params = JSON.parse(cookie.data.params as String) }
			catch(e:*) { cookie.data.params = null; trace("error parsing cookie",e)};
			if(cookie.data.params == null)
				cookie.data.params = {};
			
			
			list = new AxlLoader.classDict.MaskedScrollable();
			list.controller.addEventListener("change", onListMovement);
			list.deltaMultiplier = 30;
			list.visibleWidth = 600;
			list.visibleHeight = 400;
			list.y = 60;
			addRows();
			addChild(list as DisplayObject);
			
			selector = new Sprite();
			selector.mouseEnabled = false;
			btnRemove = new Button();
			btnRemove.width = btnRemove.height;
			btnRemove.label = '-';
			btnRemove.addEventListener(ComponentEvent.BUTTON_DOWN, onRemoveRow);
			selector.addChild(btnRemove);
			
			btnAdd = new Button();
			btnAdd.width = btnAdd.height;
			btnAdd.label = "+";
			btnAdd.y = list.y -btnAdd.height;
			btnAdd.addEventListener(ComponentEvent.BUTTON_DOWN, onAddRow);
			addChild(btnAdd);
			list.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverList);
		}
		
		protected function onAddRow(event:ComponentEvent):void
		{
			list.addChild(new Row());
			Row.distributeRows();
		}
		
		private function onListMovement(e:Event):void
		{
			if(selector.parent != null)
				removeChild(selector);
		}
		protected function onRemoveRow(e:ComponentEvent):void
		{
			if(selectedRow)
			{
				Row.removeRow(selectedRow);
				Row.distributeRows();
				removeChild(selector);
			}
		}
		
		private function onMouseOverList(e:MouseEvent):void
		{
			if(!selector.parent)
				this.addChild(selector);
			var newRow:Row = isMouseOverUnselectedRow(e.target);
			if(newRow)
			{
				selectedRow = newRow;
				selectRow();
			}
		}
		
		private function selectRow():void
		{
			rowBounds = selectedRow.getBounds(this);
			selector.graphics.clear();
			selector.graphics.beginFill(0x0000ff,0.3);
			selector.graphics.drawRect(0,0,rowBounds.width,rowBounds.height);
			selector.x = rowBounds.x;
			selector.y = rowBounds.y;
			btnRemove.x = wid - btnRemove.width;
		}
		
		private function isMouseOverUnselectedRow(target:Object):Row
		{
			if(target is Row && target != selectedRow)
				return target as Row;
			if(target.hasOwnProperty("parent") && target.parent != null)
				return isMouseOverUnselectedRow(target.parent);
			return null;
		}
		
		private function addRows():void
		{
			var o:Object= cookie.data.params;
			for(var k:String in o)
				list.addChild(new Row(k,o[k]));
			Row.distributeRows();
		}
				
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,onResize);
			window.stage.stageWidth = wid = 400;
			window.stage.stageHeight = 600;
		}
		
		protected function onResize(event:NativeWindowBoundsEvent):void
		{
			wid = stage.stageWidth;
			Row.onResize();
			btnAdd.x = wid - btnAdd.width;
			list.visibleWidth = wid;
			if(selectedRow)
				selectRow();
		}
		
		public function exiting():void
		{
			var toSave:String = JSON.stringify(Row.getJSON());
			cookie.data.params =toSave;
			cookie.data.autoSize;
			cookie.flush();
		}
	}
}
import com.axlloader.core.AxlLoader;
import com.axlloader.nativeWindows.WindowParameters;

import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;

internal class Row extends Sprite {
	private static var tff:TextFormat = new TextFormat("Arial",12,0,null,null,null,null,null,"center");
	private static var rows:Vector.<Row> = new Vector.<Row>();
	public static var rightMargin:Number=20;
	private var tk:TextField;
	private var tv:TextField;
	public function Row(key:String="", value:String=""):void
	{
		super();
		rows.unshift(this);
		tk = new TextField();
		tv = new TextField();
		formattf(tk);
		formattf(tv);
		tk.text = key;
		tv.text = value;
		AxlLoader.classDict.U.addChildGroup(this,tk,tv);
		this.addEventListener(Event.ADDED_TO_STAGE,ats);
	}
	
	public static function getJSON():Object
	{
		var o:Object = {}, k:String, v:String, i:int = rows.length
		while(i--)
		{
			k = rows[i].tk.text;
			v = rows[i].tv.text;
			if(k)
				o[k] = v;
		}
		return o;
	}

	protected function ats(event:Event):void
	{
		onResize();
	}
	
	public function onResize():void
	{
		if(!WindowParameters.wid) return;
		var w:Number = WindowParameters.wid;
		var m:Number = rightMargin/2;
		tk.width = tv.width = w/2-m;
		tk.height = tv.height = 20;
		AxlLoader.classDict.U.distribute(this,0);
		graphics.clear();
		graphics.beginFill(0,0);
		graphics.drawRect(w-rightMargin,0,rightMargin,20);
	}
	
	private function formattf(tf:TextField):void
	{
		tf.border = true;
		tf.defaultTextFormat = tff;
		tf.wordWrap = true;
		tf.type = 'input';
	}
	
	public static function onResize():void
	{
		var i:int = rows.length;
		while(i--)
			rows[i].onResize();
		
	}
	public static function distributeRows():void
	{
		for(var i:int = 0; i < rows.length; i++)
			rows[i].y = i * 20;
	}
	public static function removeRow(row:Row):void
	{
		if(row != null)
		{
			var i:int = rows.indexOf(row);
			if(i >= 0)
				rows.splice(i,1);
			if(row.parent)
				row.parent.removeChild(row);
		}
	}}