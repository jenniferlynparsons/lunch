Feature: Visiting the Reports Summary Page
  As a user
  I want to use visit the reports summary page for the FHLB Member Portal
  In order to view reports

Background:
  Given I am logged in

@smoke
Scenario: Visit reports summary page from header link
  Given I visit the dashboard
  When I click on the reports link in the header
  Then I should see "Report" as the report page's main title
  And I should see a table of "Price Indications" reports
  And I should see a table of "Credit" reports
  And I should see a table of "Collateral" reports
  And I should see a table of "Capital Stock" reports

Scenario: Member sees reports dropdown
  Given I visit the dashboard
  And I don't see the reports dropdown
  When I hover on the reports link in the header
  Then I should see the reports dropdown
