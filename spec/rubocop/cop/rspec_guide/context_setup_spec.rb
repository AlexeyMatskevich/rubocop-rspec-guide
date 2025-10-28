# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::ContextSetup, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  # Characteristic: Presence of context setup (let/before)
  # States: no setup, has let, has let!, has before, has only subject

  context "when context lacks proper setup" do
    context "with no setup at all" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe 'User' do
            context 'when premium' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/ContextSetup: Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context
              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "with only subject (subject should be at describe level)" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe 'Calculator' do
            context 'with valid data' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/ContextSetup: Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context
              subject { Calculator.new(data) }

              it { is_expected.to be_valid }
            end
          end
        RUBY
      end
    end

    context "with only examples" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe 'User' do
            context 'when active' do
            ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/ContextSetup: Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context
              it 'can login' do
                expect(user.can_login?).to be true
              end

              it 'can post' do
                expect(user.can_post?).to be true
              end
            end
          end
        RUBY
      end
    end

    context "when nested context has no setup (inverse case)" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe 'User' do
            context 'when authenticated' do
              let(:user) { create(:user) }

              context 'and premium' do
              ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/ContextSetup: Context should have setup (let/let!/let_it_be/let_it_be!/before) to distinguish it from parent context
                it 'has access' do
                  expect(user).to have_access
                end
              end
            end
          end
        RUBY
      end
    end
  end

  context "when context has proper setup" do
    context "with let" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when premium' do
              let(:user) { create(:user, :premium) }

              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "with let!" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when premium' do
              let!(:subscription) { create(:subscription, :premium) }

              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "with before" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when premium' do
              before { user.upgrade_to_premium! }

              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "with let_it_be" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when premium' do
              let_it_be(:user) { create(:user, :premium) }

              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "with let_it_be!" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when premium' do
              let_it_be!(:user) { create(:user, :premium) }

              it 'has access' do
                expect(user).to have_access
              end
            end
          end
        RUBY
      end
    end

    context "when both parent and nested contexts have setup" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'User' do
            context 'when authenticated' do
              let(:user) { create(:user) }

              context 'and premium' do
                let(:subscription) { create(:subscription, :premium) }

                it 'has access' do
                  expect(user).to have_access
                end
              end
            end
          end
        RUBY
      end
    end

    context "when context has let with domain data" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe 'Calculator' do
            context 'with complex data' do
              let(:data) { build_complex_data }

              it { expect(calculator.process(data)).to be_valid }
            end
          end
        RUBY
      end
    end
  end
end
