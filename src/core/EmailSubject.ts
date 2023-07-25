import { TinyTypeOf } from "tiny-types"

export class EmailSubject extends TinyTypeOf<string>() {
  static of(value: string) {
    return new this(value)
  }

  static unknown() {
    return new UnknownValue()
  }

  toString() {
    return this.value
  }
}

class UnknownValue implements EmailSubject {
  public get value(): string {
    throw new Error("Uknown value!")
  }

  public toJSON(): string {
    throw new Error("Uknown value!")
  }

  public equals(): boolean {
    throw new Error("Uknown value!")
  }
}
