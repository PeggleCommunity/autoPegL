#Requires AutoHotkey v2.0

#Include <peggleWindow>
#Include <GetFirstPeggleWindow>
#Include <ShotReporter>

class TimingTester
{
	aimX := unset
	aimY := unset
	startFrame := unset
	endFrame := unset
	window := unset
	reporter := unset

	__New(aimX, aimY, startFrame, endFrame, window, reporter, period?)
	{
		this.aimX := aimX
		this.aimY := aimY
		this.startFrame := startFrame
		this.endFrame := endFrame
		this.window := window
		this.reporter := reporter
		this.period := period ?? 600
	}

	TakeShot(frame)
	{
		this.window.RestartChallenge()
		this.window.SetUpAim(this.aimX, this.aimY)
		startVars := this.window.PerformTiming(frame, this.period, "levelTimer")
		endVars := this.window.WaitUntilStartOfTurn("totalPegsHit", "levelTimer")
		reportedValues := Map(
			"Frame", frame,
			"Shot Time", endVars["levelTimer"] - startVars["levelTimer"],
			"Pegs Hit", endVars["totalPegsHit"]
		)
		return reportedValues
	}

	Run()
	{
		this.reporter.WriteHeader()
		Loop this.EndFrame
		{
			if A_Index < this.StartFrame
			{
				A_Index := this.StartFrame
			}

			reportedRow := this.TakeShot(A_Index)
			this.reporter.WriteData(reportedRow)
		}
	}
}

/*
cli call args:
peggleVersion
aimX
aimY
startFrame
endFrame
[period]
*/

Main()
{
	peggleVersion := A_Args[1]
	aimX := Integer(A_Args[2])
	aimY := Integer(A_Args[3])
	startFrame := Integer(A_Args[4])
	endFrame := Integer(A_Args[5])
	if A_Args.Length == 6
	{
		period := Integer(A_Args[6])
	}
	reportedColumns := Map(
		"Frame", 5,
		"Pegs Hit", 3,
		"Shot Time", 5
	)

	window := GetFirstPeggleWindow(peggleVersion)
	reporter := ShotReporter(reportedColumns)

	tester := TimingTester(aimX, aimY, startFrame, endFrame, window, reporter, period?)

	tester.Run()
}

DllCall("AllocConsole")

^q::
{
	Main()
}

^w::
{
	Reload
}