import { assertThat, equalTo } from "hamjest"
import { parseDavContact, parseDavGroup } from "./parseDav"

describe(parseDavGroup.name, () => {
  const data =
    "BEGIN:VCARD\r\n" +
    "VERSION:3.0\r\n" +
    "UID:a5e054a0-0234-4d05-8f19-b983f83afded\r\n" +
    "N:Friends\r\n" +
    "FN:Friends\r\n" +
    "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
    "REV:2023-08-28T21:26:33.477Z\r\n" +
    "END:VCARD"

  it("parses the name", () => {
    const parsed = parseDavGroup(data)
    assertThat(parsed.name.value, equalTo("Friends"))
  })

  it("parses the id", () => {
    const parsed = parseDavGroup(data)
    assertThat(parsed.id.value, equalTo("a5e054a0-0234-4d05-8f19-b983f83afded"))
  })
})

describe(parseDavContact.name, () => {
  it("parses the email and ID", () => {
    const data =
      "BEGIN:VCARD\r\n" +
      "VERSION:3.0\r\n" +
      "UID:1cc1c622-9c8e-48e7-bfe4-8cf807d51f69\r\n" +
      "EMAIL:test@test.com\r\n" +
      "N:\r\n" +
      "FN:\r\n" +
      "REV:2023-08-28T22:54:03.019Z\r\n" +
      "END:VCARD"
    const parsed = parseDavContact(data)
    assertThat(parsed.email.value, equalTo("test@test.com"))
    assertThat(parsed.id.value, equalTo("1cc1c622-9c8e-48e7-bfe4-8cf807d51f69"))
  })

  it("parses a complex email", () => {
    const data =
      "BEGIN:VCARD\r\n" +
      "PRODID:-//CyrusIMAP.org//Cyrus 3.9.0-alpha0-701-g9b2f44d3ee-fm-202308..//EN\r\n" +
      "VERSION:3.0\r\n" +
      "UID:c5c309db-0df5-4ca6-9a35-3e8f9a8336b0\r\n" +
      "N:Person;Test;;;\r\n" +
      "FN:Test Person\r\n" +
      "ORG:;\r\n" +
      "TITLE:\r\n" +
      "NICKNAME:\r\n" +
      "EMAIL;TYPE=home;TYPE=pref:test@test.com\r\n" +
      "NOTE:\r\n" +
      "REV:20230828T225631Z\r\n" +
      "END:VCARD"
    const parsed = parseDavContact(data)
    assertThat(parsed.email.value, equalTo("test@test.com"))
  })
})
