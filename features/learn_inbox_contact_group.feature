Feature: Learn inbox contact group

  Scenario: Drag new email to Paperwork
    Given an email in Inbox/Screener from noreply@dullbank.com
    When the email is added to Inbox/Paperwork
    Then noreply@dullbank.com should be added to the Paperwork contacts group
