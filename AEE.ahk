/******************************************************
	Author: helsmy
	Website: https://github.com/helsmy/ahk_AEE
	Lisence: LGPLv2.1
	Plesase redistribute with above information
 ******************************************************
 	
    A simple event driven framework

    for the most simple way:
        #Persistent ; Ensure script keeps running until our timmer is fired
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
        maxListener(ReadOnly): the maximum number of listeners that an event can have

    Special Event:
        newListener: fired every times when a new listener is added
                     listener must accept 2 parameters: 
                        type: event name of added listener
                        listener: added listener
        removeListener: fired every times when a listener of a event is removed
                     listener must accept 2 parameters: 
                        type: event name of removed listener
                        listener: removed listener. If more than one listener is removed at once, this parameter passes an array containing all reomved listeners.
*/


class AEEmitter
{
    _events := {}
    _eventsCount := 0
    _maxListener := 10

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

    maxListener[]
    {
        get
        {
            return this._maxListener
        }

        set
        {
            throw Exception("Set to read only property", -1, "maxListener")
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
        return this._AddListener(type, callback, prepend)
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
     *   This listener will be removed Once it has been executed
     *   @params: type event name waited
     *   @params: callback listener
     *   @params: prepend If ture, add listener to the head of listener list(will be execute earlier)
     */
    Once(type, listener, prepend := false)
    {
        return this._AddListener(type, listener, prepend, true)
    }

    /**
     *   Add a listener to wait for a event
     *   @params: type event name waited
     *   @params: listener listener
     *   @params: prepend If ture, add listener to the head of listener list(will be execute earlier)
     */
    AddListener(type, listener, prepend := false)
    {
        return this._AddListener(type, listener, prepend)
    }

    /**
     *   Add a listener in the head of listener list(will be execute earlier) to wait for a event
     *   @params: type event name waited
     *   @params: listener listener
     */
    PrependListener(type, listener) 
    {
        return this._AddListener(type, listener, true)   
    }

    /**
     *   Remove a listener waiting for a event
     *   @params: type event name waited
     *   @params: listener listener to be removed
     */
    RemoveListener(type, listener)
    {
        events := this._events, list := events[type]
        for p, l in list
        {
            if (l == listener) 
            {
                list.RemoveAt(p)
                if (list.Length() == 0)
                    this.RemoveEvent(type)
                if (events.HasKey("removeListener"))
                    this.Emit("removeListener", type, listener)
                break
            }
        }
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
            listeners := events[type]
            , this.RemoveEvent(type)
        if (events.HasKey("removeListener"))
            this.Emit("removeListener", type, listeners)
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
            {
                if (!IsFunc(handler))
                    handler := ObjBindMethod(this, "_OnceWapper", type, handler)
                __AEE_EventDispatcher.Put(handler, params)
            }
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
            {
                if (!IsFunc(handler))
                    handler := ObjBindMethod(this, "_OnceWapper", type, handler)
                __AEE_EventDispatcher.Put(handler, params, true)
            }
        }
        return true
    }

    /**
     *  Set property maxListener
     */
    SetMaxListener(number)
    {
        n := number&-1
        if (number != n) 
            throw Exception("Value Error!", -1, "Need an integer.")
        this._maxListener := n
    }

    /**
     *  return number of listeners of a event
     */
    ListenerCount(type)
    {
        return this._events.HasKey(type) ? this._events[type].Length() : 0
    }

    /**
     *  return all listeners(in a array) of a event
     */
    Listeners(type)
    {
        if (!this._events.HasKey(type))
            return []
        all_l := []
        for _, l in this._events
            l := IsFunc(l) ? l : l[1]
            , all_l.Push(l)
        return all_l
    }

    /**
     *  return all events' name(in a array) registered
     */
    EventNames()
    {
        names := []
        for name in this._events
            names.Push(name)
        return names
    }

    /*
     * Inner wapper for `Once` method to remove listener after executed
     * DO NOT CALL IT
     */
    _OnceWapper(type, fn, params*)
    {
        events := this._events, list := events[type]
        ; Once marked listener is contained in a 1 length array
        fn[1].Call(params*)
        this.RemoveListener(type, fn)
    }
    
    /*
     * Inner method.
     * DO NOT CALL IT
     */
    _AddListener(type, callback, prepend := false, isOnce := false)
    {
        if (!IsFunc(callback))
            throw Exception("Value Error", -2, "Listener(callback) must be a function or method")
        if (!this._events)
            this._events := {}
        events := this._events

        if (events.HasKey("newListener"))
            this.Emit("newListener", type, callback)
        if (!events.HasKey(type))
            events[type] := [], ++this._eventsCount
        if (events[type].Length() >= this._maxListener)
            throw Exception("The number of listeners has reached the maximum.", -2, "Use method SetMaxListener to increase it.")
        ; mark once by making a non-function callback   
        if (isOnce)
            callback := [callback]
        if (!prepend)
            events[type].Push(callback)
        else
            events[type].InsertAt(1, callback)
        return this
    }
}

; *************** INNER CLASS *******************
;             DO NOT DRICTLY CALL IT
;       UNLESS YOU KNOW WHAT YOU ARE DONING
; ***********************************************
class __AEE_EventDispatcher
{
    /*
     *  Based on DBGp_DispatchTimer of Lexikos's dbgp.ahk
     */
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
