import { assertThat, equalTo, is, promiseThat, rejected, throws } from "hamjest"
import { Email, EmailSubject } from "../../core"
import { FastmailSession } from "./FastmailSession"
import { PushNotification, StateChange } from "./PushNotification"
import { reset } from "./reset"
import { sendTestEmail } from "./sendTestEmail"

describe(PushNotification.name, function () {
  this.timeout(process.env.SLOW_TEST_TIMEOUT || 30000)

  const token = process.env.FASTMAIL_API_TOKEN || "" // TODO: make env nullable infrastructure too
  let push: PushNotification

  this.beforeEach(async () => {
    await reset({ token })
  })

  this.afterEach(() => push && push.close())

  it("fails to connect with bad details", async () => {
    const attemptingConnection = PushNotification.connect({
      eventSourceUrl: "a-bad-url",
      headers: { Authorization: "a-bad-token", "Content-Type": "whatever" },
    })
    return promiseThat(attemptingConnection, is(rejected()))
  })

  it("connects with an initial state", async () => {
    const session = await FastmailSession.create(token)
    push = await PushNotification.connect(session)
    assertThat(push.state.type, equalTo("connect"))
  })

  it("emits and sets state when an email is received", async () => {
    const session = await FastmailSession.create(token)
    push = await PushNotification.connect(session)
    await sendTestEmail(
      Email.from("someone@example.com").about(EmailSubject.of("A subject"))
    )
    const changes = await listeningForChanges(1)
    assertThat(changes[0].type, equalTo("delivery"))
    assertThat(push.state.type, equalTo("delivery"))
  })

  const listeningForChanges = (expectedNumberOfChanges: number) => {
    const changes: StateChange[] = []
    return new Promise<StateChange[]>((resolve) =>
      push.addEventListener((stateChange) => {
        console.log("got a message in the tests")
        changes.push(stateChange)
        if (changes.length == expectedNumberOfChanges) resolve(changes)
      })
    )
  }
})
