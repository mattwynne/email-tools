export class EmailAddress extends String {
  static of(value: string) {
    return new this(value)
  }

  private constructor(public readonly address: string) {
    super(address)
  }
}
