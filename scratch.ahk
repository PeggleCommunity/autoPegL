#Requires AutoHotkey v2.0

#Include <peggleWindow>

GetTestPeggleWindow(processVersion)
{
	for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
	{
		if Instr(process.Name, "Peggle") or Instr(process.Name, "popcapgame")
		{
			pid := process.ProcessID
			break
		}
	}

	return PeggleWindow(pid, processVersion)
}

DllCall("AllocConsole")

stdOut := FileOpen("*", "w")
^q::
{
	Exit
}