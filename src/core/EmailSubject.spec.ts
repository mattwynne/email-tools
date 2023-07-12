import { assertThat, not, equalTo } from "hamjest"
import { EmailAddress } from "./EmailAddress"
import { EmailSubject } from "./EmailSubject"

describe(EmailSubject.name, () => {
  it(`it not equal to an ${EmailAddress.name} with the same value`, () => {
    assertThat(EmailAddress.of("one"), not(equalTo(EmailSubject.of("one"))))
  })

  it("can be rendered as a string", () => {
    assertThat(`${EmailSubject.of("one")}`, equalTo("one"))
  })
})
