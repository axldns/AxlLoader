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
	public class Updater
	{
		public static function updateFunction():void
		{
			AxlLoader.classDict.U.msg('AxlLoader has been updated to version '+AxlLoader.instance.VERSION+'<br>');
		}
	}
}