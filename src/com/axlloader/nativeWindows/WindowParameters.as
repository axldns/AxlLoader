package com.axlloader.nativeWindows
{
	import com.axlloader.core.AxlLoader;
	
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
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
		private var btnOpen:Button;
		private var openFile:File;
		private var urlr:URLRequest;
		private var urll:URLLoader;
		private var log:Function;
		private var btnRemoveAll:Button;
		private var btnSave:Button;
		public function WindowParameters(windowTitle:String)
		{
			super(windowTitle);
			cookie = SharedObject.getLocal('params');
			log = AxlLoader.classDict.U.log;
			try { cookie.data.params = JSON.parse(cookie.data.params as String) }
			catch(e:*) { cookie.data.params = null; trace("error parsing cookie",e)};
			if(cookie.data.params == null)
				cookie.data.params = {};
			
			
			list = new AxlLoader.classDict.MaskedScrollable();
			list.controller.addEventListener("change", onListMovement);
			list.controller.omitDraggingAnimation=false;
			list.controller.animationTime = 1;
			list.deltaMultiplier = 30;
			list.visibleWidth = 300;
			list.visibleHeight = 200;
			list.y = 60;
			addSavedRows();
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
			
			btnOpen = new Button();
			btnOpen.label = "open csv xml or json";
			btnOpen.width = 125;
			
			addChild(btnOpen);
			openFile = new File();
			openFile.addEventListener(Event.SELECT, onFileSelected);
			btnOpen.addEventListener(ComponentEvent.BUTTON_DOWN, browseForFile);
			
			btnRemoveAll = new Button();
			btnRemoveAll.label = "remove all";
			btnRemoveAll.x = 125;
			btnRemoveAll.width = 70;
			addChild(btnRemoveAll);
			btnRemoveAll.addEventListener(ComponentEvent.BUTTON_DOWN, onRemoveAll);			
			addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragIn);
			addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
			
			btnSave = new Button();
			btnSave.label = "save";
			btnSave.width = 50;
			btnSave.x= 195;
			addChild(btnSave);
			btnSave.addEventListener(ComponentEvent.BUTTON_DOWN, onSave);
		}
		
		override protected function onWindowCreated():void
		{
			window.addEventListener(NativeWindowBoundsEvent.RESIZE,onResize);
			window.stage.stageWidth = wid = 245;
			window.stage.stageHeight = 300;
		}
		
		protected function onResize(event:NativeWindowBoundsEvent):void
		{
			graphics.clear();
			graphics.beginFill(0xffffff);
			graphics.drawRect(0,0,wid, stage.stageHeight);
			wid = stage.stageWidth;
			Row.onResize();
			btnAdd.x = wid - btnAdd.width;
			list.visibleWidth = wid;
			list.visibleHeight = stage.stageHeight-list.y;
			if(selectedRow)
				selectRow();
		}
		
		protected function onSave(event:ComponentEvent):void
		{
			saveCookie();
		}
		
		protected function onRemoveAll(event:ComponentEvent):void
		{
			Row.removeAll();
			list.controller.percentageVertical=0;
			if(selector.parent)
				selector.parent.removeChild(selector);
		}
		
		private function onDragIn(e:NativeDragEvent):void
		{
			if(e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
			{
				var files:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				if(files.length == 1)
				{
					NativeDragManager.acceptDragDrop(this);
				}
			}
		}
		protected function onDragDrop(e:NativeDragEvent):void
		{
			var arr:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			if(arr && arr.length > 0)
			{
				urlr = new URLRequest(arr.pop().url); 
				loadFile();
			}
		}
		
		protected function onFileSelected(e:Event):void
		{
			urlr = new URLRequest(e.target.url);
			loadFile();
		}
		
		private function loadFile():void
		{
			// cant use AXL loader since it gots 
			if(urlr == null) return;
			AxlLoader.classDict.Ldr.load(urlr.url,null,onLoaded,null,null,0);
		}
		
		private function onLoaded(fn:String):void
		{
			var lo:* = AxlLoader.classDict.Ldr.getAny(fn);
			if(lo is ByteArray)
			{
				log("uncregonized type of file");
				return;
			}
			if(lo is String)
				parseCSV(lo);
			else if(lo is XMLList)
				parseXMLList(lo);
			else if(lo is XML)
				parseXMLList(XML(lo).param);
			else if(lo is Object)
				parseJSON(lo);
			Row.distributeRows();
		}
		
		private function parseXMLList(lo:XMLList):void
		{
			var len:int = lo.length();
			log("list has length of", len);
			for(var i:int = 0, xml:XML; i < len; i++)
			{
				xml = lo[i];
				if(xml.hasOwnProperty("@key") && xml.hasOwnProperty("@value"))
					list.addChild(new Row(xml.@key, xml.@value));
				else
					log("node", xml, "does not have key or value or both attributes");
				
			}
		}
		
		private function parseJSON(o:Object):void
		{
			trace("parse json");
			for(var k:String in o)
				list.addChild(new Row(k,o[k] is String ? o[k] : JSON.stringify(o[k])));
		}
		
		private function parseCSV(lo:String):void
		{
			var csvrows:Array = lo.split(/(\r\n|\n\r|\n|\r)/);
			var len:int = csvrows.length;
			var kv:Array;
			while(csvrows.length)
			{
				kv = csvrows.pop().split(',');
				if(kv.length < 2)
					continue;
				list.addChild(new Row(kv[0],kv[1]));
			}
		}
		
		public function browseForFile(e:Object=null):void
		{
			openFile.browseForOpen("open");
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
		
		private function addSavedRows():void
		{
			var o:Object= cookie.data.params;
			for(var k:String in o)
				list.addChild(new Row(k,o[k] is String ? o[k] : JSON.stringify(o[k])));
			Row.distributeRows();
		}
				
		public function exiting():void
		{
			saveCookie();
		}
		
		private function saveCookie():void
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
		tf.wordWrap = false;
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
	}
	public static function removeAll():void
	{
		var row:Row;
		while(rows.length)
		{
			row = rows.pop();
			if(row.parent)
				row.parent.removeChild(row);
			row = null;
		}
	}}