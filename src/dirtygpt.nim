const dirtyGptPort {.intdefine.} = 5552

when defined js:
  # Userscript
  import jswebsockets

  var
    socket = newWebSocket("ws://localhost:" & $dirtyGptPort)

  socket.onOpen = proc (e: Event) =
    echo("sent: test")
    socket.send("test")
  socket.onMessage = proc (e: MessageEvent) =
    echo("received: ", e.data)
    socket.close(StatusCode(1000), "received msg")
  socket.onClose = proc (e: CloseEvent) =
    echo("closing: ", e.reason)
else:
  # Lib
  import std/asyncdispatch
  from std/asynchttpserver import Request, newAsyncHttpServer, serve, close,
                                  AsyncHttpServer
  from pkg/ws import WebSocket, newWebSocket, receiveStrPacket, send

  type
    DirtyGpt* = ref object
      server: AsyncHttpServer
      prompts: seq[DirtyGptPrompt]
    DirtyGptPrompt = ref object
      id: int
      prompt, response: string

  using
    self: DirtyGpt

  proc newDirtyGpt*: DirtyGpt =
    ## Creates a new DirtyGpt websocket
    new result
    result.server = newAsyncHttpServer()
    var dirtyGpt = result
    asyncCheck result.server.serve(Port dirtyGptPort) do (req: Request) {.async, gcsafe.}:
      echo "new conn"
      echo req.hostname
      var ws = await newWebSocket req
      echo await ws.receiveStrPacket()
      await ws.send("Hi, how are you?")
      echo await ws.receiveStrPacket()
      for prompt in dirtyGpt.prompts.mitems:
        prompt.response = "Hi"

  proc prompt*(self; prompt: string): Future[string] {.async.} =
    ## Prompts to ChatGPT by using userscript
    let currPrompt = DirtyGptPrompt(
      id: self.prompts.len,
      prompt: prompt
    )
    self.prompts.add currPrompt
    while true:
      let resp = self.prompts[currPrompt.id].response
      if resp.len > 0:
        return resp
      poll()

  when isMainModule:
    var gpt = newDirtyGpt()
    var resp = gpt.prompt "Hello"
    if resp.finished:
      echo resp.read
    echo "end"
    