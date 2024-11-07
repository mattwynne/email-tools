defmodule Fastmail.Contacts.GroupsTest do
  use ExUnit.Case, async: true

  describe "loading from propfind XML" do
    test "enumerates the groups found in the XML" do
      raw_xml = File.read!(Path.join(__DIR__, "propfind-response.xml"))
      groups = Fastmail.Contacts.Groups.from_xml(raw_xml)
      assert Enum.count(groups) == 1
    end

    test "each group has a URL to its card" do
      raw_xml = File.read!(Path.join(__DIR__, "propfind-response.xml"))
      groups = Fastmail.Contacts.Groups.from_xml(raw_xml)

      assert Enum.at(groups, 0).href =~
               ~r"/dav/addressbooks/user/test@levain.codes/Default/[a-f0-9-]+.vcf"
    end
  end
end
