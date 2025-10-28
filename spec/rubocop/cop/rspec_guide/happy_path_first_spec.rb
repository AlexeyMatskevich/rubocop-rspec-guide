# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::HappyPathFirst, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  # Characteristic: Order of contexts (happy path vs corner cases)
  # States: corner case first, happy path first

  context "when corner case context appears first" do
    context 'with "but" keyword at start' do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#process_payment' do
            context 'but card is expired' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/HappyPathFirst: Place happy path contexts before corner cases. First context appears to be a corner case: but card is expired
              it { expect(result).to be_error }
            end
            context 'when card is valid' do
              it { expect(result).to be_success }
            end
          end
        RUBY
      end
    end

    context 'with "NOT" in caps' do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#activate' do
            context 'when user does NOT exist' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/HappyPathFirst: Place happy path contexts before corner cases. First context appears to be a corner case: when user does NOT exist
              it { expect(result).to be_error }
            end
            context 'when user exists' do
              it { expect(result).to be_success }
            end
          end
        RUBY
      end
    end

    context "with negative words (fails, error, etc.)" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#subscribe' do
            context 'when payment fails' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/HappyPathFirst: Place happy path contexts before corner cases. First context appears to be a corner case: when payment fails
              it { expect(result).to be_error }
            end
            context 'when payment succeeds' do
              it { expect(result).to be_success }
            end
          end
        RUBY
      end
    end

    context "with problematic state keywords (suspended, blocked)" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#login' do
            context 'when account is suspended' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/HappyPathFirst: Place happy path contexts before corner cases. First context appears to be a corner case: when account is suspended
              it { expect(result).to be_error }
            end
            context 'when account is active' do
              it { expect(result).to be_success }
            end
          end
        RUBY
      end
    end
  end

  context "when happy path context appears first" do
    context "with valid/success scenario first" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#subscribe' do
            context 'with valid card' do
              it { expect(result).to be_success }
            end
            context 'but payment fails' do
              it { expect(result).to be_error }
            end
          end
        RUBY
      end
    end

    context "with authenticated user first" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#process' do
            context 'when user is authenticated' do
              it { expect(result).to be_success }
            end
            context 'when user is NOT authenticated' do
              it { expect(result).to be_error }
            end
          end
        RUBY
      end
    end

    context 'with "without" (binary alternative, not negative)' do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            context 'without premium subscription' do
              it { expect(result).to eq(100) }
            end
            context 'with premium subscription' do
              it { expect(result).to eq(80) }
            end
          end
        RUBY
      end
    end

    context "when there is only one context" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#process' do
            context 'when error occurs' do
              it { expect(result).to be_error }
            end
          end
        RUBY
      end
    end
  end
end
