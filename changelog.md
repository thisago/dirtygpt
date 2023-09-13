# Changelog

## Version 0.2.2 (2023/09/13)

- Fixes in userscript
  - No more duplicate prompt
  - Faster connection (Stopping to abort connection when connecting)

## Version 0.2.1 (2023/08/22)

- Added timeout to websocket connection in userscript

## Version 0.2.0 (2023/08/21)

- Added fast client expiration if no ping was sent
- Added re-prompt if client was disconnected before responding
- Fixed `connectedClients`

## Version 0.1.0 (2023/08/21)

- Init
- Added server prompt sending
- Added userscript prompting
- Added WS again to communicate
- Implemented HTML response getting
- Added more functions to prompt without blocking
- Added HTML to markdown using Turndown JS
- Separated userscript from lib
- Fixed installation
- Fixed nimble file
- Fixed main module example
- Exported `connectedClients`
- Removed server debug echo
