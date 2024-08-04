#Requires AutoHotkey v2.0

#Include <peggleProcess>

class PeggleWindow
{
	reader := unset
	pid := unset
	gameVersion := unset

	static timingOffset := 8
	, fastForwardSpeed := 8
	, msPerFrame := 10
	, fineTimingFrames := 20 ; x 30
	, processToGameVersions := Map(
		"Deluxe", "Deluxe",
		"Extreme", "Extreme",
		"NightsPortable", "Nights",
		"NightsSteam", "Nights",
		"Wow", "Wow"
	)
	, playButtonCoords := Map(
		"Deluxe", {X: 470, Y: 500},
		"Extreme", {X: 470, Y: 500},
		"Nights", {X: 470, Y: 530},
		"Wow", {X: 470, Y: 530}
	)

	GameBaseIsNights()
	{
		return (
			this.gameVersion == "Nights" or this.gameVersion == "Wow"
		)
	}

	getCharacterSelectCoords(character)
	{
		switch this.gameVersion . " " . character
		{
			case "Deluxe Bjorn"       : return {X: 260, Y: 160}
			case "Deluxe Jimmy"       : return {X: 330, Y: 160}
			case "Deluxe Tut"         : return {X: 260, Y: 230}
			case "Deluxe Splork"      : return {X: 330, Y: 230}
			case "Deluxe Claude"      : return {X: 260, Y: 300}
			case "Deluxe Renfield"    : return {X: 330, Y: 300}
			case "Deluxe Tula"        : return {X: 260, Y: 370}
			case "Deluxe Warren"      : return {X: 330, Y: 370}
			case "Deluxe Cinderbottom": return {X: 260, Y: 440}
			case "Deluxe Hu"          : return {X: 330, Y: 440}

			case "Nights Bjorn"       : return {X: 260, Y: 160}
			case "Nights Jimmy"       : return {X: 330, Y: 160}
			case "Nights Renfield"    : return {X: 260, Y: 230}
			case "Nights Tut"         : return {X: 330, Y: 230}
			case "Nights Splork"      : return {X: 260, Y: 300}
			case "Nights Claude"      : return {X: 330, Y: 300}
			case "Nights Tula"        : return {X: 260, Y: 370}
			case "Nights Cinderbottom": return {X: 330, Y: 370}
			case "Nights Warren"      : return {X: 260, Y: 440}
			case "Nights Hu"          : return {X: 330, Y: 440}
			case "Nights Marina"      : return {X: 260, Y: 510}

			case "Extreme Bjorn"      : return {X: 260, Y: 160}

			case "Wow Bjorn"          : return {X: 260, Y: 160}
			case "Wow Splork"         : return {X: 330, Y: 160}
		}
	}

	static MouseToDefaultPosition()
	{
		MouseMove 30, 561
	}

	static MouseClick(coords, button:="L")
	{
		Click coords.X, coords.Y, button
	}
	ClickMenu()
	{
		Click 30, 560
	}

	ClickRestartChallenge()
	{
		; nights delay untested
		Sleep this.GameBaseIsNights() ? 300 : 210
		Click 400, 430
	}

	ClickRestartAdventure()
	{
		Click 490, 410
	}

	ClickConfirmRestartChallenge()
	{
		; nights delay untested
		Sleep this.GameBaseIsNights() ? 300 : 170
		Click 325, 440
	}

	ClickConfirmRestartAdventure()
	{
		Click 325, 420
	}

	SkipLevelSpawn()
	{
		; nights delay untested
		Sleep this.GameBaseIsNights() ? 500 : 140
		Click 100, 100
		Sleep this.GameBaseIsNights() ? 500 : 260
	}

	static ClickReplayButton(advanced:=false)
	{
		Click 760, 560
	}

	__New(pid, processVersion)
	{
		this.pid := pid
		this.gameVersion := PeggleWindow.processToGameVersions[processVersion]
		this.reader := PeggleMemoryReader.GetReader(pid, processVersion)

		return this
	}

	ReportVariables(vars*)
	{
		reportedVariables := Map()
		for var in vars
		{
			reportedVariables[var] := this.reader.Read(var)
		}

		return reportedVariables
	}

	ReportSingleVariable(var)
	{
		return this.reader.Read(var)
	}

	BringThisGameToFront()
	{
		WinMoveTop ("ahk_pid " . this.pid)
		WinActivate ("ahk_pid " . this.pid)
	}

