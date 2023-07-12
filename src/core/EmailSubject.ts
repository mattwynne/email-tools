import { TinyTypeOf } from "tiny-types"

export class EmailSubject extends TinyTypeOf<string>() {
  static of(value: string) {
    return new this(value)
  }

  toString() {
    return this.value
  }
}
