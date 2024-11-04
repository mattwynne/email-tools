defmodule Fastmail.Contacts.GroupsTest do
  use ExUnit.Case, async: true

  describe "loading from propfind XML" do
    test "enumerates the groups found in the XML" do
      raw_xml = File.read!(Path.join(__DIR__, "propfind-response.xml"))
      groups = Fastmail.Contacts.Groups.from_xml(raw_xml)
      assert Enum.count(groups) == 1
    end
  end
end
