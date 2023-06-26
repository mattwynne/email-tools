export class ContactsGroup {
  static named(value: string) {
    return new this(value)
  }

  private constructor(public readonly name: string) {}
}
