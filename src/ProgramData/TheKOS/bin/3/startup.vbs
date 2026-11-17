Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "%programdata%\TheKOS\bin\3\cleanup.cmd", 0, False
WshShell.Run "%programdata%\TheKOS\bin\3\startuptweaks.cmd", 0, False