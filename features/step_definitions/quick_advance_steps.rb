Then(/^I should see "(.*?)" in the quick advance flyout input field$/) do |text|
  expect(page.find('.flyout-top-section input').value()).to eq(text)
end

When(/^I open the quick advance flyout and enter (\d+)$/) do |amount|
  if page.first('.flyout', visible: true)
    step "I enter \"#{amount}\" into the \".dashboard-quick-advance-flyout input\" input field"
  else
    step "I enter \"#{amount}\" into the \".dashboard-module-advances input\" input field"
  end
  step "I should see a flyout"
  sleep 0.5 # we select a rate after the flyout opens, but in some cases selenium does its checks before that JS fires
end

When(/^I open the quick advance flyout$/) do
  @amount = Random.rand(100000) + 100000
  step "I open the quick advance flyout and enter #{@amount}"
end

Given(/^I am on the quick advance stock purchase screen$/) do
  step "I open the quick advance flyout and enter 1000131"
  step "I select the rate with a term of \"2week\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should be on the quick advance stock purchase screen"
end

Given(/^I select the continue with advance option$/) do
  page.find('#continue_transaction').click
end

When(/^I click on the continue with request button$/) do
  page.find('.dashboard-quick-advance-flyout .confirm-quick-advance-capstock').click
end

Then(/^I should see the cumulative stock purchase on the preview screen$/) do
  page.assert_selector('.dashboard-quick-advance-flyout .quick-advance-preview dt', visible: true, exact: true, text: I18n.t('dashboard.quick_advance.field_headings.cumulative') + ':')
end

When(/^I go back to the quick advance rate table$/) do
  quick_advance_go_back('.dashboard-quick-advance-flyout .quick-advance-rates', 2)
end

