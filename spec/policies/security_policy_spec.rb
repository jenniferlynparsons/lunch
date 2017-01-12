require 'rails_helper'

RSpec.describe SecurityPolicy, :type => :policy do
  let(:user) { instance_double(User, intranet_user?: false) }

  describe '`authorize_securities?` method' do
    subject { SecurityPolicy.new(user, :security) }

    context 'extranet user' do
      context "for a User with the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
        it { should permit_action(:authorize_securities) }
      end
      context "for a User without the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:authorize_securities) }
      end
    end
    context 'intranet user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(true)
      end
      context "for a User with the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
        it { should_not permit_action(:authorize_securities) }
      end
      context "for a User without the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:authorize_securities) }
      end
    end
  end

  describe '`authorize_collateral?` method' do
    subject { SecurityPolicy.new(user, :security) }

    context 'extranet user' do
      context "for a User with the `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::COLLATERAL_SIGNER]) }
        it { should permit_action(:authorize_collateral) }
      end
      context "for a User without the `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:authorize_collateral) }
      end
    end
    context 'intranet user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(true)
      end
      context "for a User with the `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::COLLATERAL_SIGNER]) }
        it { should_not permit_action(:authorize_collateral) }
      end
      context "for a User without the `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:authorize_collateral) }
      end
    end
  end

  describe '`delete?` method' do
    subject { SecurityPolicy.new(user, :securities_request) }

    context 'for an intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(true) }

      context "with the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
        it { should_not permit_action(:delete) }
      end
      context "without the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:delete) }
      end
    end
    context 'for an extranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(false) }

      context "with the `#{User::Roles::SECURITIES_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
        it { should permit_action(:delete) }
      end
      context "with the `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::COLLATERAL_SIGNER]) }
        it { should permit_action(:delete) }
      end
      context "without the `#{User::Roles::SECURITIES_SIGNER}` or `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([]) }
        it { should_not permit_action(:delete) }
      end
      context "with both the `#{User::Roles::SECURITIES_SIGNER}` and `#{User::Roles::COLLATERAL_SIGNER}` role" do
        before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER, User::Roles::COLLATERAL_SIGNER]) }
        it { should permit_action(:delete) }
      end
    end
  end

  describe '`submit?` method' do
    subject { SecurityPolicy.new(user, :securities_request) }

    context 'for an intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(true) }
      it { should_not permit_action(:submit) }
    end
    context 'for an extranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(false) }
      it { should permit_action(:submit) }
    end
  end
end