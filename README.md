AHK-Library-Setup
=================

A Tool for AHK Library writers to ensure people using their library are set up correctly.

###Why would I want it?
If you distribute an Autohotkey library, for example via GitHub, and you wish to make it super-easy for people to  use it from any folder, then this tool will reduce your documentation and support burden.

###What does it do?
This tool has 4 main purposes

1. Ensure the user can include the library from any folder using the `#include <lib>` syntax. This is acheived by insterting an .ahk file into `C:\Program Files\AutoHotkey\Lib` that contains the line `#include filename\to\source\file.ahk`.   
This way, the user can keep the library file in the GitHub repo folder (And easily update it as the library updates) but always be able to include the latest version via the `#include <lib>` syntax.
1. Ensure The AHK Lib folder exists.
1. Ensure that AutoHotkey is installed   
Note this is possible because the script is designed to be compiled to an EXE, so AHK is not required to run the Setup script.
1. Ensure that AutoHotkey is not a version from autohotkey.com, and thus incompatible with newer versions from ahkscript.org (The bane of the #ahk IRC channel).

###How do I use it?
Simply edit the values in the section at the start of the script, compile it and include it with your project.

Run it first to simulate the user using it - it makes several checks to make sure YOU are all set up properly ;)
