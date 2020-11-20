/******************************************************
	Author: helsmy
	Website: https://github.com/helsmy/ahk_AEE
	Lisence: LGPLv2.1
	Plesase redistribute with above information
 ******************************************************
 	
    A simple event driven framework

    for the most simple way:
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

    Property:
        eventsCount(ReadOnly): number of events registered

    Special Event:
        newListener: fired every times when a new listener is added
                     listener must accept 2 parameters: 
                        type: event name of added listener
                        listener: added listener
        removeListener: fired every times when a listener of a event is removed
                     listener must accept 2 parameters: 
                        type: event name of removed listener
                        listener: removed listener
*/


class AEEmitter
{
    static _events := {}
    static _eventsCount := 0

    eventsCount[]
    {
        get
        {
            return this._eventsCount
        }

        set
        {
            throw Exception("Set to read only property", -1, "eventsCount")
        }
    }

    /**
     *   Add a listener to wait for a event
     *   @params: type event name waited
     *   @params: callback listener
     *   @params: prepend If ture, add listener to the head of listener list(will be execute earlier)
     */
    On(type, callback, prepend := false)
    {
        if (!IsFunc(callback))
            throw Exception("Value Error", -1, "Listener(callback) must be a function or method")
        if (!this._events)
            this._events := {}
        events := this._events

        if (events.HasKey("newListener"))
            this.Emit("newListener", type, callback)
        if (!events.HasKey(type))
        {
            events[type] := []
            ++this._eventsCount
        }
        if (!prepend)
            events[type].Push(callback)
        else
            events[type].InsertAt(1, callback)
        return this
    }

    /**
     *   Remove a listener waiting for a event
     *   @params: type event name waited
     *   @params: callback listener to be removed
     */
    Off(type, callback)
    {
        return this.RemoveListener(type, callback)
    }

    /**
     *   Add a listener to wait for a event
     *   @params: type event name waited
     *   @params: listener listener
     *   @params: prepend If ture, add listener to the head of listener list(will be execute earlier)
     */
    AddListener(type, listener, prepend := false)
    {
        return this.On(type, listener, prepend := false)
    }

    /**
     *   Add a listener in the head of listener list(will be execute earlier) to wait for a event
     *   @params: type event name waited
     *   @params: listener listener
     */
    PrependListener(type, listener) 
    {
        return this.On(type, listener, true)   
    }

    /**
     *   Remove a listener waiting for a event
     *   @params: type event name waited
     *   @params: listener listener to be removed
     */
    RemoveListener(type, listener)
    {
        events := this._events, list := events[type]
        postion := 0
        for p, l in list
        {
            if (l == listener)
                postion := p
        }  

        ; No corresponding listener, do nothing
        if (!postion)
            return this
        list.RemoveAt(postion)
        if (events.HasKey("removeListener"))
            this.Emit("removeListener", type, listener)
        return this
    }

    /**
     *   Remove all listener of a event
     *   @params: type event name waited
     */
    RemoveAllListener(type)
    {
        events := this._events
        if (events.HasKey(type))
            events[type] := []
        return this
    }

    /**
     *   Remove a event from monitor
     *   @params: type event name to be removed
     */
    RemoveEvent(type)
    {
        events := this._events
        if (events.HasKey(type))
            events.Delete(type), --this._eventsCount
        return this
    }

    /**
     *   Emit a specific event 
     *   @params: type event name waited
     *   @params: params* params to be passed to each listener
     */
    Emit(type, params*)
    {
        if (this._events.HasKey(type))
        {
            for _, handler in this._events[type]
                __AEE_EventDispatcher.Put(handler, params)
        }
        return true
    }

    /**
     *   Emit a specific event and execute each listener as quick as possible
     *   @params: type event name waited
     *   @params: params* params to be passed to each listener
     */
    EmitImmediate(type, params*)
    {
        if (this._events.HasKey(type))
        {
            for _, handler in this._events[type]
                __AEE_EventDispatcher.Put(handler, params, true)
        }
        return true
    }

    Once(type, params*)
    {
        if (this._events.HasKey(type))
        {
            for _, handler in this._events[type]
            {
                fn := ObjBindMethod(this, "_OnceWapper", type, handler)
                __AEE_EventDispatcher.Put(fn, params)
            }
        }
        return true
    }

    /*
     * Inner wapper for `Once` method to remove listener after executed
     * DO NOT CALL IT
     */
    _OnceWapper(type, fn, params*)
    {
        events := this._events, list := events[type]
        fn.Call(params*)
        if (list.Length != 0)
            this.RemoveListener(type, fn)
        else
            this.RemoveEvent(type)
    }
}

; *************** INNER CLASS *******************
;             DO NOT DRICTLY CALL IT
;       UNLESS YOU KNOW WHAT YOU ARE DONING
; ***********************************************
class __AEE_EventDispatcher
{
	static eventQueue := []
	static immediateQueue := []

	Put(handler, data, immediate := false)
	{
		if !immediate
			this.eventQueue.Push([handler, data])
		else
			this.immediateQueue.Push([handler, data])
		; Using a single timer ensures that each handler finishes before
		; the next is called, and that each runs in its own thread.
		static DT := ObjBindMethod(__AEE_EventDispatcher, "DispatchTimer")
		SetTimer, % DT, -1
	}

	DispatchTimer()
	{
		static DT := ObjBindMethod(__AEE_EventDispatcher, "DispatchTimer")
		; Clear immediateQueue array before fire handler of eventQueue
		if (next := this.immediateQueue.RemoveAt(1))
			fn := next[1], %fn%(next[2]*)
		; Call exactly one handler per new thread.
		else if next := this.eventQueue.RemoveAt(1)
			fn := next[1], %fn%(next[2]*)
		; If the queue is not empty, reset the timer.
		if (this.eventQueue.Length() || this.immediateQueue.Length())
			SetTimer, % DT, -1
	}
}
