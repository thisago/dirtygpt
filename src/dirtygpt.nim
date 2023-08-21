from std/json import parseJson, to, `$`, `%*`, `%`

const
  dirtyGptPort {.intdefine.} = 5552

const
  wsMsgGetPrompt = "getPrompt"

type
  DirtyGptPrompt = ref object
    id: int
    text, response: string
    requested: bool
  DirtyGptResponse* = ref object
    id: int
    text: string

when defined js:
  import std/asyncjs
  import std/sugar
  import std/jsconsole

  from std/dom import document, Interval, click, setInterval, clearInterval,
                      Element, querySelectorAll, Interval, clearInterval

  import pkg/jswebsockets

  import dirtyGpt/jsutils
  import dirtyGpt/turndown

  proc getPromptResponse: string =
    let responses = document.querySelectorAll ".markdown"
    result = turndown responses[^1].innerHtml

  proc main {.async.} =
    let
      promptField = await document.waitEl "#prompt-textarea"
      promptButton = await document.waitEl "#prompt-textarea + button"

    proc clickButton(button: Element) {.async.} =
      var
        interval: Interval
        delay = 500

      await newPromise() do (resolve: () -> void):
        interval = setInterval(proc() =
          if not promptButton.disabled:
            click button
            clearInterval interval
            resolve()
        , delay)


    proc prompt(text: cstring): Future[string] {.async.} =
      var
        interval: Interval
        limit = 500
        delay = 500

      promptField.setInputValue text
      await clickButton promptButton
      await sleep 500

      return newPromise[string]() do (resolve: (string) -> void):
        interval = setInterval(proc() =
          if limit == 0:
            clearInterval interval
            resolve ""
          else:
            if promptButton.innerText.len == 0:
              clearInterval interval
              resolve getPromptResponse()
          dec limit
        , delay)

    proc startWs =
      var
        ws = newWebSocket("ws://localhost:" & $dirtyGptPort)
        available = true
        loopInterval: Interval

      proc getPromptLoop(loopDelay = 500) =
        loopInterval = setInterval(proc =
          if available:
            ws.send wsMsgGetPrompt
            available = false
        , loopDelay)

      ws.onOpen = proc (e: Event) =
        getPromptLoop()

      ws.onMessage = proc (e: MessageEvent) =
        discard (proc {.async.} =
          var prompt = parseJson($e.data).to DirtyGptPrompt
          prompt.response = await prompt prompt.text
          available = true
          ws.send( $ %*prompt)
        )()
      ws.onClose = proc (e: CloseEvent) =
        echo "closed"
        clearInterval loopInterval
        startWs()
    startWs()
  when isMainModule:
    discard main()
else:
  # Lib
  import std/asyncdispatch
  from std/asynchttpserver import Request, newAsyncHttpServer, close, listen,
                                  AsyncHttpServer, shouldAcceptRequest,
                                  acceptRequest
  from std/json import JsonParsingError

  from pkg/ws import newWebSocket, receiveStrPacket, send, Open,
                      WebSocketClosedError

  type
    DirtyGpt* = ref object
      server: AsyncHttpServer
      prompts: seq[DirtyGptPrompt]
      connectedClients: int ## How much WS clients is connected to provide answers

  using
    self: DirtyGpt

  func nextPrompt*(self): DirtyGptPrompt =
    ## Get the next unprompted prompt
    for prompt in self.prompts:
      if not prompt.requested:
        prompt.requested = true
        return prompt

  func update*(self; answered: DirtyGptPrompt): bool =
    ## Update prompt with answered result
    result = false
    for prompt in self.prompts:
      if prompt.id == answered.id:
        prompt.response = answered.response
        return true


  proc newDirtyGpt*: DirtyGpt =
    ## Creates a new DirtyGpt websocket
    new result
    proc serve(self) {.async.} =
      self.server = newAsyncHttpServer()
      proc cb(req: Request) {.async.} =
        echo (req.reqMethod, req.url, req.headers)
        var ws = await newWebSocket req
        inc self.connectedClients
        try:
          while ws.readyState == Open:
            let packet = await receiveStrPacket ws
            case packet:
            of wsMsgGetPrompt:
              let nextPrompt = self.nextPrompt
              await ws.send( $ %*nextPrompt)
            else:
              try:
                let answered = packet.parseJson.to DirtyGptPrompt
                if not self.update answered:
                  echo "Error, prompt not exists: ", answered[]
              except JsonParsingError:
                await ws.send "Unknown command"
        except WebSocketClosedError:
          discard

        dec self.connectedClients

        # for prompt in self.prompts.mitems:
        #   prompt.response = "Hi"

      self.server.listen Port dirtyGptPort

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
    echo "create: ", result[]

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
    
    
  proc wait*(self; prompt: DirtyGptPrompt): Future[string] {.async.} =
    ## Waits the prompt to be answered
    ## 
    ## Can be blocking
    while true:
      let pr = self.get prompt
      if pr.response.len > 0:
        return pr.response
      poll()

  proc prompt*(self; prompt: string): Future[string] {.async.} =
    ## Prompts to ChatGPT by using userscript
    ## 
    ## Can be blocking
    let currPrompt = self.queuePrompt prompt
    result = await self.wait currPrompt

  when isMainModule:
    proc main {.async.} =
      var gpt = newDirtyGpt()
      echo await gpt.prompt "list 5 fruits"

      stop gpt

  waitFor main()
