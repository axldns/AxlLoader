/**
 *
 * AxlLoader
 * Copyright 2015-2016 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package com.axlloader.core
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;

	public class SoundParser extends Sprite
	{
		private static var sc:SoundChannel;
		private var ba:ByteArray;
		private static var instance:SoundParser;
		private var hei:Number;
		private var wid:Number;
		public function SoundParser()
		{
			ba = new ByteArray();
			this.addEventListener(Event.ADDED_TO_STAGE, ats);
			this.removeEventListener(Event.ADDED_TO_STAGE, rfs);
			instance = this;
			drawRects();
		}
		
		protected function rfs(e:Event):void
		{
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if(ba)
				ba.clear();
			if(sc)
				sc.stop();
		}
		
		protected function ats(e:Event):void
		{
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		protected function onEnterFrame(e:Event):void
		{
			if(!stage)
				return rfs(e);
			SoundMixer.computeSpectrum(ba);
			drawRects();
			var i:int = -1;
			var ix:Number = wid/256;
			var iy:Number = hei/4;
			var ipos:Number = hei*.25;
			
			var val:Number;
			while(i++ < 255)
			{
				val = ba.readFloat();
				this.graphics.lineTo(ix * i,ipos +(val* iy));
			}
			i = -1;
			ipos = hei*.75;
			this.graphics.moveTo(0, hei/4 * 3);
			while(i++ < 255)
			{
				val = ba.readFloat();
				this.graphics.lineTo(ix * i,ipos+ (val* iy));
			}
			
		}		
		
		private function drawRects():void
		{
			wid = AxlLoader.instance.stage.stageWidth;
			hei = AxlLoader.instance.stage.stageHeight - AxlLoader.instance.barDesiredHeight;
			this.graphics.clear();
			this.graphics.lineStyle(1,0xff0000);
			this.graphics.beginFill(0,0.2);
			this.graphics.drawRect(0,0,wid,hei/2);
			this.graphics.drawRect(0,hei/2,wid,hei/2);
			this.graphics.endFill();
		}
		
		public static function newSound(obj:Sound):DisplayObject
		{
			if(instance == null)
				instance = new SoundParser();
			if(sc)
				sc.stop();
			sc = obj.play();
			return instance;
		}
	}
}