package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.SharedObject;
	
	import fl.controls.TextInput;
	
	public class Sync extends Sprite
	{
		private var xsize:Point = new Point();
		private var searcher:TextInput;
		private var ca:Array;
		private var cookie:SharedObject;
		private var list:Sprite;
		public function Sync()
		{
			super();
			list = new Sprite();
			this.addChild(list);
			cookie = SharedObject.getLocal('sync');
			if(!(cookie.data.sync is Array))
				cookie.data.sync = [];
			this.addEventListener(Event.ADDED_TO_STAGE, stageAdded);
			reRead(cookie.data.recent)
			list.addChild(new SyncListElement());
		}
		
		public function get size():Point { return xsize }

		protected function stageAdded(event:Event):void
		{
			stage.stageWidth = list.width;
			stage.stageHeight = list.height;
			this.dispatchEvent(new Event('resize'));
		}
		
		public function reRead(v:Array):void
		{
			this.dispatchEvent(new Event('resize'));
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
import flash.display.Sprite;
import flash.events.Event;

import axl.utils.U;

import fl.controls.Button;
import fl.controls.ComboBox;
import fl.controls.TextInput;
import fl.data.DataProvider;

internal class SyncListElement extends Sprite
{
	private var type:TextInput;
	private var listenerDispatcher:ComboBox;
	private var dispatchedOn:ComboBox;
	private var eventRelated:ComboBox;
	private var changesList:TextInput;
	private var dispatchNow:Button;
	private var remove:Button;
	
	public function SyncListElement():void
	{
		super();
		type = new TextInput();
		type.width = 150;
		
		listenerDispatcher = new ComboBox();
		listenerDispatcher.dataProvider = new DataProvider([{label : "listener"}, {label : "dispatcher"}]);
		listenerDispatcher.width = 100;
		listenerDispatcher.addEventListener(Event.CHANGE, listenerDispatcherChange);
		
		dispatchedOn = new ComboBox();
		dispatchedOn.dataProvider = new DataProvider([{label : "loaded"}, {label : "addedToStage"}, {label: "event"}]);
		dispatchedOn.width = 100;
		dispatchedOn.addEventListener(Event.CHANGE, dispatchedOnChange);
		
		
		eventRelated = new ComboBox();
		eventRelated.dataProvider = new DataProvider();
		eventRelated.width = 100;
		
		
		changesList = new TextInput();
		changesList.width = 200;
		changesList.addEventListener(Event.CHANGE, changeListUpdated);
		
		
		dispatchNow = new Button();
		dispatchNow.label = "dispatch now";
		dispatchNow.width = dispatchNow.textField.width + 5;
		
		
		remove = new Button();
		remove.label = "remove";
		remove.width = remove.textField.width + 5;
		
		PromoLoader.addGrouop(this, type, listenerDispatcher, dispatchedOn, eventRelated, changesList, dispatchNow, remove);
		U.distribute(this, 0);
		listenerDispatcher.selectedIndex = 0;
		listenerDispatcherChange();
	}
	
	
	public function refresh():void
	{
		listenerDispatcherChange();
	}
	
	protected function listenerDispatcherChange(e:Event=null):void
	{
		if(listenerDispatcher.selectedLabel == 'listener')
		{
			changesList.enabled = false;
			dispatchNow.enabled = false;
			eventRelated.enabled = false;
			dispatchedOn.enabled = false;
		}
		else
		{
			changesList.enabled = true;
			dispatchNow.enabled = true;
			dispatchedOn.enabled = true;
			eventRelated.enabled = (dispatchedOn.selectedLabel == 'event');
		}
	}
	
	protected function dispatchedOnChange(e:Event):void
	{
		eventRelated.enabled = (dispatchedOn.selectedLabel == 'event');
	}
	
	
	protected function changeListUpdated(event:Event):void
	{
		// TODO Auto-generated method stub
	}
}