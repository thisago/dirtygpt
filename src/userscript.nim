when not defined js:
  {.fatal: "JS only module".}
when not isMainModule:
  {.fatal: "This userscript cannot be imported".}

import std/asyncjs
import std/sugar

from std/dom import document, Interval, click, setInterval, clearInterval,
                    Element, querySelectorAll, Interval, clearInterval,
                    setTimeout, clearTimeout, Timeout
from std/json import parseJson, to, `$`, `%*`, `%`
from std/strformat import fmt

import pkg/jswebsockets

import dirtyGpt/jsutils
import dirtyGpt/turndown
import dirtyGpt/common

const
  promptFieldSel = "#prompt-textarea"
  promptButtonSel = fmt"{promptFieldSel} + button"

let logger = newLogger()

proc getPromptResponse: string =
  let responses = document.querySelectorAll ".markdown"
  result = turndown responses[^1].innerHtml

proc sclose(ws: Websocket) =
  # Silent close a socket (disable onClose)
  ws.onClose = proc (e: CloseEvent) = discard
  close ws
func available(ws: Websocket): bool {.inline.} =
  # check if ws is open
  not ws.isNil and ws.readyState == Open

proc main {.async.} =
  let promptField = await document.waitEl promptFieldSel
  var
    ws: WebSocket
    wsOpen = false
    lastPrompt: string

  proc clickSubmitButton {.async.} =
    if ws.available:
      click await document.waitEl promptButtonSel

  proc prompt(text: cstring): Future[string] {.async.} =
    var
      interval: Interval
      limit = 500
      delay = 500

    logger.log lvlDebug, fmt"Prompting '{text}'"
    promptField.setInputValue text
    await clickSubmitButton()
    await sleep 500 # make sure that was clicked

    discard await document.waitEl promptButtonSel
    result = getPromptResponse()

  proc startWs =
    if ws.isNil or ws.readyState == Closed:
      var
        available = true
        loopInterval: Interval
      ws = newWebSocket fmt"ws://localhost:{dirtyGptPort}"

      proc getPromptLoop =
        loopInterval = setInterval(proc =
          if available:
            ws.send wsMsgGetPrompt
            available = false
            logger.log lvlDebug, fmt"Requesting new prompt for server connection ."
          else:
            ws.send wsMsgPing
            logger.log lvlDebug, fmt"Pinging server connection."
        , clientLoopTime)

      ws.onOpen = proc (e: Event) =
        logger.log lvlDebug, fmt"New server connection"
        wsOpen = true
        getPromptLoop()

      ws.onMessage = proc (e: MessageEvent) =
        discard (proc {.async.} =
          var prompt = parseJson($e.data).to DirtyGptPrompt
          if not prompt.isNil:
            logger.log lvlDebug, fmt"Received new prompt from server . {prompt[]}"
            lastPrompt = prompt.text
            prompt.response = await prompt prompt.text
            available = true
            if ws.available:
              if prompt.text == lastPrompt:
                ws.send($ %*prompt)
                logger.log lvlDebug, fmt"Sent prompt response to server {prompt[]}"
              else:
                logger.log lvlInfo, fmt"Discarding response for '{prompt.text}'" # new prompt was requested
            else:
              logger.log lvlInfo, fmt"Connection with server is invalid. Cannot send prompt response"
          else:
            logger.log lvlDebug, fmt"Prompt data was invalid"
        )()

      ws.onClose = proc (e: CloseEvent) =
        if wsOpen:
          logger.log lvlInfo, fmt"Closed server connection. {e.reason}"
        else:
          logger.log lvlInfo, fmt"Cannot connect to server. {e.reason}"
        wsOpen = false
        clearInterval loopInterval
        ws = nil
        startWs()
    else:
      logger.log lvlInfo, fmt"Websocket already connected to server"

  startWs()

when isMainModule:
  discard main()
