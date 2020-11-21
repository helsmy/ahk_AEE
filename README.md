# AEEmitter
A simple event driven framework for autohotkey

## How to use

For the most simple way:  
1. Put AEE.ahk into `YouScriptDir/lib`
2. Do something like below:
```autohotkey
#Persistent
#include <AEE>
Hello(words)
{
    Msgbox, % "Hello " words "!"
    ; we need exit script by ourselves, 
    ; when use #Persistent
    ExitApp
}
emitter := new AEEmitter()
emitter.On("say", Func("Hello")) ; register a event
; A msgbox will show with "Hello World!"
emitter.emit("say", "World")     ; fire it
```

### detail

- Property:
eventsCount(ReadOnly): number of events registered

- Special Event:
  - newListener: fired every times when a new listener is added
             listener must accept 2 parameters:  
                type: event name of added listener  
                listener: added listener
  - removeListener: fired every times when a listener of a event is removed
             listener must accept 2 parameters:  
                type: event name of removed listener  
                listener: removed listener
- Method:
  - On(type, callback, prepend := false)
    - Add a listener to wait for a event
    - params:
      - type: event name waited
      - callback: listener
      - prepend: If ture, add listener to the head of listener list(will be execute earlier)
  - Off(type, callback)
    - Remove a listener waiting for a event
    - params:
      - type: event name waited
      - callback: listener to be removed
  - AddListener(type, listener, prepend := false)
    - same as `On`
  - PrependListener(type, listener) 
    - Add a listener in the head of listener list(will be execute earlier) to wait for a event
    - params:
      - type: event name waited
      - listener: listener
  - Once(type, listener, prepend := false)
    - Add a listener to wait for a event. This listener will be removed Once it has been executed
    - params:
      - type: event name waited 
      - callback: listener 
      - prepend: If ture, add listener to the head of listener list(will be execute earlier)
  - RemoveListener(type, listener)
    - same as `Off`
  - RemoveAllListener(type)
    - Remove all listener of a event
    - params:
      - type: event name waited
  - RemoveEvent(type)
    - Remove a event from monitor
    - params:
      - type: event name waited
  - Emit(type, params*)
    - Emit a specific event 
    - params:
      - type: event name waited
      - params*: params to be passed to each listener
  - EmitImmediate(type, params*)
    - Emit a specific event and execute each listener as quick as possible
    - params:
      - type: event name waited
      - params*: params to be passed to each listener
