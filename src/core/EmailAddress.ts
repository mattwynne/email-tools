import { TinyTypeOf } from "tiny-types"

export class EmailAddress extends TinyTypeOf<string>() {
  static of(value: string | EmailAddress) {
    if (typeof value !== "string") return value
    return new this(value)
  }

  toString() {
    return this.value
  }
}
