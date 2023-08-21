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
                      Element
  from std/json import parseJson, to

  import pkg/jswebsockets

  import dirtyGpt/jsutils

  echo "start"
  proc main {.async.} =
    echo "getInput"
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
            resolve()
        , delay)

    proc prompt(text: cstring): Future[string] {.async.} =
      var
        interval: Interval
        limit = 500
        delay = 500

      promptField.setInputValue text
      await clickButton promptButton

      return newPromise[string]() do (resolve: (string) -> void):
        interval = setInterval(proc() =
          if limit == 0:
            clearInterval interval
            resolve ""
          else:
            echo promptButton.innerText
            if promptButton.innerText.len == 0:
              clearInterval interval
              resolve "success"
        , delay)


    var
      ws = newWebSocket("ws://localhost:" & $dirtyGptPort)

    proc promptNext() =
      ws.send wsMsgGetPrompt

    ws.onOpen = proc (e: Event) =
      promptNext()
      
    ws.onMessage = proc (e: MessageEvent) =
      discard (proc {.async.} =
        let prompt = parseJson($e.data).to DirtyGptPrompt
        let response = await prompt prompt.text
        echo response
      )()
    ws.onClose = proc (e: CloseEvent) =
      echo("closing: ", e.reason)
  when isMainModule:
    discard main()
else:
  # Lib
  import std/asyncdispatch
  from std/asynchttpserver import Request, newAsyncHttpServer, close, listen,
                                  AsyncHttpServer, shouldAcceptRequest,
                                  acceptRequest
  from std/json import `$`, `%*`, `%`

  from pkg/ws import newWebSocket, receiveStrPacket, send, Open,
                      WebSocketClosedError

  type
    DirtyGpt* = ref object
      server: AsyncHttpServer
      prompts: seq[DirtyGptPrompt]

  using
    self: DirtyGpt

  func nextPrompt*(self): DirtyGptPrompt =
    ## Get the next unprompted prompt
    for prompt in self.prompts:
      if not prompt.requested:
        prompt.requested = true
        return prompt

  proc newDirtyGpt*: DirtyGpt =
    ## Creates a new DirtyGpt websocket
    new result
    proc serve(self) {.async.} =
      self.server = newAsyncHttpServer()
      proc cb(req: Request) {.async.} =
        echo (req.reqMethod, req.url, req.headers)
        var ws = await newWebSocket req
        try:
          while ws.readyState == Open:
            let packet = await receiveStrPacket ws
            case packet:
            of wsMsgGetPrompt:
              let nextPrompt = self.nextPrompt
              await ws.send($ %*nextPrompt)
            else:
              await ws.send "Unknown command"
        except WebSocketClosedError:
          echo "closed"
          
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

  proc prompt*(self; prompt: string): Future[string] {.async.} =
    ## Prompts to ChatGPT by using userscript
    let currPrompt = DirtyGptPrompt(
      id: self.prompts.len,
      text: prompt
    )
    self.prompts.add currPrompt
    echo "create: ", currPrompt[]

    while true:
      var resp = self.prompts[currPrompt.id]
      if resp.requested:
        if resp.response.len > 0:
          return resp.response
      poll()

  when isMainModule:
    var gpt = newDirtyGpt()
    var resp = waitFor gpt.prompt "Hello"
    echo resp
    echo "end"

    stop gpt
