defmodule Fastmail.Contacts.Card do
  alias Fastmail.Contacts.Card.Group
  alias Fastmail.Contacts.Card.Individual
  alias Fastmail.Contacts.Card.Property
  require Logger

  def new(lines) when is_list(lines) do
    properties = lines |> Enum.map(&Property.parse/1)

    case Keyword.get(properties, :"X-ADDRESSBOOKSERVER-KIND") do
      "group" -> Group.new(properties)
      _ -> Individual.new(properties)
    end
  end

  def for_group(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    uid = Keyword.get(opts, :uid, Uniq.UUID.uuid4())
    rev = Keyword.get(opts, :rev, DateTime.utc_now() |> DateTime.to_iso8601())
    member_uids = Keyword.get(opts, :member_uids, [])
    %Group{name: name, uid: uid, rev: rev, member_uids: member_uids}
  end

  def for_individual(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    uid = Keyword.get(opts, :uid, Uniq.UUID.uuid4())
    rev = Keyword.get(opts, :rev, DateTime.utc_now() |> DateTime.to_iso8601())
    formatted_name = Keyword.fetch!(opts, :formatted_name)
    email = Keyword.fetch!(opts, :email)
    %Individual{name: name, uid: uid, rev: rev, formatted_name: formatted_name, email: email}
  end
end