When(/^I preview a loan that doesn't require a capital stock purchase$/) do
  step "I enter \"999999\" into the \".dashboard-quick-advance-flyout input\" input field"
  step "I select the rate with a term of \"2week\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should see a preview of the quick advance"
end

Given(/^I am on the quick advance stock purchase screen for an advance with a collateral error$/) do
  step "I open the quick advance flyout and enter 1000121"
  step "I select the rate with a term of \"2week\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should be on the quick advance stock purchase screen"
end

Then(/^I see a collateral limit error$/) do
  step %{I should see a "insufficient collateral" error with amount 1000121 and type "whole"}
end

When(/^I go back to the capital stock purchase screen$/) do
  quick_advance_go_back('.dashboard-quick-advance-flyout .quick-advance-capstock', 1)
end

Then(/^I should see only one quick advance stock purchase screen$/) do
  page.assert_selector('.dashboard-quick-advance-flyout .quick-advance-capstock', count: 1, visible: true)
end

Then(/^I should not see the cumulative stock purchase on the preview screen$/) do
  page.assert_no_selector('.dashboard-quick-advance-flyout .quick-advance-preview dt', visible: true, exact: true, text: I18n.t('dashboard.quick_advance.field_headings.cumulative') + ':')
end

Then(/^I should be on the quick advance stock purchase screen$/) do
  page.assert_selector('.dashboard-quick-advance-flyout .quick-advance-capstock', visible: true)
end

When(/^I click on the View Recent Price Indications link$/) do
  page.find('.quick-advance-desk-closed-message a', text: I18n.t('dashboard.quick_advance.advances_desk_closed_link').upcase ).click
end

Then(/^I should see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', visible: true)
end

Then(/^I should not see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', :visible => :hidden)
end

Then(/^I should see a rate for the "(.*?)" term with a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").text.should_not eql("")
end

Then(/^I should see a blacked out value for the "(.*?)" term with a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").text.should eql('–')
end

When(/^I hover on the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").hover
end

Then(/^I should see the quick advance table tooltip for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}'] .tooltip", visible: true)
end

Then(/^I should see the quick advance table tooltip for the cell with a term of "(.*?)", a type of "(.*?)" and a maturity date of "(.*?)"$/) do |term, type, text|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}'] .tooltip-pair span:last-child", visible: true, text: text)
end

When(/^I select the rate with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  @rate_term = term
  @rate_type = type
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").click
end

When(/^I see the unselected state for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.assert_no_selector(".dashboard-quick-advance-flyout td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

When(/^I see the deactivated state for the initiate advance button$/) do
  page.assert_no_selector(".dashboard-quick-advance-flyout .initiate-quick-advance.active")
end

Then(/^I should see the selected state for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.assert_selector(".dashboard-quick-advance-flyout td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

Then(/^the initiate advance button should be active$/) do
  page.assert_selector(".dashboard-quick-advance-flyout .initiate-quick-advance.active")
end

When(/^I click on the initiate advance button$/) do
  page.find(".dashboard-quick-advance-flyout .initiate-quick-advance.active", visible: true).click
end

Then(/^I should see a preview of the quick advance$/) do
  page.assert_selector('.quick-advance-preview', visible: true)
  #valdiate_passed_advance_params
end

Then(/^I should see an interest payment frequency of "(.*?)"$/) do |field|
  page.assert_selector('.quick-advance-summary dd', text: I18n.t("dashboard.quick_advance.table.#{field}"), visible: true)
end

Then(/^I should see a preview of the quick advance with a notification about the new rate$/) do
  page.assert_selector('.quick-advance-preview', visible: true)
  page.assert_selector('.quick-advance-updated-rate')
end

Then(/^I should see an initiate advance button with a notification about the new rate$/) do
  page.assert_selector('.confirm-quick-advance', text: I18n.t('dashboard.quick_advance.buttons.new_rate'))
end

When(/^the quick advance rate has changed$/) do
  # implement code to ensure rate is displayed as having changed
end

When(/^the desk has closed$/) do
  # implement code to ensure desk has closed
end

When(/^there is limited pricing today$/) do
  # implement code to ensure there is a limited pricing message for today
end

When (/^I click on the link to view limited pricing information$/) do
  page.find('.quick-advance-limited-pricing-notice').click
end

Then (/^I should see the limited pricing information message$/) do
  page.assert_selector('.quick-advance-limited-pricing-message', visible: true)
end

Then(/^I should not see a preview of the quick advance$/) do
  page.assert_no_selector(".quick-advance-preview")
end

When(/^I click on the back button for the quick advance preview$/) do
  step 'I scroll to the bottom of the screen'
  page.find(".quick-advance-back-button", visible: true).click
end

When(/^I click on the quick advance confirm button$/) do
  step 'I scroll to the bottom of the screen'
  page.find(".confirm-quick-advance").click
end

Then(/^I should see confirmation number for the advance$/) do
  page.assert_selector('.quick-advance-summary dt', text: "Advance Number:", visible: true)
  validate_passed_advance_params
end

Then(/^I should not see the quick advance preview message$/) do
  page.assert_no_selector('.quick-advance-preview-message');
end

Then(/^I should see the quick advance confirmation close button$/) do
  page.assert_selector('.quick-advance-confirmation .primary-button', text: I18n.t('global.close').upcase, visible: true)
end

Then(/^I should see the quick advance interstitial$/) do
  page.assert_selector('.quick-advance-body .quick-advance-loading-message', visible: true)
end

Given(/^I am on the quick advance preview screen$/) do
  step "I open the quick advance flyout"
  step "I select the rate with a term of \"2week\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should not see the quick advance table"
  step "I should see a preview of the quick advance"
end

Then(/^I successfully execute a quick advance$/) do
  step "I open the quick advance flyout"
  step "I select the rate with a term of \"2week\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should not see the quick advance table"
  step "I should see a preview of the quick advance"
  step "I enter my SecurID pin and token"
  step "I click on the quick advance confirm button"
  step "I should see confirmation number for the advance"
  step "I should not see the quick advance preview message"
  step "I should see the quick advance confirmation close button"
end

When(/^I click on the quick advance confirmation close button$/) do
  page.find('.quick-advance-confirmation .primary-button', text: I18n.t('global.close').upcase).click
  sleep 1
end

Then(/^I should see an? "(.*?)" error(?: with amount (\d+) and type "(.*?)")?$/) do |error_type, amount, type|
  collateral_type = case type
    when 'whole'
      I18n.t('dashboard.quick_advance.table.mortgage')
    when 'agency'
      I18n.t('dashboard.quick_advance.table.agency')
    when 'aaa'
      I18n.t('dashboard.quick_advance.table.aaa')
    when 'aa'
      I18n.t('dashboard.quick_advance.table.aa')
  end
  text = case error_type
    when 'insufficient financing availability'
      /\A#{Regexp.quote(strip_tags(I18n.t("dashboard.quick_advance.error.insufficient_financing_availability_html", amount: fhlb_formatted_currency(amount.to_i, precision: 0))))}\z/
    when 'insufficient collateral'
      /\A#{Regexp.quote(strip_tags(I18n.t("dashboard.quick_advance.error.insufficient_collateral_html", amount: fhlb_formatted_currency(amount.to_i, precision: 0), collateral_type: collateral_type)))}\z/
    when 'advance unavailable'
      /\A#{Regexp.quote(I18n.t('dashboard.quick_advance.error.advance_unavailable', phone_number: service_desk_phone_number))}\z/
    when 'rate expired'
      /\A#{Regexp.quote(I18n.t("dashboard.quick_advance.error.rate_expired"))}\z/
    else
      raise 'Unknown error_type'
  end
  page.assert_selector('div.quick-advance-icon-section.icon-error-before p', visible: true, text: text)
end

Then(/^I should see SecurID errors$/) do
  page.assert_selector('.quick-advance-preview .form-error', visible: true)
  page.assert_selector('.quick-advance-preview input.input-field-error', visible: true)
end

def validate_passed_advance_params
  page.assert_selector('.quick-advance-summary span', visible: true, text: fhlb_formatted_currency(@amount, html: false, precision: 0))
  page.assert_selector('.quick-advance-summary dd', visible: true, text: I18n.t("dashboard.quick_advance.table.axes_labels.#{@rate_term}"))
  rate_type_text = case @rate_type
  when 'whole'
    I18n.t('dashboard.quick_advance.table.whole_loan')
  when 'aaa', 'aa', 'agency'
    I18n.t("dashboard.quick_advance.table.#{@rate_type}")
  else
    I18n.t('global.none')
  end
  page.assert_selector('.quick-advance-summary dd', visible: true, text: rate_type_text)
end

def quick_advance_go_back(selector, max_steps)
  back_count = 0
  while page.all(selector, visible: true, wait: 2).count == 0 && back_count <= max_steps
    (
      page.first('.dashboard-quick-advance-flyout .quick-advance-back-button', visible: true) ||
      page.first('.dashboard-quick-advance-flyout .secondary-button', visible: true, text: I18n.t('dashboard.quick_advance.buttons.back').upcase)
    ).click
    back_count = back_count + 1
  end
  expect(back_count).to be <= max_steps
end

Given(/^I enter my SecurID pin$/) do
  page.find('input[name=securid_pin]').set(Random.rand(9999).to_s.rjust(4, '0'))
end

Given(/^I enter my SecurID token$/) do
  page.find('input[name=securid_token]').set(Random.rand(999999).to_s.rjust(6, '0'))
end

When(/^I enter "([^"]*)" for my SecurID (pin|token)$/) do |value, field|
  page.find("input[name=securid_#{field}]").set(value)
end

Then(/^I shouldn't see the SecurID fields$/) do
  page.assert_no_selector("input[name=securid_pin]")
  page.assert_no_selector("input[name=securid_token]")
end

Given(/^I enter my SecurID pin and token$/) do
  step %{I enter my SecurID pin}
  step %{I enter my SecurID token}
end