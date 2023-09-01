import { DAVClient } from "tsdav"
import { Environment } from "../environment"

export interface Credentials {
  username: string
  password: string
}

export class FastmailCredentials implements Credentials {
  static create(env: Environment = Environment.create()) {
    return new this(env.FASTMAIL_USERNAME, env.FASTMAIL_DAV_PASSWORD)
  }

  static createNull(env: Environment = Environment.createNull()) {
    return this.create(env)
  }

  private constructor(
    public readonly username: string,
    public readonly password: string
  ) {}
}

export class Fastmail {
  static async createDavClient(config: Credentials) {
    const dav = new DAVClient({
      authMethod: "Basic",
      serverUrl: `https://carddav.fastmail.com/dav/addressbooks/user/${config.username}/Default`,
      credentials: {
        username: config.username.replace("@", "+Default@"),
        password: config.password,
      },
      defaultAccountType: "carddav",
    })
    await dav.login()
    return dav
  }
}
