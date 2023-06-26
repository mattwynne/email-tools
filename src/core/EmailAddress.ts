export class EmailAddress {
  static of(value: string) {
    return new this(value)
  }

  private constructor(public readonly address: string) {}
}
