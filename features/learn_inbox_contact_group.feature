Feature: Learn inbox contact group

  Scenario: Drag new email to Paperwork
    Given an email in Inbox/Screener from noreply@dullbank.com
    When Matt drags the email into the Inbox/Paperwork folder
    Then noreploy@dullbank.com should be added to the "Paperwork" contacts group