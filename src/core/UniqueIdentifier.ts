import { TinyTypeOf } from "tiny-types"
import { UnknownValue } from "."

export class UniqueIdentifier extends TinyTypeOf<string>() {
  static of(value: string | UniqueIdentifier): UniqueIdentifier {
    if (typeof value !== "string") return value
    return new this(value)
  }

  static unknown() {
    return new UnknownValue<string>()
  }

  static create() {
    return new this(crypto.randomUUID())
  }
}
