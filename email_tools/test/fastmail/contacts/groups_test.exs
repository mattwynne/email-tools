defmodue Fastmail.Contacts.GroupsTest do
  describe "loading from propfind XML" do
    test "enumerates the groups found in the XML" do
      raw_xml = File.read(Path.join(__DIR__), "propfind-response")
      groups = Fastmail.Conacts.Groups.from_xml(raw_xml)
      assert Enum.length(groups) == 1
    end
  end
end
