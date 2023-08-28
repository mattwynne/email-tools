import {
  assertThat,
  equalTo,
  hasProperty,
  matchesPattern,
  throws,
} from "hamjest"
import { Environment } from "./Environment"

describe(Environment.name, () => {
  context("null mode", () => {
    it("creates with typical stubbed values", () => {
      const env = Environment.createNull()
      assertThat(env.FASTMAIL_USERNAME, equalTo("test@example.com"))
      assertThat(env.FASTMAIL_DAV_PASSWORD, equalTo("abcdef-12345"))
    })
  })

  context("real mode", () => {
    it("reads the real environment from the process", () => {
      const originalEnv = process.env
      process.env.FASTMAIL_USERNAME = "test-username"
      process.env.FASTMAIL_DAV_PASSWORD = "test-password"
      const env = Environment.create()
      assertThat(env.FASTMAIL_USERNAME, equalTo("test-username"))
      assertThat(env.FASTMAIL_DAV_PASSWORD, equalTo("test-password"))
      process.env = originalEnv
    })

    it("throws if keys are missing in the process environment", () => {
      const originalEnv = process.env
      delete process.env.FASTMAIL_USERNAME
      assertThat(() => {
        Environment.create()
      }, throws(hasProperty("message", matchesPattern(/Please set FASTMAIL_USERNAME./))))
      process.env = originalEnv
    })
  })
})
