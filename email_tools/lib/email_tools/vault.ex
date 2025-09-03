defmodule EmailTools.Vault do
  use Cloak.Vault, otp_app: :email_tools

  @impl GenServer
  def init(config) do
    config =
      Keyword.put(config, :ciphers, [
        default:
          {Cloak.Ciphers.AES.GCM,
           tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY", config)}
      ])

    {:ok, config}
  end

  defp decode_env!(var, _config) when is_binary(var) do
    case System.get_env(var) do
      nil ->
        case Application.get_env(:email_tools, EmailTools.Vault) do
          nil ->
            raise """
            environment variable #{var} is missing.
            Generate a key with: mix cloak.generate.key
            Then set the environment variable or add to config.
            """
          vault_config ->
            # Extract key from the already configured cipher in dev.exs
            case Keyword.get(vault_config, :ciphers) do
              [default: {Cloak.Ciphers.AES.GCM, cipher_config}] ->
                Keyword.get(cipher_config, :key)
              _ -> raise "Invalid cipher configuration"
            end
        end

      key ->
        Base.decode64!(key)
    end
  end
end