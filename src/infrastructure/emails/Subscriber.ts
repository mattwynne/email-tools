import EventSource from "eventsource"
import { Headers } from "./FastmailSession"

type Listener = (event: MessageEvent<any>) => void

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

  public async addEventListener(handler: () => void) {
    const listener = (e: MessageEvent<any>) => {
      console.log(e.data)
      handler()
      // const changes: StateChange = JSON.parse(e.data).changed
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
