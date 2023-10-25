import { TinyTypeOf } from "tiny-types"
import { UnknownValue } from "./UnknownValue"

export class EmailAddress extends TinyTypeOf<string>() {
  static unknown(): EmailAddress {
    return new UnknownValue<string>()
  }

  static of(value: string | EmailAddress) {
    if (typeof value !== "string") return value
    return new this(value)
  }

  toString() {
    return this.value
  }
}
