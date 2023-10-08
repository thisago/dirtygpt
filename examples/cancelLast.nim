import std/asyncdispatch
import pkg/dirtygpt

let gpt = newDirtyGpt()

var prompt = gpt.queuePrompt "Hello, my name is John"

while gpt.connectedClients == 0: # wait connect
  waitFor sleepAsync 500
waitFor sleepAsync 1000

gpt.delete prompt

disconnectClients gpt # disconnect

prompt = gpt.queuePrompt "Hello, did you know my name?"

echo gpt.connectedClients # 0

echo waitFor gpt.wait prompt # wait connect again and answer

stop gpt
