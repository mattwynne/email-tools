import { JSONValue, TinyType } from "tiny-types"

type NullValue<T> = { value: T } & TinyType

export class UnknownValue<Primitive> implements NullValue<Primitive> {
  public get value(): Primitive {
    throw new Error("Unknown value!")
  }

  equals(another: TinyType): boolean {
    throw new Error("Unknown value!")
  }

  toString(): string {
    throw new Error("Unknown value!")
  }

  toJSON(): JSONValue {
    throw new Error("Unknown value!")
  }
}