	RestartAdventureLevel(character?)
	{
		this.BringThisGameToFront()

		; This needs to be re-implemented
		PeggleWindow.ClickMenu()
		Sleep 210
		PeggleWindow.ClickRestartAdventure()
		Sleep 180
		PeggleWindow.ClickConfirmRestartAdventure()
		Sleep 120
		PeggleWindow.SkipLevelSpawn()
		Sleep 260

		if !IsSet(character)
		{
			this.WaitUntilStartOfTurn()
			return
		}
		else
		{
			coords := this.getCharacterSelectCoords(character)
		}

		PeggleWindow.MouseClick(coords)
        Sleep 10
		PeggleWindow.MouseClick(coords)

		if this.GameBaseIsNights()
		{
			Sleep 250
		}

		this.WaitUntilStartOfTurn()
	}

	RestartChallenge(character?) ; TODO split this and add fallbacks
	{
		this.BringThisGameToFront()

		Loop
		{
			this.ClickMenu()
			this.ClickRestartChallenge()
			this.ClickConfirmRestartChallenge()
			this.SkipLevelSpawn()

			timerPoll1 := this.reader.Read("levelTimer")
			Sleep 20
			timerPoll2 := this.reader.Read("levelTimer")
			if A_Index > 20
			{
				throw Error("Fatal desync in pause menu", -1)
			}
		}
		until timerPoll2 > timerPoll1


		this.PickCharacter(character?)
	}

	PickCharacter(character?)
	{
		while (this.reader.Read("boardState") != 9)
		{
			Sleep PeggleWindow.msPerFrame // 2
			if A_Index > 20
			{
				throw Error("Fatal desync before character select", -1)
			}
		}

		if !IsSet(character)
		{
			coords := PeggleWindow.playButtonCoords[this.gameVersion]
		}
		else
		{
			coords := this.getCharacterSelectCoords(character)
		}

		PeggleWindow.MouseClick(coords)
		PeggleWindow.MouseClick(coords)

		while (this.reader.Read("boardState") != 1)
		{
			Sleep PeggleWindow.msPerFrame // 2
			if A_Index > 20
			{
				throw Error("Fatal desync after character select", -1)
			}
		}
	}

	WaitUntilStartOfTurn(reportVars*)
	{
		while (this.reader.Read("boardState") == 1)
		{
			Sleep PeggleWindow.msPerFrame // 2
		}

		Click "R D"
		while (this.reader.Read("boardState") != 1)
		{
			Sleep PeggleWindow.msPerFrame // 2
		}
		Click "R U"
		PeggleWindow.MouseToDefaultPosition()
		return this.reportVariables(reportVars*)
	}

	CheckIfTurnDone(reportVars*)
	{
		ballIsGoing := this.reader.Read("boardState") == 2
		if ballIsGoing
		{
			return
		}
		return this.reportVariables(reportVars*) ; [] is truthy
	}

	SetUpAim(mouseX, mouseY, taps:=0, direction:="{Left}")
	{
		MouseMove mouseX, mouseY
		loop taps
		{
			Send direction
		}
	}

	DoBufferShot(reportVars*)
	{
		Send "{Enter down}"
		while this.reader.Read("boardState") != 2
		{
			Sleep 10
		}
		Send "{Enter up}"
		return this.reportVariables(reportVars*)
	}

	PerformTiming(frame?, period:=600, reportVars*)
	{
		if !IsSet(frame)
		{
			Click "R D"
			Sleep 100
			Click "R U"
			Send "{Enter}"
			return this.reportVariables(reportVars*)
		}

		targetFastForwardEndInPeriod := frame - PeggleWindow.timingOffset - PeggleWindow.fineTimingFrames

		currentTime := this.reader.Read("levelCycle")
		cycleOffset := ceil((currentTime - targetFastForwardEndInPeriod) / period)
		targetFastForwardEnd := targetFastForwardEndInPeriod + period * cycleOffset

		targetFrame := targetFastForwardEnd + PeggleWindow.fineTimingFrames

		fastForwardTime := (
			(targetFastForwardEnd - currentTime)
			// PeggleWindow.fastForwardSpeed
			* PeggleWindow.msPerFrame
		)
		if fastForwardTime
		{
			Click "R D"
			Sleep fastForwardTime
			Click "R U"
		}

		/*
		remainingWait := (targetFrame - this.reader.Read("levelCycle") - 1) * PeggleWindow.msPerFrame
		if remainingWait < 0
			throw TargetError ("Overshot target frame (remainingWait = " remainingWait ")", -1, remainingWait)
		*/

		while this.reader.Read("levelCycle") < targetFrame
		{
			Sleep 0
		}

		Send "{Enter}"
		return this.reportVariables(reportVars*)
	}

	SaveReplay(filename, single:="")
	{

	}
}