import { TinyTypeOf } from "tiny-types"

export class ContactsGroup extends TinyTypeOf<string>() {
  static named(value: string) {
    return new this(value)
  }
}
