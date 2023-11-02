import { assertThat, equalTo } from "hamjest"
import { FastmailSession } from "./FastmailSession"
import { PushNotification, StateChange } from "./PushNotification"
import { Email, EmailSubject } from "../../core"
import { sendTestEmail } from "./sendTestEmail"
import { reset } from "./reset"

describe(PushNotification.name, function () {
  this.timeout(process.env.SLOW_TEST_TIMEOUT || 30000)

  const token = process.env.FASTMAIL_API_TOKEN || "" // TODO: make env nullable infrastructure too
  let push: PushNotification

  this.beforeEach(async () => {
    await reset({ token })
    const session = await FastmailSession.create(token)
    push = await PushNotification.connect(
      session.eventSourceUrl,
      session.headers
    )
  })

  this.afterEach(() => push.close())

  it("connects", async () => {
    const stateChange = await new Promise<StateChange>((resolve) =>
      push.addEventListener(resolve)
    )
    assertThat(stateChange.type, equalTo("connect"))
  })

  it("emits when an email is received", async () => {
    await new Promise<StateChange>((resolve) => push.addEventListener(resolve))
    await sendTestEmail(
      Email.from("someone@example.com").about(EmailSubject.of("A subject"))
    )
    const stateChange = await new Promise<StateChange>((resolve) =>
      push.addEventListener(resolve)
    )
    assertThat(stateChange.type, equalTo("delivery"))
  })
})
