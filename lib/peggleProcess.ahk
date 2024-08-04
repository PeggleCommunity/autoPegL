#Requires AutoHotkey v2.0

#Include <classMemory>
OnExit PeggleMemoryReader.Exiting

class PeggleMemoryReader
{
	classMemory := unset
	readers := Map()
	static activeReaders := Map()
	static gameTables := Map(
		"Deluxe", Map(
			"gameMode", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x760]),
			"boardState", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x7b8, 0x154, 0x4]),
			"levelCycle", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x7b8, 0x158, 0x10]),
			"levelTimer", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x7b8, 0xbc, 0x14c]),
			"totalPegsHit", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x7b8, 0x154, 0x120]),
			"orangePegsLeft", Map("baseOffset", 0x286768, "dataType", "UInt", "offsets", [0x7b8, 0x154, 0x360])
		),
		; TODO add tables for other games
		"NightsPortable", Map(

		),
		"NightsSteam", Map(
			"gameMode", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x7f4]),
			"boardState", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x864, 0x720, 0x4]),
			"levelCycle", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x864, 0x724, 0x10]),
			"levelTimer", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x864, 0xd4, 0x14c]),
			"totalPegsHit", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x864, 0x720, 0x1a4]),
			"orangePegsLeft", Map("baseOffset", 0x2cbe04, "dataType", "UInt", "offsets", [0x864, 0x720, 0x414]),
			"cannonAngleHex", Map("baseOffset", 0x2cbe04, "dataType", "Int", "offsets", [0x864, 0x720, 0xec])
		),
		"Extreme", Map(

		),
		"Wow", Map(

		),
	)

	static GetPointerReader(&classMemory, baseAddress, dataType, offsets)
	{
		return () => classMemory.read(baseAddress, dataType, offsets*)
	}

	__New(pid, gameType)
	{
		if not classMemory := _ClassMemory("ahk_pid " . pid)
			return

		this.classMemory := classMemory

		for entryName, entryData in PeggleMemoryReader.gameTables[gameType]
		{
			baseAddress := this.classMemory.getModuleBaseAddress() + entryData["baseOffset"]
			this.readers[entryName] := PeggleMemoryReader.getPointerReader(
				&classMemory,
				baseAddress,
				entryData["dataType"],
				entryData["offsets"]
			)
		}
		PeggleMemoryReader.activeReaders[pid] := this
		return this
	}

	static GetReader(pid, gameType)
	{
		if existingReader := PeggleMemoryReader.activeReaders.get(pid, "")
		{
			MsgBox "Found existing reader"
			return existingReader
		}
		return PeggleMemoryReader(pid, gameType)
	}

	Read(entryName)
	{
		; if not this.classMemory.isHandleValid()
		return this.readers[entryName]()
	}

	static Exiting(*)
	{
		for pid, reader in PeggleMemoryReader.activeReaders
			reader.classMemory := unset
	}
}