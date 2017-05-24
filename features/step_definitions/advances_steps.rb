Then(/^I should see active advances data$/) do
  page.assert_selector('.advances-main-body', visible: true)
end

Then(/^I should see a advances table with multiple data rows$/) do
  page.assert_selector('.report-table tbody tr')
end

Given(/^I am on the "(.*?)" advances page$/) do |advances|
  sleep_if_close_to_midnight
  @today = Time.zone.now.to_date
  case advances
    when 'Manage Advances'
      visit '/advances/manage'
    when 'Add Advance'
      visit '/advances/select-rate'
    else
      raise Capybara::ExpectationNotMet, 'unknown report passed as argument'
  end
end

Given(/^I don't see the advances dropdown$/) do
  page.find('.logo').hover # make sure the mouse isn't left on top of the reports dropdown from a different test
  advances_menu = page.find('.nav-menu', text: I18n.t('global.advances'))
  advances_menu.find(:xpath, '..').assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I click on the advances link in the header$/) do
  page.find('.secondary-nav li', text: I18n.t('global.advances')).click
end

Then(/^I should see an advances disabled message$/) do
  page.assert_selector('.etransact-status-message', text(I18n.t('advance_desk_unavailable', phone_number: service_desk_phone_number)))
end

When(/^I click the Manage Advances button$/) do
  page.find('.secondary-button', text: I18n.t('advances.manage_advances.title').upcase).click
end

Then(/^I should be on the Manage Advances page$/) do
  page.assert_selector('h1', text: I18n.t('advances.manage_advances.title'), exact: true, visible: true)
end

Then(/^I should not see the link for adding an advance$/) do
  page.assert_no_selector('.nav-dropdown a', text: I18n.t('advances.add_advance.nav'), exact: true)
end

Then(/^I should see the add advance rate table$/) do
  page.assert_selector('.advance-rates-table')
end

Then(/^I should see the add advance custom rate table$/) do
  page.assert_selector('.advance-rates-custom-table')
end

Then(/^I should not see the add advance rate table$/) do
  page.assert_no_selector('.advance-rates-table')
end

When(/^I enter "(.*?)" into the add advance amount field/) do |amount|
  step %{I enter "#{amount}" into the "input[name='advance_request[amount]'" input field}
end

Then(/^the add advance amount field should be blank$/) do
  expect(page.find("input[name='advance_request[amount]'").value).to eq('')
end

Then(/^the add advance amount field should show "(.*?)"/) do |text|
  expect(page.find("input[name='advance_request[amount]'").value).to eq(text)
end

When(/^I click the button to cancel my advance$/) do
  page.find('.cancel-advance').click
end

When(/^I enter an amount into the add advance amount field$/) do
  @amount = Random.rand(100010) + 100000
  step %{I enter "#{@amount}" into the add advance amount field}
end

#TODO - remove duplicate steps from 'quick_advance_steps.rb' once the dashboard quick advance is removed
Then(/^I should see a rate for the "(.*?)" term with a type of "(.*?) on the add advance page"$/) do |term, type|
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}']").text.should_not eql("")
end

Then(/^I should see a blacked out value for the "(.*?)" term with a type of "(.*?)" on the add advance page$/) do |term, type|
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}']").text.should eql('–')
end

When(/^I hover on the cell with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}']").hover
end

Then(/^I should see the add advance table tooltip for the cell with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}'] .tooltip", visible: true)
end

Then(/^I should see the add advance table tooltip for the cell with a term of "(.*?)", a type of "(.*?)" and a maturity date of "(.*?)" on the add advance page$/) do |term, type, text|
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}'] .tooltip-pair span:last-child", visible: true, text: text)
end

