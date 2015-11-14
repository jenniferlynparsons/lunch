require 'rails_helper'

RSpec.describe ResourcesController, type: :controller do
  login_user

  describe 'GET guides' do
    it_behaves_like 'a user required action', :get, :guides
    it 'should render the guides view' do
      get :guides
      expect(response.body).to render_template('guides')
    end
  end

  describe 'GET business_continuity' do
    it_behaves_like 'a user required action', :get, :guides
    it 'should render the guides view' do
      get :business_continuity
      expect(response.body).to render_template('business_continuity')
    end
  end

  describe 'GET capital_plan' do
    it_behaves_like 'a user required action', :get, :capital_plan
    it 'should render the capital plan view' do
      get :capital_plan
      expect(response.body).to render_template('capital_plan')
    end
  end

  describe 'GET forms' do
    it_behaves_like 'a user required action', :get, :forms
    it 'should render the guides view' do
      get :forms
      expect(response.body).to render_template('forms')
    end
    [
      :agreement_rows, :signature_card_rows, :wire_transfer_rows, :capital_stock_rows,
      :website_access_rows, :credit_rows, :lien_real_estate_rows, :lien_other_rows,
      :specific_identification_rows, :deposits_rows, :securities_rows, :loan_document_rows,
      :creditor_relationship_rows
      ].each do |var|
        it "should assign `@#{var}`" do
          get :forms
          expect(assigns[var]).to be_present
        end
      end
  end

  describe 'GET download' do
    it_behaves_like 'a user required action', :get, :download, file: 'foo'
    it 'should raise `ActionController::MissingFile` if an unknown file is requested' do
      expect { get :download, file: 'foo' }.to raise_error(ActionController::MissingFile)
    end
    it 'should raise `ActionController::MissingFile` if an unknown form is requested' do
      expect { get :download, file: 'form_0001' }.to raise_error(ActionController::MissingFile)
    end
    file_mapping = {
      'creditguide' => 'creditguide.pdf',
      'collateralguide' => 'collateralguide.pdf',
      'collateralreviewguide' => 'mortgage-loan-collateral-field-review-process.pdf',
      'corporation_assignment' => 'Corporate_Assignment.doc',
      'credit_union_amendment' => 'corporate-credit-union-amendment.docx',
      'credit_union_agreement' => 'subordination-agreement-credit-unions.pdf',
      'capitalplan' => 'capital-plan.pdf',
      'capitalplansummary' => 'capital-plan-summary.pdf',
      'pfi_agreement_resolution' => 'mpf-pfi-agreement-resolution.pdf',
      'delegation_of_authority' => 'mpf-delegation-of-authority.pdf',
      'delegation_of_authority_requests' => 'mpf-delegation-of-authority-requests-for-files-from-custodian.pdf',
      'delegation_of_authority_definitions' => 'mpf-delegation-of-authority-definitions.pdf',
      'pfi_agreement' => 'mpf-pfi-agreement.pdf',
      'pfi_application' => 'mpf-pfi-application.pdf',
      'mortgage_operations_questionnaire' => 'mpf-mortgage-operations-questionnaire.pdf',
      'mortgage_operations_questionnaire_addendum' => 'mpf-mortgage-operations-questionnaire-addendum.pdf',
      'mpf_fidelity' => 'mpf-fidelity-errors-omissions-insurance-worksheet-OG2.pdf',
      'anti_predatory' => 'mpf-anti-predatory-lending-questionnaire.pdf',
      'in_house' => 'mpf-in-house-QC-questionnaire.pdf',
      'collateral_file' => 'mpf-collateral-file-release-information.pdf',
      'post_closing' => 'mpf-post-closing-information.pdf',
      'servicer' => 'mpf-servicer-information.pdf',
      'servicer_account_remittance' => 'mpf-PI-custodial-account-agreement-SS-or-AA-single-remittance.pdf',
      'servicer_account_actual' => 'mpf-PI-custodial-account-agreement-AA.pdf',
      'servicer_account' => 'mpf-TI-custodial-account-agreement.pdf',
      'xtra_agreement' => 'mpf-xtra-agreement-for-access-to-fannie-mae-du-only.pdf',
      'xtra_addendum_mpf' => 'mpf-xtra-addendum-servicing-retained.pdf',
      'xtra_addendum_servcer_account' => 'mpf-xtra-PI-custodial-account-agreement-mpf-bank.pdf',
      'xtra' => 'mpf-xtra-TI-custodial-account-agreement.pdf',
      'xtra_addendum_mpf_released' => 'mpf-xtra-addendum-servicing-released.pdf',
      'direct_agreement' => 'mpf-direct-addendum-to-pfi-agreement.pdf',
      'direct_questionnaire' => 'mpf-direct-operations-questionnaire.pdf'
    }
    [
      2117, 2349, 2127, 2177, 1465, 1694, 2136, 2065, 2066, 2108, 2067, 2153, 2068, 2070,
      2071, 2065, 2109, 1685, 2239, 2238, 2160, 2228, 2051, 2192, 1465, 2215, 2161, 2237,
      2281, 2242, 2241, 2243, 2202, 2200, 2249, 1547, 2204, 1722, 449, 1227, 2143, 2194
    ].each do |form_number|
      file_mapping["form_#{form_number}"] = "fc#{form_number}.pdf"
    end
    file_mapping.each do |name, file|
      it "should send the file `#{file}` when `#{name}` is requested" do
        expect(subject).to receive(:send_file).with(Rails.root.join('private', file), filename: file).and_call_original
        get :download, file: name
      end
    end
  end
end
