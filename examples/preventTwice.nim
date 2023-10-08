import std/asyncdispatch
import pkg/dirtygpt

let gpt = newDirtyGpt()

let prompt = gpt.queuePrompt "Hello, free ChatGPT have rate limit?" # add prompt to queue

while gpt.connectedClients == 0: # wait connect
  waitFor sleepAsync 500
waitFor sleepAsync 500

disconnectClients gpt # disconnect

echo gpt.connectedClients # 0

echo waitFor gpt.wait prompt # wait connect again and answer

stop gpt
