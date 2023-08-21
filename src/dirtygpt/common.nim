const
  dirtyGptPort* {.intdefine.} = 5552

const
  wsMsgGetPrompt* = "getPrompt"

type
  DirtyGptPrompt* = ref object
    id*: int
    text*, response*: string
    requested*: bool
  DirtyGptResponse* = ref object
    id*: int
    text*: string
