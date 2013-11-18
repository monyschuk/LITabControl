LITabControl
============

An auto-layout based multi-tab control designed to look and behave like the tab control in Apple's Numbers spreadsheet.

Features
--------

LITabControl distinguishes itself from other opensource tab systems with its support for Numbers-style behaviors. It supports arbitrary drop-down menus associated with each tab, an animated scrolling tab area, and animated tab reordering.

Classes
-------

The LITabControl project includes 2 classes:

1. **LITabControl** - an NSControl subclass used to display tabs. 

2. **LITabCell** - an NSButtonCell subclass used to draw the tab area and to draw both text and images in Numbers-style.

Using LITabControl
------------------

To learn how to use LITabControl, run the LITabControl project in Xcode. LIAppDelegate implements the LITabControlDataSource protocol to display a series of tabs across the top of its associated window.To Add the control to your own project, copy or link assets and classes located in the Classes folder to your project. 

To respond to tab clicks - set LITabControl's target and action properties, or listen for LITabControlDidChangeSelectionNotification notifications. 

To add new tabs, set LITabControl's addTarget and addAction properties. Your method used to add a tab should behave like this:

```
- (IBAction)addTab:(id)sender {
  // .. add some model object representing your tab
  [sender reloadData];
}
```

LICENSE & NOTES
---------------

LITabControl is licensed under the MIT license and hosted on GitHub at https://github.com/monyschuk/LITabControl/ Fork the project and feel free to send pull requests with your changes!


TODO
----

* tab title editing
* more documentation
* a more elaborate example
