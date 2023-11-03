import EventSource from "eventsource"
import util from "util"
import Debug from "debug"
import { Headers } from "./FastmailSession"

const debug = Debug("email-tools:PushNotification")

type Listener = (event: MessageEvent<any>) => void

export type StateChange = {
  type: string
  changed: {
    [accountId: string]: {
      Email: string
      EmailDelivery: string
      Mailbox: string
      Thread: string
    }
  }
}

export class PushNotification {
  public static async connect({
    eventSourceUrl,
    headers,
  }: {
    eventSourceUrl: string
    headers: Headers
  }) {
    const eventSource = await new Promise<EventSource>((opened) => {
      const eventSource = new EventSource(eventSourceUrl, { headers })
      eventSource.onerror = (e: MessageEvent<any>) => {
        throw new Error("Could not connect EventSource: " + JSON.stringify(e))
      }
      eventSource.onopen = () => opened(eventSource)
    })
    return await new Promise<PushNotification>((connected) => {
      eventSource.addEventListener("state", ({ data }: MessageEvent<any>) => {
        const initialState: StateChange = JSON.parse(data)
        connected(new PushNotification(eventSource, initialState))
      })
    })
  }

  private readonly listeners: Listener[] = []
  private constructor(
    private readonly eventSource: EventSource,
    private currentState: StateChange
  ) {
    this.addEventListener((newState) => (this.currentState = newState))
  }

  public get state() {
    return this.currentState
  }

  public async addEventListener(handler: (changes: StateChange) => void) {
    const listener = (e: MessageEvent<any>) => {
      const changes: StateChange = JSON.parse(e.data)
      debug(
        util.inspect(changes, {
          showHidden: false,
          depth: null,
          colors: true,
        })
      )
      handler(changes)
    }
    this.listeners.push(listener)
    this.eventSource?.addEventListener("state", listener)
  }

  public close() {
    for (const listener of this.listeners) {
      this.eventSource.removeEventListener("state", listener)
    }
    this.eventSource.close()
  }
}
