defmodule Fastmail.Jmap.MethodCalls.GetAllChangedTest do
  alias Fastmail.Jmap.AccountState
  alias Fastmail.Jmap.Email
  alias Fastmail.Jmap.Contact
  alias Fastmail.Jmap.Collection
  alias Fastmail.Jmap.Thread
  alias Fastmail.Jmap.Mailbox
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Session

  use ExUnit.Case, async: false

  @tag :online
  test "fetches latest email changes" do
    Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
    |> Session.new()
    |> Session.execute(GetAllChanged, type: "Email", since_state: "J7100")
    |> dbg()
  end

  @tag :online
  test "fetches latest mailbox changes" do
    Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
    |> Session.new()
    |> Session.execute(GetAllChanged, type: "Mailbox", since_state: "J7100")
    |> dbg()
  end

  @tag :online
  test "fetches latest thread changes" do
    Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
    |> Session.new()
    |> Session.execute(GetAllChanged, type: "Thread", since_state: "J7100")
    |> dbg()
  end

  test "models the response when an email was updated" do
    response =
      Session.null(
        execute: [
          {{GetAllChanged, type: "Email", since_state: "J7100"},
           [
             [
               "Email/changes",
               %{
                 "accountId" => "u4d014069",
                 "created" => [],
                 "destroyed" => [],
                 "hasMoreChanges" => false,
                 "newState" => "J7138",
                 "oldState" => "J7100",
                 "updated" => ["Su4vMyni5WCk"]
               },
               "changes"
             ],
             [
               "Email/get",
               %{
                 "accountId" => "u4d014069",
                 "state" => "J7138",
                 "list" => [
                   %{
                     "attachments" => [],
                     "bcc" => nil,
                     "blobId" => "G1ba9881e530e3410968a1a9be7332ff7092b02b3",
                     "bodyValues" => %{},
                     "cc" => nil,
                     "from" => [%{"email" => "someone@example.com", "name" => nil}],
                     "hasAttachment" => false,
                     "htmlBody" => [
                       %{
                         "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
                         "charset" => "us-ascii",
                         "cid" => nil,
                         "disposition" => nil,
                         "language" => nil,
                         "location" => nil,
                         "name" => nil,
                         "partId" => "1",
                         "size" => 0,
                         "type" => "text/plain"
                       }
                     ],
                     "id" => "Su4vMyni5WCk",
                     "inReplyTo" => nil,
                     "keywords" => %{"$seen" => true, "$x-me-annot-2" => true},
                     "mailboxIds" => %{"P2F" => true},
                     "messageId" => ["99b181e7-9ee6-1a24-5cc8-4b4bf5e4d6a0@example.com"],
                     "preview" => "",
                     "receivedAt" => "2023-12-16T00:22:15Z",
                     "references" => nil,
                     "replyTo" => nil,
                     "sender" => nil,
                     "sentAt" => "2023-12-16T00:22:13Z",
                     "size" => 9075,
                     "subject" => "A subject",
                     "textBody" => [
                       %{
                         "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
                         "charset" => "us-ascii",
                         "cid" => nil,
                         "disposition" => nil,
                         "language" => nil,
                         "location" => nil,
                         "name" => nil,
                         "partId" => "1",
                         "size" => 0,
                         "type" => "text/plain"
                       }
                     ],
                     "threadId" => "AX_dGzpWbEk7",
                     "to" => [%{"email" => "test@levain.codes", "name" => nil}]
                   }
                 ],
                 "notFound" => []
               },
               "updated"
             ]
           ]}
        ]
      )
      |> Session.execute(GetAllChanged, type: "Email", since_state: "J7100")

    assert response ==
             %GetAllChanged.Response{
               type: :email,
               old_state: "J7100",
               updated: %Collection{
                 state: "J7138",
                 list: [
                   %Email{
                     id: "Su4vMyni5WCk",
                     thread_id: "AX_dGzpWbEk7",
                     from: [
                       %Contact{
                         email: "someone@example.com"
                       }
                     ],
                     mailbox_ids: ["P2F"]
                   }
                 ]
               }
             }
  end

  test "handles the response when a mailbox is updated" do
    response =
      Session.null(
        execute: [
          {{GetAllChanged, type: "Mailbox", since_state: "J7100"},
           [
             [
               "Mailbox/changes",
               %{
                 "accountId" => "u4d014069",
                 "created" => [],
                 "destroyed" => [],
                 "didFoldersSync" => 1,
                 "hasMoreChanges" => false,
                 "newState" => "J7138",
                 "oldState" => "J7100",
                 "updated" => ["P1k", "P2-", "P2V", "P2k", "P3-", "P3F", "P2F", "P-F"],
                 "updatedProperties" => nil
               },
               "changes"
             ],
             [
               "Mailbox/get",
               %{
                 "accountId" => "u4d014069",
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
               "updated"
             ]
           ]}
        ]
      )
      |> Session.execute(GetAllChanged, type: "Mailbox", since_state: "J7100")

    assert response ==
             %GetAllChanged.Response{
               type: :mailbox,
               old_state: "J7100",
               updated: %Collection{
                 state: "J7138",
                 list: [
                   %Mailbox{name: "Inbox", id: "P-F"},
                   %Mailbox{name: "Archive", id: "P1k"},
                   %Mailbox{name: "Drafts", id: "P2-"},
                   %Mailbox{name: "TestFolder", id: "P2F"},
                   %Mailbox{name: "TestFolderTwo", id: "P2V"},
                   %Mailbox{name: "Sent", id: "P2k"},
                   %Mailbox{name: "Spam", id: "P3-"},
                   %Mailbox{name: "Trash", id: "P3F"}
                 ]
               }
             }
  end

  test "handles the response when threads are updated" do
    response =
      Session.null(
        execute: [
          {{GetAllChanged, type: "Thread", since_state: "J7100"},
           [
             [
               "Thread/changes",
               %{
                 "accountId" => "u4d014069",
                 "created" => [],
                 "destroyed" => [],
                 "hasMoreChanges" => false,
                 "newState" => "J7138",
                 "oldState" => "J7100",
                 "updated" => ["AX_dGzpWbEk7"]
               },
               "changes"
             ],
             [
               "Thread/get",
               %{
                 "accountId" => "u4d014069",
                 "list" => [%{"emailIds" => ["Su4vMyni5WCk"], "id" => "AX_dGzpWbEk7"}],
                 "notFound" => [],
                 "state" => "J7138"
               },
               "updated"
             ]
           ]}
        ]
      )
      |> Session.execute(GetAllChanged, type: "Thread", since_state: "J7100")

    assert response ==
             %GetAllChanged.Response{
               type: :thread,
               old_state: "J7100",
               updated: %Collection{
                 state: "J7138",
                 list: [
                   %Thread{id: "AX_dGzpWbEk7", email_ids: ["Su4vMyni5WCk"]}
                 ]
               }
             }
  end

  describe "apply_to/2" do
    test "updating emails" do
      state =
        %AccountState{
          mailboxes:
            Collection.new("123", [
              %Mailbox{id: "inbox", name: "Inbox"},
              %Mailbox{id: "action", name: "Action"}
            ]),
          threads:
            Collection.new("123", [
              %Thread{id: "a-thread", email_ids: ["email-1"]}
            ]),
          emails:
            Collection.new("123", [
              %Email{
                id: "email-1",
                mailbox_ids: ["inbox"],
                from: [%Contact{email: "a@b.com"}],
                thread_id: "a-thread"
              }
            ])
        }

      response = %GetAllChanged.Response{
        type: :email,
        old_state: "123",
        updated:
          Collection.new("456", [
            %Email{
              id: "email-1",
              mailbox_ids: ["inbox", "action"],
              from: [%Contact{email: "a@b.com"}],
              thread_id: "a-thread"
            }
          ])
      }

      new_state = GetAllChanged.Response.apply_to(response, state)

      assert %AccountState{
               emails: %Collection{
                 state: "456",
                 list: [
                   %Email{mailbox_ids: ["inbox", "action"]}
                 ]
               }
             } = new_state
    end
  end
end
