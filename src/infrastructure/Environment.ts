const defaultNullEnvironment: Environment = {
  FASTMAIL_DAV_PASSWORD: "abcdef-12345",
  FASTMAIL_USERNAME: "test@example.com",
}

const validateKeysExistIn = (env: NodeJS.ProcessEnv) => {
  const expectedKeys = Object.keys(Environment.createNull())
  const actualKeys = Object.keys(process.env)
  const missingKeys = expectedKeys.filter((key) => !actualKeys.includes(key))
  if (missingKeys.length > 0) {
    throw new Error(
      `Please set ${missingKeys.join(", ")}. Keys found: ${actualKeys}`
    )
  }
}

export class Environment {
  static create() {
    validateKeysExistIn(process.env)
    return new this(process.env as unknown as Environment)
  }

  static createNull(keys: Partial<Environment> = {}) {
    return new this({ ...defaultNullEnvironment, ...keys })
  }

  constructor(properties: Environment) {
    Object.assign(this, properties)
  }

  // @ts-ignore
  public readonly FASTMAIL_USERNAME: string
  // @ts-ignore
  public readonly FASTMAIL_DAV_PASSWORD: string
}
