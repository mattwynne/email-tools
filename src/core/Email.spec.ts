import { assertThat, equalTo } from "hamjest"
import { Email, EmailAddress, EmailSubject } from "."

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
