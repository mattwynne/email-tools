import { TinyTypeOf } from "tiny-types"
import { UnknownValue } from "."

export class EmailSubject extends TinyTypeOf<string>() {
  static of(value: string) {
    return new this(value)
  }

  static unknown() {
    return new UnknownValue<string>()
  }

  toString() {
    return this.value
  }
}
