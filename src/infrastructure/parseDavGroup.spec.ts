import { assertThat, equalTo } from "hamjest"
import { parseDavGroup } from "./parseDavGroup"

describe(parseDavGroup.name, () => {
  it("parses the name", () => {
    const data =
      "BEGIN:VCARD\r\n" +
      "VERSION:3.0\r\n" +
      "UID:a5e054a0-0234-4d05-8f19-b983f83afded\r\n" +
      "N:Friends\r\n" +
      "FN:Friends\r\n" +
      "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
      "REV:2023-08-28T21:26:33.477Z\r\n" +
      "END:VCARD"
    const parsed = parseDavGroup(data)
    assertThat(parsed.value, equalTo("Friends"))
  })
})
