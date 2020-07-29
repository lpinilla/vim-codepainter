# vim-codepainter 🎨🖌

A plugin for Vim to color different parts of code making the use of Highlights

This plugin is made to manage the different "colors" that you can assign to the code. The idea is as simple as to pre-append a delimeter like `#0#` before each line and then add a matching rule to highlight that lines.

## Demo

![](./vim-codepainter_demo.gif)

## How to use

Once installed (I highly recommend [vim-plug](https://github.com/junegunn/vim-plug)), you need to set a color (or use default), select the area you want to "paint" and press F2 (default key-binding) to paint it.

If you had something already painted, selecting and applying the same color will result on removing it. If you paint it with another color, it will replace it for the new one.

### Changing between colors

There are 10 colors pre-defined on the plugin source (named "paint<n>"). You can use any highlight group you want using `:PainterChangeColor <number>` for the default ones or `:PainterChangeColorByName <name>` to supply your own highlight group. The default group is "paint0".

### Cleaning everything

If you want to remove every marker and every match rule, you should run the command `:PainterEraseAll`

### Saving the Marks

Use the command `:PainterSaveMarks <path>` to create a json file with the marks. If no path is supplied, it will use the file's path and create a file with the same name.

### Loading Marks from a file

The command `:PaintarLoadMarks <path>` lets you load the marks saved previously. If a path is not supplied, it will use the current file path and try to load a json file with the same filename of the current file.

By default, the plugin will try to automatically load the marks of the current file if they exist. You can disable this feature by changing the flag `g:auto_load_marks` to 0 in the plugin source.

### Bugs

If you find a bug, feel free to open an issue about it!
