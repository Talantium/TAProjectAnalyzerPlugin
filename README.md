TAProjectAnalyzerPlugin
=======================

Xcode Plugin to gather and show some project metrics like LoC

Uses CLOC (http://cloc.sourceforge.net/)


Install
======

1) Clone project
2) Build project (installs automatically in the plugins dir of the current user)
3) Restart Xcode
4) New menu entry: "Product > Project Statistics"
5) If a proper project is open, the whole project folder is scanned for code files and LoC are counted


ToDo
======

* Proper UI
* Result parsing more robust
* Settings to choose/exclude folders