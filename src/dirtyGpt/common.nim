from std/logging import newConsoleLogger, ConsoleLogger, log, Level
export log, Level

const
  dirtyGptPort* {.intdefine.} = 5552

const
  clientLoopTime* {.intdefine.} = 500 ## ping interval
  clientPingMaxWait* {.intdefine.} = clientLoopTime * 3 ## Max interval without receiving ping

# const
#   clientSocketTimeout* {.intdefine.} = 3000

const
  wsMsgGetPrompt* = "getPrompt"
  wsMsgPing* = "ping"

const debugLevel* {.intdefine: "dirtyGptDebugLvl".} = Natural 0 # 0-2
when debugLevel > 2:
  {.fatal: "Debug Level can be: 0, 1 or 2".}

type
  DirtyGptPrompt* = ref object
    id*: int
    text*, response*: string
    requestedTo*: string ## Websocket id who prompt was requested
  DirtyGptResponse* = ref object
    id*: int
    text*: string

proc newLogger*: ConsoleLogger =
  newConsoleLogger(
    fmtStr = "[$time] - $levelname: ",
    levelThreshold = when debugLevel == 1: lvlInfo elif debugLevel == 2: lvlDebug else: lvlNone
  )
