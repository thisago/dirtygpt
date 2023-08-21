when not defined js:
  {.fatal: "JS only module".}

# Turndown.js
type TurndownService {.importc.} = ref object
proc newTurndownService: TurndownService {.importjs: "(new TurndownService)".}

let td = newTurndownService()

proc turndown(td: TurndownService; html: cstring): cstring {.importcpp.}

proc turndown*(html: cstring): string =
  ## Turns HTML to Markdown
  $td.turndown html
