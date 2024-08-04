#Requires AutoHotkey v2.0

/*
shot input has three blocks

Aim: either
(<x>,<y>): coordinates
L|R|D: left/right/down

Taps:
L|R<t>: t taps in direction left/right.
If aim is L/R then direction defaults to opposite.

Timing:
[<f>%<p>]: acceptable timings are frames f mod p.
p defaults to 600 if missing

Returns data object containing fields
x, y, direction, taps, frame, period
*/
UnpackNotation(packedShot)
{
	unpackedShot := Object()

	coordsPattern := "^\((?<x>\d+),(?<y>\d+)\)"
	cardinalPattern := "^(?<side>[LRD])"

	if RegexMatch(packedShot, coordsPattern, &match)
	{
		foundSide := ""
		unpackedShot.x := Integer(match.x)
		unpackedShot.y := Integer(match.y)
	}
	else if RegexMatch(packedShot, coordsPattern, &match)
	{
		foundSide := match.side
		switch foundSide
		{
			case "L":
				unpackedShot.x := 10
				unpackedShot.y := 10
			case "R":
				unpackedShot.x := 790
				unpackedShot.y := 10
			case "D":
				unpackedShot.x := 400
				unpackedShot.y := 80
		}
	}
	else
	{
		throw
	}

	directionStart := match.Pos + match.Len

	directionPattern := "^(?<direction>[LR])"

	if foundSide == "L"
	{
		unpackedShot.direction := "R"
		tapsStart := directionStart
	}
	else if foundSide == "R"
	{
		unpackedShot.direction := "L"
		tapsStart := directionStart
	}
	else if RegexMatch(packedShot, directionPattern, &match, directionStart)
	{
		unpackedShot.direction := match.direction
		tapsStart := match.Pos + match.Len
	}
	else
	{
		unpackedShot.direction := ""
		tapsStart := directionStart
	}


	tapsPattern := "^(?<taps>\d+)"

	if unpackedShot.direction and RegexMatch(packedShot, tapsPattern, &match, tapsStart)
	{
		unpackedShot.taps := match.taps
		timingStart := match.Pos + match.Len
	}
	else
	{
		unpackedShot.taps := 0
		timingStart := tapsStart
	}

	framePeriodPattern := "^\[(?<frame>\d+)%(?<period>\d+)\]"
	framePattern := "^\[(?<frame>\d+)\]"

	if RegexMatch(packedShot, framePeriodPattern, &match, timingStart)
	{
		unpackedShot.frame := match.frame
		unpackedShot.period := match.period
	}
	else if RegexMatch(packedShot, framePattern, &match, timingStart)
	{
		unpackedShot.frame := match.frame
		unpackedShot.period := 600
	}
	else
	{
		unpackedShot.frame := ""
		unpackedShot.period := ""
	}

	return unpackedShot
}