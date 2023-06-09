import { TinyTypeOf } from "tiny-types"

export class EmailAddress extends TinyTypeOf<string>() {
  static of(value: string) {
    return new this(value)
  }

  toString() {
    return this.value
  }
}