When(/^I select the rate with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  @rate_term = term
  @rate_type = type
  page.find(".advance-rates-table td[data-advance-term='#{term}'][data-advance-type='#{type}']").click
end

When(/^I select custom rate with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  @rate_type = type
  page.find(".advance-rates-custom-table td[data-advance-type='#{type}']").click
end

When(/^I see the unselected state for the cell with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  page.assert_no_selector(".advance-rates-table td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

When(/^I see the deactivated state for the initiate advance button on the add advance page$/) do
  page.assert_selector(".initiate-add-advance:disabled")
end

Then(/^I should see the selected state for the cell with a term of "(.*?)" and a type of "(.*?)" on the add advance page$/) do |term, type|
  page.assert_selector(".advance-rates-table td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

Then(/^the initiate advance button should be active on the add advance page$/) do
  page.assert_selector(".initiate-add-advance")
  page.assert_no_selector(".initiate-add-advance:disabled")
end

When(/^I click on the initiate advance button on the add advance page$/) do
  page.find(".initiate-add-advance", visible: true).click
end

When(/^I click on the edit button for the add advance preview$/) do
  step 'I scroll to the bottom of the screen'
  page.find(".edit-advance-button", visible: true).click
end

When(/^I am on the add advance preview screen$/) do
  step 'I am on the "Add Advance" advances page'
  step 'I enter an amount into the add advance amount field'
  step 'I click to toggle to the frc rates'
  step 'I select the rate with a term of "2week" and a type of "aaa" on the add advance page'
  step 'I click on the initiate advance button on the add advance page'
end

When(/^I confirm an added advance with a rate that changes$/) do
  step 'I enter my SecurID pin and token'
  allow_any_instance_of(AdvanceRequest).to receive(:rate_changed?).and_return(true)
  step 'I click on the add advance confirm button'
end

When(/^I confirm an added advance with a rate that remains unchanged$/) do
  step 'I enter my SecurID pin and token'
  allow_any_instance_of(AdvanceRequest).to receive(:rate_changed?).and_return(false)
  step 'I click on the add advance confirm button'
end

Given(/^I am on the add advance stock purchase screen$/) do
  step 'I am on the "Add Advance" advances page'
  step 'I enter "1000131" into the add advance amount field'
  step 'I click to toggle to the frc rates'
  step 'I select the rate with a term of "2week" and a type of "whole" on the add advance page'
  step 'I click on the initiate advance button on the add advance page'
  step "I should be on the add advance stock purchase screen"
end

Then(/^I should be on the add advance stock purchase screen$/) do
  page.assert_selector('.add-advance-capstock')
end

Then(/^I should be on the financing availability limit screen$/) do
  page.assert_selector('.add-advance-financing-availability-limit')
end

Then(/^I should see the cumulative stock purchase on the add advance preview screen$/) do
  page.assert_selector('.add-advance-preview dt', visible: true, exact: true, text: I18n.t('dashboard.quick_advance.field_headings.cumulative') + ':')
end

Then(/^I should not see the cumulative stock purchase on the add advance preview screen$/) do
  page.assert_no_selector('.add-advance-preview dt', visible: true, exact: true, text: I18n.t('dashboard.quick_advance.field_headings.cumulative') + ':')
end

When(/^I preview a loan that doesn't require a capital stock purchase on the add advance page$/) do
  step 'I enter "999999" into the add advance amount field'
  step 'I click to toggle to the frc rates'
  step 'I select the rate with a term of "2week" and a type of "whole" on the add advance page'
  step 'I click on the initiate advance button on the add advance page'
  step "I should see a preview of the advance"
end

Then(/^I should see the get another advance button$/) do
  page.assert_selector('.primary-button', text: I18n.t('advances.actions.another_advance').upcase, exact: true)
end

When(/^I click the get another advance button$/) do
  page.find('.primary-button', text: I18n.t('advances.actions.another_advance').upcase, exact: true).click
end

When(/^I successfully add an advance$/) do
  step 'I am on the add advance preview screen'
  step 'I enter my SecurID pin and token'
  step 'I click on the add advance confirm button'
  step 'I should see confirmation number for the added advance'
  step 'I should see the get another advance button'
end

When(/^I try to (preview|take out) an added advance on a disabled product$/) do |mode|
  amount = mode == 'preview' ? 100004 : 100005
  step 'I am on the "Add Advance" advances page'
  step "I enter \"#{amount}\" into the add advance amount field"
  step 'I click to toggle to the frc rates'
  step 'I select the rate with a term of "2week" and a type of "whole" on the add advance page'
  step 'I click on the initiate advance button on the add advance page'
  if mode == 'take out'
    step "I enter my SecurID pin and token"
    step 'I click on the add advance confirm button'
  end
end

Then(/^I should see a preview of the advance$/) do
  page.assert_selector('.add-advance-preview', visible: true)
end

Then(/^I should not see a preview of the advance$/) do
  page.assert_no_selector('.add-advance-preview', visible: true)
end

Then(/^I should see an advance interest payment frequency of "(.*?)"$/) do |field|
  page.assert_selector('.add-advance-summary dd', text: I18n.t("dashboard.quick_advance.table.#{field}"), visible: true)
end

Then(/^I should see an? "(.*?)" advance error(?: with amount (\d+) and type "(.*?)")?$/) do |error_type, amount, type|
  collateral_type = case type
    when 'whole'
      I18n.t('dashboard.quick_advance.table.whole_loan')
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
    when 'unauthorized'
      /\A#{Regexp.quote(I18n.t("dashboard.quick_advance.error.not_authorized"))}\z/
    when 'total daily limit'
      /\A#{Regexp.quote(I18n.t("dashboard.quick_advance.error.exceeds_daily_limit", limit: fhlb_formatted_currency_whole(100000000, {html: false})))}\z/
    when 'end time'
      /\A#{Regexp.quote(I18n.t("dashboard.quick_advance.error.end_of_day", time: fhlb_formatted_time(Time.zone.now - 5.minutes).strip))}\z/
    when 'exceeds maximum term'
      /\A#{Regexp.quote(I18n.t("dashboard.quick_advance.error.exceeds_maximum_term_#{type}", count: amount))}\z/
    else
      raise 'Unknown error_type'
  end
  page.assert_selector('.add-advance-icon-section.icon-error-before p', visible: true, text: text)
end

Then(/^I should see SecurID errors on the (Add Advance|Letter of Credit) preview page$/) do |request_type|
  css_selector = case request_type
  when 'Add Advance'
    '.add-advance-preview'
  when 'Letter of Credit'
    '.letters-of-credit-preview'
  end
  page.assert_selector("#{css_selector} .form-error", visible: true)
  page.assert_selector("#{css_selector} input.input-field-error", visible: true)
end

When(/^I click on the add advance confirm button$/) do
  step 'I scroll to the bottom of the screen'
  page.find(".confirm-add-advance").click
end

Then(/^I should see confirmation number for the added advance$/) do
  page.assert_selector('.add-advance-summary dt', text: "Advance Number:", visible: true)
  validate_passed_add_advance_params
end

Then(/^I should see an add advance error$/) do
  step %{I should see an "advance unavailable" advance error}
end

def validate_passed_add_advance_params
  page.assert_selector('.add-advance-summary span', visible: true, text: fhlb_formatted_currency(@amount, html: false, precision: 0))
  page.assert_selector('.add-advance-summary dd', visible: true, text: I18n.t("dashboard.quick_advance.table.axes_labels.#{@rate_term}"))
  rate_type_text = case @rate_type
    when 'whole'
      I18n.t('dashboard.quick_advance.table.whole_loan')
    when 'aaa', 'aa', 'agency'
      I18n.t("dashboard.quick_advance.table.#{@rate_type}")
    else
      I18n.t('global.none')
  end
  page.assert_selector('.add-advance-summary dd', visible: true, text: rate_type_text)
end

When(/^the add advance rate has changed$/) do
  # implement code to ensure rate is displayed as having changed
end

Then(/^there should be no rate selected$/) do
  page.assert_no_selector('.cell-selected')
end

When(/^I click on the dashboard module limited pricing notice$/) do
  page.find('.dashboard-module-limited-pricing-notice').click
end

When(/^I click to toggle to the (frc|vrc) rates$/) do |rate_type|
  page.find(".advance-rates-table-toggle span[data-active-term-type='#{rate_type}']").click
end

Then(/^I should not see any rates selected$/) do
  page.assert_no_selector('.advance-rates-table .rate-selected')
end

Then(/^I should (see|not see) the borrowing capacity sidebar/) do |visible|
  if visible == 'see'
    page.assert_selector('.sidebar-borrowing-capacity')
  elsif visible == 'not see'
    page.assert_no_selector('.sidebar-borrowing-capacity')
  end
end

Then(/^I should see Funding Date information$/) do
  page.assert_selector('.advance-funding-date-wrapper', visible: true)
end

Then(/^I should see Custom Term information$/) do
  page.assert_selector('.advance-custom-date-wrapper', visible: true)
end

When(/^I click on Edit Funding Date link$/) do
  page.find('.advance-alternate-funding-date-edit').click
end

When(/^I click on Close Funding Date link$/) do
  page.find('.advance-alternate-funding-date-close').click
end

Then(/^I should see Updated Funding Date$/) do
  page.assert_selector('.advance-funding-date-wrapper span:nth-child(2)', text: I18n.t('advances.funding.funding_on', date: fhlb_date_standard_numeric(@future_funding_date)), exact: true, visible: true)
end


When(/^I click on Add Custom Term link$/) do
  page.find('.advance-custom-date-add').click
end

When(/^I click on the Today radio button$/) do
  page.find('.advance-alternate-funding-date-wrapper ul li:first-child input[type=radio]').click
end

When(/^I click on the Next Business Day radio button$/) do
  @future_funding_date = page.find('.advance-alternate-funding-date-wrapper ul li:nth-child(2) input[type=radio]').value
  page.find('.advance-alternate-funding-date-wrapper ul li:nth-child(2) input[type=radio]').click
end

When(/^I click on the Skip Business Day radio button$/) do
  page.find('.advance-alternate-funding-date-wrapper ul li:last-child input[type=radio]').click
end

Then(/^I should see Set an Alternate Funding Date$/) do
  page.assert_selector('.advance-alternate-funding-date-wrapper')
end

Then(/^I should see Custom Term Calendar$/) do
  page.assert_selector('.advance-custom-date-maturity-calendar-partial', visible: true)
end

When(/^I click on the Cancel link$/) do
  page.find('.advance-custom-date-cancel').click
end

When(/^I click on Edit Custom Term link$/) do
  page.find('.advance-custom-date-edit').click
end

Then(/^I should see the View Rates For This Term button in its (enabled|disabled) state$/) do |state|
  if state == 'enabled'
    page.assert_no_selector('.view-custom-rates:disabled')
    page.assert_selector('.view-custom-rates')
  else
    page.assert_selector('.view-custom-rates:disabled')
  end
end

Then(/^I should see an Advance Confirmation column in the data table$/) do
  page.assert_selector('.manage-advances-table th', text: I18n.t('advances.confirmation.title'), exact: true)
end

When(/^I click the Add Advance button$/) do
  page.find('.advances-header-buttons a', text: I18n.t('advances.add_advance.nav').upcase, exact: true).click
end

Then(/^I see the "([^"]*)" filter selected$/) do |filter|
  page.assert_selector('.advances-filter span.active', text: filter, exact: true)
end

When(/^I filter the advances by "([^"]*)"$/) do |filter|
  page.find('.advances-filter span', text: filter, exact: true).click
end

Then(/^I see (only outstanding|all) advances$/) do |type|
  case type
  when 'only outstanding'
    page.assert_selector('.manage-advances-table tr td:nth-child(6) span')
  when 'all'
    page.assert_selector('.manage-advances-table tr td:nth-child(6)', text: I18n.t('global.missing_value'), exact: true)
  else
    raise ArgumentError.new("unknown advance type: #{type}")
  end
end

Given(/^I select the continue with advance option$/) do
  page.find('#continue_transaction').click
end

When(/^I click on the confirm add advance button$/) do
  page.find('.confirm-add-advance').click
end

When(/^I click on the View Rates For this Term button$/) do
  page.find('.view-custom-rates').click
end

Then(/^I should see the add advance confirmation page$/) do
  page.assert_selector('.add-advance-confirmation')
end

Then(/^I should see an advance amount of "([^"]*)"$/) do |amount|
  page.assert_selector('.add-advance-summary dl:first-child dd:first-of-type', text: fhlb_formatted_currency_whole(amount, html: false), exact: true)
end
