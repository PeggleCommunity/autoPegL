#Requires AutoHotkey v2.0

#Include <peggleWindow>

GetAllPeggleWindows(processVersion)
{
	windows := []
	for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
	{
		if Instr(process.Name, "Peggle") or Instr(process.Name, "popcapgame")
		{
			pid := process.ProcessID
			windows.Push(PeggleWindow(pid, processVersion))
		}
	}

	return windows
}