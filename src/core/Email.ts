import { EmailAddress } from "./EmailAddress"

export class Email {
  static from(sender: EmailAddress) {
    return new this(sender)
  }

  private constructor(public readonly from: EmailAddress) {}
}
