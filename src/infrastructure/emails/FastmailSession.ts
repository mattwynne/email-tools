import EventSource from "eventsource"

type ApiMethod =
  | "Email/get"
  | "Email/set"
  | "Email/query"
  | "Mailbox/get"
  | "Mailbox/set"
  | "Mailbox/query"

type MethodCall = [method: ApiMethod, params: any, index: string]

export type FastmailConfig = {
  token: string
}

export type Headers = {
  "Content-Type": string
  Authorization: string
}

type Listener = (event: MessageEvent<any>) => void

class Subscriber {
  private events: EventSource | undefined
  private readonly listeners: Listener[] = []

  constructor(
    private readonly url: string,
    private readonly headers: Headers
  ) {}

  public addEventListener(handler: () => void) {
    if (!this.events) {
      this.events = new EventSource(this.url, { headers: this.headers })
    }
    const listener = (e: MessageEvent<any>) => {
      console.log(e.data)
      handler()
      // const changes: StateChange = JSON.parse(e.data).changed
    }
    this.listeners.push(listener)
    this.events.addEventListener("state", listener)
  }

  public close() {
    if (this.events) {
      for (const listener of this.listeners) {
        this.events.removeEventListener("state", listener)
      }
      this.events.close()
    }
  }
}

export class FastmailSession {
  static async create(token: string) {
    const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    }
    const hostname = "api.fastmail.com"
    const authUrl = `https://${hostname}/.well-known/jmap`
    const response = await fetch(authUrl, {
      method: "GET",
      headers,
    })
    return new this(headers, (await response.json()) as FastmailSession)
  }

  private readonly subscriber

  constructor(
    public readonly headers: Headers,
    private readonly data: FastmailSession
  ) {
    this.subscriber = new Subscriber(
      this.data.eventSourceUrl + "types=*",
      headers
    )
  }

  public close() {
    this.subscriber.close()
  }

  subscribe(handler: () => void) {
    // TODO - expose the subscriber through this method, then only people who use it have to close it.
    this.subscriber.addEventListener(handler)
  }

  get apiUrl(): string {
    return this.data.apiUrl
  }

  get eventSourceUrl(): string {
    return this.data.eventSourceUrl
  }

  get username(): string {
    return this.data.username
  }

  get primaryAccounts(): { [urn: string]: string } {
    return this.data.primaryAccounts
  }

  get accountId(): string {
    return this.data.primaryAccounts["urn:ietf:params:jmap:mail"]
  }

  public async call(method: ApiMethod, params: any) {
    const responses = await this.calls([[method, params, "0"]])
    return responses[0][1]
  }

  public async calls(methodCalls: MethodCall[]) {
    const response = await fetch(this.apiUrl, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
        methodCalls,
      }),
    })
    if (!response.ok) {
      throw new Error(await response.text())
    }
    const result = await response.json()
    return result["methodResponses"]
  }
}
