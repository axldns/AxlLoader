**AxlLoader**
---------

AxlLoader is an AIR application for opening swf files. 

 - supports and speeds up development process
 - allows to preview network projects in local file system without IDE
 - contains number of dev-oriented tools, features and fascilities while still being small and fast
 - it's easy to integrate your projects with built in, powerful debugger
 - it's seamlessly updateable  over the network

It's an official tool to support projects based on AXLX framework, but there are no technical limitations to gain full benefits on any other projects*.

Download 
-----------
installer  | portable
------------- | -------------
[Windows - installer](http://axldns.com/axlloader/download/24191d2005d4a8280d01db927296f1c14f85414f/win/AxlLoader-win-installer.zip) | [Windows - portable](http://axldns.com/axlloader/download/24191d2005d4a8280d01db927296f1c14f85414f/win/AxlLoader-win-portable.zip)
[OS X - installer](http://axldns.com/axlloader/download/24191d2005d4a8280d01db927296f1c14f85414f/osx/AxlLoader-osx-installer.zip) |[OS X - portable](http://axldns.com/axlloader/download/24191d2005d4a8280d01db927296f1c14f85414f/osx/AxlLoader-osx-portable.zip)
[AIR - universal](http://axldns.com/axlloader/download/24191d2005d4a8280d01db927296f1c14f85414f/air/AxlLoader.air) |



Opening files
-------------
There is number of ways to load content in AxlLoader. Choose your favourite.

 - *Drag and drop* file onto application window or desktop icon
 - *Associate files* with AxlLoader - choose it as your default
   application for opening swf files
 - *Copy* file or link and *paste* it into main AxlLoader window
 - Use *"Open" button* on top bar menu
 - Use *"History" button* to navigate through previously loaded files,
   double click to load again
 - Use *hot-keys* to open files you loaded in the past

Hot Keys
--------
AxlLoader is quite rich in hot keys. There are two groups it. First controls  main application functions (loading, reloading, bringing windows up/down). Second group gives directives to [LiveArranger](http://axldns.com/?page_id=98).

***Main program shortcuts***
Hot key  | Function
------------- | -------------
ctrl/cmd + r  | reload current file
ctrl/cmd + [0-9]   |  load file from history
ctrl/cmd + v   |   load file from clipboard
ctrl/cmd + l   |  show/hide top menu bar
ctrl/cmd + t   |  show/hide Timestamp Generator window
ctrl/cmd + f   |  show/hide FlashVars window
ctrl/cmd + shift + c   |  show/hide Console window
ctrl/cmd + shift + h	| show/hide History window


***LiveArranger shortcuts*** 
Hot key  | Function
------------- | -------------
F6 | switches LiveArranger on/off
ESC  | closes editor, if editor is closed, turns arranger off
Shift   |  changes selector style
Shift + arrows   |    multiplies movements by 5px
arrows| if focus is on selected object - moves selected object horizontally and vertically, if focus is in editor input - increases and dis-creases numeric value or changes Boolean flag
Z   |  (traverse up) sets parent of selected object as selected object if available
X   |  (traverse down) selects first child of selected object as selected object if available
1   |  (traverse side) selects another child(+1) in container of selected object if available
2   |   (traverse side) selects another child(-1) in container of selected object if available
PageUp, PageDown, Home| opens/closes editor widget for selected object
Press and hold CTRL or CMD | If editor is off: allows to drag buttons preventing from executing their functions.  If editor is on: allows to select new object without exiting editor


Supported files
---------------

Despite the fact it's created to load flash files (**swf**), AxlLoader also provides primitive support for:

 - sounds - mp3, mpeg
 - images - png, jpg, gif
 - textual - xml, json, csv, txt

FlashVars
---------
User defined FlashVars can be passed three ways.

 - paste links with query strings
 - manually - use built in FlashVars editor
 - semi-manually - drag-n'drop JSON, XML or CSV file onto FlashVars editor

Aside from user defined parameters, there are three flash vars AxlLoader adds automatically:

 - `fakeTimestamp` - taken from top bar clock (great for spoofing server time)
   
 - `loadedURL` - an URL address of file that has been loaded
 - `fileName` - file name of loaded file
 
 All these three sources of flashvars (query defined, user defined, built-in) are combined together (original URL is strpped) and passed to LoaderContext.

Top Bar Clock
-------------

Top Bar Clock is also interactive: mouse wheel and keyboard arrows can tweak the values, pressing Enter key when focus is in any of its input fields reloads current content with new value of  `fakeTimestamp`.
Just like clocks in Time Stamp Generator Window, it displays time in your local time and generates *Unix timestamp*. 

Known issues
------------

 - Problems with swfs with poor error handling. If flash project throws errors and exceptions from the very first frame, it's quite likely AxlLoader and its fallbacks won't be able to handle it. By default AxlLoader keeps content in non-html container (unlike Flash Pro, Adobe Animate). Calling `ExternalInterface.call` without checking `ExternalInterface.available` is most typical example of throwing exception AxlLoader struggles with.
 - Stage 3d projects support: LiveArranger does not support it, background covers it. Still able to load, view, debug.
 - Fonts. Multiple swfs registering different fonts under the same name may cause rendering wrong fonts. This requires application restart.