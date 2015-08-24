Feature: Products Page
  As a user
  I want to learn more about the products offered by FHLB
  In order to decide which ones are right for my bank

  Background:
    Given I am logged in

  @smoke @jira-mem-696
  Scenario: Member navigates to the product summary page via the resources dropdown
    Given I hover on the products link in the header
    When I click on the products summary link in the header
    Then I should see the "products summary" product page

  @smoke @jira-mem-697
  Scenario: Member navigates to the FRC product page
    When I hover on the products link in the header
    And I click on the frc link in the header
    Then I should see the "frc" product page

  @smoke @jira-mem-851
  Scenario: Member navigates to the FRC Embedded Cap product page
    When I hover on the products link in the header
    And I click on the frc embedded link in the header
    Then I should see the "frc embedded" product page

  @smoke @jira-mem-843
  Scenario: Member navigates to the ARC product page
    When I hover on the products link in the header
    And I click on the arc link in the header
    Then I should see the "arc" product page
