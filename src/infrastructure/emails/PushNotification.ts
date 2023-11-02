import EventSource from "eventsource"
import util from "util"
import Debug from "debug"
import { Headers } from "./FastmailSession"

const debug = Debug("email-tools:Subscriber")

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
  public static async connect(url: string, headers: Headers) {
    const eventSource = await new Promise<EventSource>((opened) => {
      const events = new EventSource(url, { headers })
      events.onopen = () => opened(events)
    })
    return new PushNotification(eventSource)
  }

  private readonly listeners: Listener[] = []
  private constructor(private readonly eventSource: EventSource) {}

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
