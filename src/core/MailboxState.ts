import { MailboxName, UniqueIdentifier } from "."

export class MailboxState {
  static named(name: string | MailboxName) {
    return new this(UniqueIdentifier.unknown(), MailboxName.of(name), [])
  }

  private constructor(
    public readonly id: UniqueIdentifier,
    public readonly name: MailboxName,
    public readonly emailIds: UniqueIdentifier[]
  ) {}

  public withId(id: UniqueIdentifier | string) {
    return new MailboxState(UniqueIdentifier.of(id), this.name, this.emailIds)
  }

  public withEmailIds(ids: UniqueIdentifier[]) {
    return new MailboxState(this.id, this.name, ids)
  }
}
