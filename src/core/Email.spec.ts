import { assertThat, equalTo } from "hamjest"
import { Email } from "./Email"
import { EmailAddress } from "./EmailAddress"
import { EmailSubject } from "./EmailSubject"

describe(Email.name, () => {
  it("renders to a string", () => {
    assertThat(
      `${Email.from(EmailAddress.of("someone@example.com")).about(
        EmailSubject.of("a subject")
      )}`,
      equalTo("a subject [someone@example.com]")
    )
  })
})
