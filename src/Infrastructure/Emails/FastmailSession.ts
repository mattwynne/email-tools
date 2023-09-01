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

  constructor(
    public readonly headers: { [key: string]: string },
    private readonly data: FastmailSession
  ) {}

  get apiUrl(): string {
    return this.data.apiUrl
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
