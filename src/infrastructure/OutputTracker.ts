// Copyright Titanium I.T. LLC. MIT License
import EventEmitter from "events"

/** A utility class for infrastructure wrappers to use track output */
export class OutputTracker<Change> {
  private _data: Change[]
  private _trackerFn: (data: Change) => void

  static create<T>(emitter: EventEmitter, event: string) {
    return new OutputTracker<T>(emitter, event)
  }

  constructor(
    private readonly _emitter: EventEmitter,
    private readonly _event: string
  ) {
    this._data = []

    this._trackerFn = (data: Change) => this._data.push(data)
    this._emitter.on(this._event, this._trackerFn)
  }

  get data() {
    return this._data
  }

  consume() {
    const result = [...this._data]
    this._data.length = 0
    return result
  }

  off() {
    this.consume()
    this._emitter.off(this._event, this._trackerFn)
  }
}
