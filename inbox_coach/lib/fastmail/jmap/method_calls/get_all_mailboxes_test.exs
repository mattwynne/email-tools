defmodule Fastmail.Jmap.MethodCalls.GetAllMailboxesTest do
  import ExUnit.CaptureLog
  alias Fastmail.Jmap.AccountState
  alias Fastmail.Jmap.Collection
  alias Fastmail.Jmap.Mailbox
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias Fastmail.Jmap.Session
  use ExUnit.Case, async: false

  test "models the response" do
    session =
      Session.null(
        execute: [
          {{GetAllMailboxes},
           [
             [
               "Mailbox/get",
               %{
                 "accountId" => "u4d014069",
                 "didFoldersCheck" => 1,
                 "list" => [
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P-F",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => false,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => false,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Inbox",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "inbox",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 1,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P1k",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Archive",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "archive",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 3,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P2-",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Drafts",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "drafts",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 4,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P2F",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "TestFolder",
                     "parentId" => "P-F",
                     "purgeOlderThanDays" => 31,
                     "role" => nil,
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 10,
                     "suppressDuplicates" => true,
                     "totalEmails" => 1,
                     "totalThreads" => 1,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P2V",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "TestFolderTwo",
                     "parentId" => "P-F",
                     "purgeOlderThanDays" => 31,
                     "role" => nil,
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 10,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => false,
                     "hidden" => 0,
                     "id" => "P2k",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Sent",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "sent",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 5,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => true,
                     "hidden" => 0,
                     "id" => "P3-",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Spam",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "junk",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 6,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   },
                   %{
                     "autoLearn" => false,
                     "autoPurge" => true,
                     "hidden" => 0,
                     "id" => "P3F",
                     "identityRef" => nil,
                     "isCollapsed" => false,
                     "isSubscribed" => true,
                     "learnAsSpam" => false,
                     "myRights" => %{
                       "mayAddItems" => true,
                       "mayAdmin" => true,
                       "mayCreateChild" => true,
                       "mayDelete" => true,
                       "mayReadItems" => true,
                       "mayRemoveItems" => true,
                       "mayRename" => true,
                       "maySetKeywords" => true,
                       "maySetSeen" => true,
                       "maySubmit" => true
                     },
                     "name" => "Trash",
                     "parentId" => nil,
                     "purgeOlderThanDays" => 31,
                     "role" => "trash",
                     "sort" => [%{"isAscending" => false, "property" => "receivedAt"}],
                     "sortOrder" => 7,
                     "suppressDuplicates" => true,
                     "totalEmails" => 0,
                     "totalThreads" => 0,
                     "unreadEmails" => 0,
                     "unreadThreads" => 0
                   }
                 ],
                 "notFound" => [],
                 "state" => "J7138"
               },
               "mailboxes"
             ]
           ]}
        ]
      )

    response = Session.execute(session, GetAllMailboxes)

    assert ^response = %GetAllMailboxes.Response{
             mailboxes:
               Collection.new("J7138", [
                 %Mailbox{name: "Inbox", id: "P-F", role: :inbox},
                 %Mailbox{name: "Archive", id: "P1k", role: :archive},
                 %Mailbox{name: "Drafts", id: "P2-", role: :drafts},
                 %Mailbox{name: "TestFolder", id: "P2F", role: :none},
                 %Mailbox{name: "TestFolderTwo", id: "P2V", role: :none},
                 %Mailbox{name: "Sent", id: "P2k", role: :sent},
                 %Mailbox{name: "Spam", id: "P3-", role: :junk},
                 %Mailbox{name: "Trash", id: "P3F", role: :trash}
               ])
           }
  end

  test "logs warning for unknown mailbox role" do
    session =
      Session.null(
        execute: [
          {{GetAllMailboxes},
           [
             [
               "Mailbox/get",
               %{
                 "list" => [
                   %{
                     "id" => "custom-1",
                     "name" => "Custom Folder",
                     "role" => "unknown_custom_role"
                   }
                 ],
                 "state" => "test-state"
               },
               "mailboxes"
             ]
           ]}
        ]
      )

    log =
      capture_log(fn ->
        Session.execute(session, GetAllMailboxes)
      end)

    assert log =~ "Unknown mailbox role encountered: \"unknown_custom_role\""
  end

  describe "apply_to/2" do
    test "updating mailboxes in AccountState" do
      state = %AccountState{
        mailboxes:
          Collection.new("123", [
            %Mailbox{id: "inbox", name: "Inbox", role: :inbox},
            %Mailbox{id: "archive", name: "Archive", role: :archive}
          ])
      }

      response = %GetAllMailboxes.Response{
        mailboxes:
          Collection.new("456", [
            %Mailbox{id: "inbox", name: "Inbox Updated", role: :inbox},
            %Mailbox{id: "archive", name: "Archive", role: :archive},
            %Mailbox{id: "drafts", name: "Drafts", role: :drafts}
          ])
      }

      new_state = GetAllMailboxes.Response.apply_to(response, state)

      assert %AccountState{
               mailboxes: %Collection{
                 state: "456",
                 list: [
                   %Mailbox{id: "inbox", name: "Inbox Updated", role: :inbox},
                   %Mailbox{id: "archive", name: "Archive", role: :archive},
                   %Mailbox{id: "drafts", name: "Drafts", role: :drafts}
                 ]
               }
             } = new_state
    end
  end
end
