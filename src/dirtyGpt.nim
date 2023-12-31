when defined js:
  {.fatal: "This library doesn't work in JS backend".}

import std/asyncdispatch
from std/asynchttpserver import Request, newAsyncHttpServer, close, listen,
                                AsyncHttpServer, shouldAcceptRequest,
                                acceptRequest
from std/json import parseJson, to, `$`, `%*`, `%`, JsonParsingError
from std/times import DateTime, `<`, now, milliseconds, `-`
from std/strformat import fmt

from pkg/ws import newWebSocket, receiveStrPacket, send, Open,
                    WebSocketClosedError, WebSocket, close

import dirtyGpt/common

type
  DirtyGpt* = ref object
    server: AsyncHttpServer
    prompts: seq[DirtyGptPrompt]
    clients: seq[DirtyGptClient]
  DirtyGptClient = tuple
    time: DateTime
    ws: WebSocket

using
  self: DirtyGpt
  prompt: DirtyGptPrompt
  ws: WebSocket

func requested(prompt): bool =
  prompt.requestedTo.len > 0

func nextPromptFor*(self; ws): DirtyGptPrompt =
  ## Get the next unprompted prompt
  for prompt in self.prompts:
    if not prompt.requested:
      prompt.requestedTo = ws.key
      return prompt

func update*(self; answered: DirtyGptPrompt): bool =
  ## Update prompt with answered result
  result = false
  for prompt in self.prompts:
    if prompt.id == answered.id:
      prompt.response = answered.response
      return true

proc addClient(self; ws) =
  ## Adds new Websocket connection
  self.clients.add (now(), ws)

proc clientPing(self; ws) =
  ## Update the client time
  for cl in self.clients.mitems:
    if cl.ws.key == ws.key:
      cl.time = now()

proc isOpen(self; ws): bool =
  ## Check if this Websocket connection is on open clients
  result = false
  for cl in self.clients.mitems:
    if cl.ws.key == ws.key:
      return true

proc resetUnansweredPromptsOf(self; ws) =
  ## Reset the unanswered prompts sent to `ws`
  for prompt in self.prompts:
    if prompt.requestedTo == ws.key:
      prompt.requestedTo = ""

proc updateClients(self) =
  ## Remove expired clients who doesn't sent ping
  let nowTime = now()
  for i in countdown(self.clients.len - 1, 0):
    let client = self.clients[i]
    if client.time < nowTime - clientPingMaxWait.milliseconds:
      echo client.time, " - ", nowTime - clientPingMaxWait.milliseconds
      close client.ws
      self.resetUnansweredPromptsOf client.ws
      self.clients.delete i

proc connectedClients*(self): int =
  ## How much WS clients is connected to provide answers
  self.updateClients()
  result = self.clients.len

proc newDirtyGpt*: DirtyGpt =
  ## Creates a new DirtyGpt websocket
  let logger = newLogger()
  new result
  proc serve(self) {.async.} =
    self.server = newAsyncHttpServer()
    proc cb(req: Request) {.async.} =
      var ws = await newWebSocket req
      self.addClient ws
      logger.log lvlInfo, fmt"New client connected: '{ws.key}'. Connected clients: {self.connectedClients}"
      try:
        while ws.readyState == Open:
          if not self.isOpen ws:
            break
          let packet = await receiveStrPacket ws
          case packet:
          of wsMsgPing:
            self.clientPing ws
            logger.log lvlDebug, fmt"Client '{ws.key}' pinging"
          of wsMsgGetPrompt:
            let nextPrompt = self.nextPromptFor ws
            if not nextPrompt.isNil:
              await ws.send($ %*nextPrompt)
              logger.log lvlDebug, fmt"Sent to client '{ws.key}' prompt: {nextPrompt[]}"
          else:
            try:
              let answered = packet.parseJson.to DirtyGptPrompt
              if not self.update answered:
                logger.log lvlInfo, fmt"Client answered a nonexistent prompt: {answered[]}"
              else:
                logger.log lvlDebug, fmt"Client answer received: {answered[]}"
            except JsonParsingError:
              logger.log lvlInfo, fmt"Client sent an invalid request"
              await ws.send "Unknown command"
      except WebSocketClosedError:
        logger.log lvlInfo, fmt"Client '{ws.key}' was disconnected. Connected clients: {self.connectedClients}"
        discard

    self.server.listen Port dirtyGptPort
    logger.log lvlInfo, fmt"DirtyGPT server is listening at {dirtyGptPort} port."

    while true:
      if self.server.shouldAcceptRequest:
        await self.server.acceptRequest cb
      else:
        await sleepAsync(500)

  asyncCheck serve result

proc stop*(self) =
  ## Stop DirtyGPT
  close self.server

proc queuePrompt*(self; prompt: string): DirtyGptPrompt =
  ## Adds the prompt to queue
  result = DirtyGptPrompt(
    id: self.prompts.len,
    text: prompt
  )
  self.prompts.add result
  # echo "create: ", result[]

proc isAnswered*(self; prompt: DirtyGptPrompt): bool =
  ## Checks if the prompt was answered
  self.prompts[prompt.id].response.len > 0

proc isRequested*(self; prompt: DirtyGptPrompt): bool =
  ## Checks if the prompt was requested
  self.prompts[prompt.id].requested

proc get*(self; prompt: DirtyGptPrompt): DirtyGptPrompt =
  ## Gets the prompt if it's completed, if not, just return what you've provided
  result = prompt
  var resp = self.prompts[prompt.id]
  if resp.requested:
    if resp.response.len > 0:
      self.prompts.delete prompt.id
      result = resp

func delete*(self; prompt: DirtyGptPrompt) =
  ## Deletes the prompt from queue
  self.prompts.delete prompt.id

proc wait*(self; prompt: DirtyGptPrompt): Future[string] {.async.} =
  ## Waits the prompt to be answered
  ##
  ## Can be blocking
  while true:
    let pr = self.get prompt
    if pr.response.len > 0:
      return pr.response
    self.updateClients()
    poll()

proc prompt*(self; prompt: string): Future[string] {.async.} =
  ## Prompts to ChatGPT by using userscript
  ##
  ## Can be blocking
  let currPrompt = self.queuePrompt prompt
  result = await self.wait currPrompt

proc disconnectClients*(self) =
  ## Disconnect all WS clients
  for client in self.clients:
    close client.ws
    self.resetUnansweredPromptsOf client.ws
  self.clients = @[]

when isMainModule:
  proc main {.async.} =
    var gpt = newDirtyGpt()
    echo await gpt.prompt "ls -la"

    stop gpt

  waitFor main()
