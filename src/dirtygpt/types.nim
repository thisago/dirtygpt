from pkg/ws import WebSocket

type
  DirtyGptConn* = ref object
    ws*: WebSocket
