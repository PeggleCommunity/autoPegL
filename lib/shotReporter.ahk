#Requires AutoHotkey v2.0

OnExit ShotReporter.Exiting

class ShotReporter
{
	output := unset

	static openOutputs := []

	static Exiting(*)
	{
		for outputBuffer in ShotReporter.openOutputs
		{
			outputBuffer.Close()
		}
	}
	/*
	columns: Map containing key-value pairs (name (string), output column size)
	outputFile: writable text buffer
	*/
	__New(columns, outputFile?)
	{
		if IsSet(outputFile)
		{
			ShotReporter.openOutputs.Push(outputFile)
		}
		else
		{
			outputFile := FileOpen("*", "w")
		}
		this.output := outputFile
		for name, size in columns
		{
			columns[name] = max(StrLen(Name), size)
		}
		this.columns := columns
	}

	WriteHeader()
	{
		line := ""
		for name, size in this.columns
		{
			if A_Index > 1
			{
				line .= ","
			}
			line .= Format("{1:" size "}", name)
		}
		this.output.WriteLine(line)
	}

	WriteData(data)
	{
		line := ""
		for name, size in this.columns
		{
			if A_Index > 1
			{
				line .= ","
			}
			line .= Format("{1:" size "}", data[name])
		}
		this.output.WriteLine(line)
	}
}
