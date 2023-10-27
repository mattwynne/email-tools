import EventSource from "eventsource"
import util from "util"
import Debug from "debug"
import { Headers } from "./FastmailSession"

const debug = Debug("Subscriber")

type Listener = (event: MessageEvent<any>) => void

type StateChange = {
  type: string
  changeed: {
    [accountId: string]: {
      Email: string
      EmailDelivery: string
      Mailbox: string
      Thread: string
    }
  }
}

export class Subscriber {
  public static async connect(url: string, headers: Headers) {
    const events = await new Promise<EventSource>((opened) => {
      const events = new EventSource(url, { headers })
      events.onopen = () => opened(events)
    })
    return new Subscriber(events)
  }

  private readonly listeners: Listener[] = []
  private constructor(private readonly events: EventSource) {}

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
    this.events?.addEventListener("state", listener)
  }

  public close() {
    for (const listener of this.listeners) {
      this.events.removeEventListener("state", listener)
    }
    this.events.close()
  }
}
