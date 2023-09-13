const
  dirtyGptPort* {.intdefine.} = 5552

const
  clientLoopTime* {.intdefine.} = 500 ## ping interval
  clientPingMaxWait* {.intdefine.} = clientLoopTime * 2 ## Max interval without receiving ping

const
  clientSocketTimeout* {.intdefine.} = 3000

const
  wsMsgGetPrompt* = "getPrompt"
  wsMsgPing* = "ping"

type
  DirtyGptPrompt* = ref object
    id*: int
    text*, response*: string
    requestedTo*: string ## Websocket id who prompt was requested
  DirtyGptResponse* = ref object
    id*: int
    text*: string
