#Requires AutoHotkey v2.0

#Include <peggleWindow>
#Include <GetAllPeggleWindows>
OnExit DaliBreaker.Exiting

class DaliBreaker
{
	windows := unset
	numWindows := unset
	runningShots := unset
	output := unset
	displayGui := unset

	static openOutputs := []
	, startOrangeCount := 95
	, rCannonAngle := 0x3DFA35DD
	, lCannonAngle := 0x40413E2C

	static Exiting(*)
	{
		for outputBuffer in DaliBreaker.openOutputs
		{
			outputBuffer.Close()
		}
	}

	__New(outputFile?)
	{
		if IsSet(outputFile)
		{
			DaliBreaker.openOutputs.Push(outputFile)
		}
		else
		{
			outputFile := FileOpen("*", "w")
		}
		this.output := outputFile

		this.windows := GetAllPeggleWindows("NightsSteam")
		this.numWindows := this.windows.Length
		this.runningShots := []
		this.runningShots.Length := this.numWindows
		; did not make display yet
	}

	TakeShot(index)
	{
		window := this.windows[index]

		window.RestartChallenge("Bjorn")
		loop
		{
			loop
			{
				x := random(720, 799)
				y := random(150, 200)
			} until ((x > 63) or (y < 530)) ; don't try a shot that's on the menu button

			window.SetUpAim(x, y)
			Sleep 50
			cannonAngle := window.reportSingleVariable("cannonAngleHex")
		} until (cannonAngle != DaliBreaker.rCannonAngle) and (cannonAngle != DaliBreaker.lCannonAngle)

		shotStart := window.PerformTiming(,,"levelTimer")["levelTimer"]
		return {X: x, Y: y, start: shotStart}
	}

	WaitForDoneWindow()
	{
		loop
		{
			loop this.numWindows
			{
				if this.windows[A_Index].CheckIfTurnDone()
					return A_Index

				Sleep 10
			}
		}
	}

	CollectDoneShotData(index)
	{
		window := this.windows[index]
		shot := this.runningShots[index]

		postShotVars := window.ReportVariables("levelTimer", "totalPegsHit", "orangePegsLeft")
		shot.duration := postShotVars["levelTimer"] - shot.start
		shot.pegsHit := postShotVars["totalPegsHit"]
		orangesHit := DaliBreaker.startOrangeCount - postShotVars["orangePegsLeft"]
		shot.consistentSpooky := orangesHit == postShotVars["totalPegsHit"]

		return shot
	}

	WriteData(shot)
	{
		this.output.WriteLine(
			Format(
				"{1:3},{2:4},{3:5},{4:3},{5:2}",
				shot.X, shot.Y, shot.duration, shot.pegsHit, shot.consistentSpooky
			)
		)
	}

	UpdateDisplay(shot)
	{

	}
}

Main()
{
	/*
	if A_Args.Length
	{
		filename := A_Args[1]
		outputFile := FileOpen(filename, "a")
	}
	*/
	outputFile := FileOpen("results.txt", "a")

	breaker := DaliBreaker(outputFile)

	loop breaker.numWindows
	{
		breaker.runningShots[A_Index] := breaker.TakeShot(A_Index)
	}

	loop 200
	{
		doneWindowIndex := breaker.WaitForDoneWindow()
		shotResult := breaker.CollectDoneShotData(doneWindowIndex)
		breaker.WriteData(shotResult)
		breaker.runningShots[doneWindowIndex] := breaker.TakeShot(doneWindowIndex)
		Sleep 150
	}
}

Main()

^w::
{
	Reload
}