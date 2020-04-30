# Giftray

1. Description
2. Make and installation
3. Usage and configuration
4. Known Issues
5. TODO

1 Description
=============

This tool was developped by cadeauthom on AutoHotKey.
This tool target only windows distributions.
The tool provides a way to use predefined function through customized hotkey and through a tray menu.
Last installer can be download on: https://github.com/cadeauthom/giftray/releases/latest

This tool is fully opensource and is available through GPL v3 license.

2 Build and installation
========================

2.1 Build
---------
A Makefile can be found on top directory of the sources.
The Makefile was made to be run on wsl (Windows Subsystem Linux) and has been tested only on wsl Ubuntu.
make will call the AutoHotkey and its compiler to exe, the paths and the options must be set:
- AHKRUN
- AHKRUNFLAGS
- AHKEXE
- AHKEXEFLAG

A converter is needed to create ico images for svg and must be defined with its options:
- CONVERTIMG
- CONVERTIMGFLAGS
ImageMagick was used on compiled version.

A compressing tool is hardly recommanded to minimize the size of the final executables.
- COMPRESS
- COMPRESSFLAGS
upx was used on compiled version.

Then use the following make command:
- make
   to build the full project, then the executable in the build folder is directly usable
- make compil
   to build the installer (on install)
- make cleanexe
   to clean only exe files (keep all icons and other files)
- make clean
   to clean all

2.2 Installation
----------------
AutoHotkey is not needed to install or run the tool.
Simply run the setup executable you built or downloaded from github.
This will install the images, a basic configuration and the executables on the %Program Files%
Shortcuts will also be set in the Windows Start Menu.
It will also add the tool at Startup of Windows.

2.3 Uninstallation
------------------
Run the uninstall shortcut from Windows Start Menu or uninstall executable from your installation folder.
It will ask to keep or not the configuration and then remove everything except the uninstaller from your system.

3 Usage and configuration
=========================

3.1 Menu
--------
By right-clicking on the tray icon, a menu opens and show the configured actions.
The not-configured actions are visible "Inactive" submenu.
Then click on the wanted menu to run the corresponding action.
The icon will be animated while the action is running (and few seconds after).

The tray will always show preconfigured menus including Exit and Reload.

3.2 HotKey
----------
By opening the menu, the defined HotKey are visible at the right of the definition of the action and on the submenu "Not clickable".
The definition of the keys can be found in AutoHotKey.com.
Using the HotKey as any shortcut to run the corresponding action.
The icon will be animated while the action is running (and few seconds after).

3.3 Configuration
-----------------
The current configuration can be found on "Show conf" menu of the tray and the file itself.
If no file is correclty written on the user's document folder, the one from the installation folder is used.
The configuration file allow 3 ways to add an action to the tray and the HotKey:
- default:
  using only the "real" action name as the following example:
  ```
  windows_WinAlwaysontop
  ```
  If the action does not exist, it will appear in the errors.
- detailed:
  describing all or part of the options of the action in several lines.
  ```
  my_wynAlway2top {
  menu : true
  ahk : Ctrl + Win + Space
  function : windows_WinAlwaysontop
  ico : windows_WinAlwaysontop.ico
  print : Set the windows on top
  action_opt1 : custom option of action
  }
  ```
  Be carefull to not create nested description and to respect the name of the options as well as the brackets { and }
  If not set, any option will be set to the default of the discribed action (my_wynAlway2top here).
  If the function does no exist, the action will appear in the errors.
  print will be the string visible on the menu.
  ico is the path or the name of the ico to use in the tray.
  ico can be the file name if the file is on the icons directory, or a path starting by the drive (C:\....\), or path starting with .\ to look from the installation path.
  action_opt1 is an example of option that can be specific to the action.
  If a non-defined option is set, an error will be printed while starting the tool, as well as any typo!
  menu is a boolean to define if the acction appear in the list of available actions in the tray.
  ahk is a string for the HotKey, the format is described on AutoHotKey.com
  A generator is avaiable throught the menu.
  An empty string or "NULL" will disable the HotKey.
  At least one of ahk and menu must be set to have a HotKey and/or a tray configured.
- included:
  using an included file that will be found in the corresponding conf.d folder and named /<name>.conf were <name> is a string like the following
  ```
  #include my_wynAlway2topbis
  ```
  The file contains lines as defined for previous way.
  By using the "Show conf" menu, the included actions will be shown as detailed actions.
On all configuration file, "#" defines a comment (except for include) "/*" and "*/" define a comment block.

3.3 Images
----------
Please always use your custom images by using your own name and use detailed configuration.
It will avoid to remove or replace your images with the installer.
Recommanded format 32x32 ico files.
The ico(s) of the tray can also be updated but with the risk of the loss using the installer.
The tray will use the icos found on icons\ and with named ending by "-nb" where nb are consicutive numbers starting from 0.
The 0 is shown when the tool is inactive and the other will be used in a loop while activating the tool.

4 Known Issues
==============

- Configuration files must be encode in ANSY, if not, special caracters may create bugs, especially in "ahk" parameteres.
- hidden or system path are not supported (for icons, actions...)

5 TODO
======

5.1 Installation/build
----------------------
- add include conf file in build
- pregression bar during (un)installation
- option for installation for startup
- add installation to windows registry
- customize installation directory (ahk FileCreateDir & FileInstall do not allow variables ?)

5.2 Features/improvements
-------------------------
- limit size of 'print' field
- custom ico for tray with configuration
- fully document the options of all actions
- check to have only different HotKey
- create user configuration
- add Menu, Tray, Tip,  text

5.3 Other
---------
- way to rename executables
- cut main file for separate small and main fct
