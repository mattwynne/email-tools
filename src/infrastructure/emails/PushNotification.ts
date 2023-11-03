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

class JmapEventSource {
  static async connect({
    eventSourceUrl,
    headers,
  }: {
    eventSourceUrl: string
    headers: Headers
  }) {
    return new Promise<JmapEventSource>((resolved) => {
      const eventSource = new EventSource(eventSourceUrl, { headers })
      eventSource.onerror = ({ data }: MessageEvent<string>) => {
        throw new Error(
          "Could not connect EventSource: " + JSON.stringify(data)
        )
      }
      eventSource.onopen = () => resolved(new JmapEventSource(eventSource))
    })
  }
  private readonly listeners: Listener[] = []
  public constructor(private readonly eventSource: EventSource) {}

  public async onStateChange(handler: (changes: StateChange) => void) {
    const listener = ({ data }: MessageEvent<string>) => {
      const changes: StateChange = JSON.parse(data)
      debug(changes)
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

export class PushNotification {
  public static async connect({
    eventSourceUrl,
    headers,
  }: {
    eventSourceUrl: string
    headers: Headers
  }) {
    const jmapEventSource = await JmapEventSource.connect({
      eventSourceUrl,
      headers,
    })
    return await new Promise<PushNotification>((connected) => {
      jmapEventSource.onStateChange((initialState) =>
        connected(new PushNotification(jmapEventSource, initialState))
      )
    })
  }

  private constructor(
    private readonly events: JmapEventSource,
    private currentState: StateChange
  ) {
    events.onStateChange((newState) => (this.currentState = newState))
  }

  public get state() {
    return this.currentState
  }

  public async addEventListener(handler: (changes: StateChange) => void) {
    this.events.onStateChange(handler)
  }

  public close() {
    this.events.close()
  }
}
