# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::DuplicateLetValues, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it "registers an offense for duplicate let with same value in all siblings" do
    expect_offense(<<~RUBY)
      describe 'Calculator' do
        context 'with addition' do
          let(:currency) { :usd }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:currency)` with same value `:usd` in ALL sibling contexts. Extract to parent context.
          it { expect(result).to eq(10) }
        end

        context 'with subtraction' do
          let(:currency) { :usd }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:currency)` with same value `:usd` in ALL sibling contexts. Extract to parent context.
          it { expect(result).to eq(5) }
        end
      end
    RUBY
  end

  it "registers an offense for duplicate let! with same value" do
    expect_offense(<<~RUBY)
      describe 'Calculator' do
        context 'scenario A' do
          let!(:user) { create(:user) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:user)` with same value `create(:user)` in ALL sibling contexts. Extract to parent context.
        end

        context 'scenario B' do
          let!(:user) { create(:user) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:user)` with same value `create(:user)` in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "does not register an offense when values differ" do
    expect_no_offenses(<<~RUBY)
      describe 'Calculator' do
        context 'with USD' do
          let(:currency) { :usd }
        end

        context 'with EUR' do
          let(:currency) { :eur }
        end
      end
    RUBY
  end

  it "registers a warning when let is duplicated in some but not all contexts" do
    expect_offense(<<~RUBY)
      describe 'Calculator' do
        context 'scenario A' do
          let(:currency) { :usd }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Let `:currency` with value `:usd` duplicated in 2/3 contexts. Consider refactoring test hierarchy - this suggests poor organization.
        end

        context 'scenario B' do
          # No currency let here
        end

        context 'scenario C' do
          let(:currency) { :usd }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Let `:currency` with value `:usd` duplicated in 2/3 contexts. Consider refactoring test hierarchy - this suggests poor organization.
        end
      end
    RUBY
  end

  context "when WarnOnPartialDuplicates is disabled" do
    let(:config) do
      rubocop_config_with_rspec_language(
        "RSpecGuide/DuplicateLetValues" => {
          "WarnOnPartialDuplicates" => false
        }
      )
    end

    it "does not register warnings for partial duplicates" do
      expect_no_offenses(<<~RUBY)
        describe 'Calculator' do
          context 'scenario A' do
            let(:currency) { :usd }
          end

          context 'scenario B' do
            # No currency let here
          end

          context 'scenario C' do
            let(:currency) { :usd }
          end
        end
      RUBY
    end

    it "still registers errors when duplicated in all contexts" do
      expect_offense(<<~RUBY)
        describe 'Calculator' do
          context 'scenario A' do
            let(:currency) { :usd }
            ^^^^^^^^^^^^^^^^^^^^^^^ Duplicate `let(:currency)` with same value `:usd` in ALL sibling contexts. Extract to parent context.
          end

          context 'scenario B' do
            let(:currency) { :usd }
            ^^^^^^^^^^^^^^^^^^^^^^^ Duplicate `let(:currency)` with same value `:usd` in ALL sibling contexts. Extract to parent context.
          end
        end
      RUBY
    end
  end

  it "does not register an offense for different let names" do
    expect_no_offenses(<<~RUBY)
      describe 'Calculator' do
        context 'scenario A' do
          let(:amount) { 100 }
        end

        context 'scenario B' do
          let(:total) { 100 }
        end
      end
    RUBY
  end

  it "registers an offense in 3 or more sibling contexts" do
    expect_offense(<<~RUBY)
      describe 'Calculator' do
        context 'A' do
          let(:tax) { 0.1 }
          ^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:tax)` with same value `0.1` in ALL sibling contexts. Extract to parent context.
        end

        context 'B' do
          let(:tax) { 0.1 }
          ^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:tax)` with same value `0.1` in ALL sibling contexts. Extract to parent context.
        end

        context 'C' do
          let(:tax) { 0.1 }
          ^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:tax)` with same value `0.1` in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "handles string values" do
    expect_offense(<<~RUBY)
      describe 'User' do
        context 'with email' do
          let(:domain) { "example.com" }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:domain)` with same value `"example.com"` in ALL sibling contexts. Extract to parent context.
        end

        context 'with username' do
          let(:domain) { "example.com" }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:domain)` with same value `"example.com"` in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "handles integer values" do
    expect_offense(<<~RUBY)
      describe 'Cart' do
        context 'with item A' do
          let(:quantity) { 5 }
          ^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:quantity)` with same value `5` in ALL sibling contexts. Extract to parent context.
        end

        context 'with item B' do
          let(:quantity) { 5 }
          ^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:quantity)` with same value `5` in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "handles hash values" do
    expect_offense(<<~RUBY)
      describe 'Calculator' do
        context 'with addition' do
          let(:config) { {timeout: 5} }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:config)` with same value `{timeout: 5}` in ALL sibling contexts. Extract to parent context.
          it { expect(result).to eq(10) }
        end

        context 'with subtraction' do
          let(:config) { {timeout: 5} }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:config)` with same value `{timeout: 5}` in ALL sibling contexts. Extract to parent context.
          it { expect(result).to eq(5) }
        end
      end
    RUBY
  end

  it "handles array values" do
    expect_offense(<<~RUBY)
      describe 'Processor' do
        context 'with operation A' do
          let(:options) { [:fast, :safe] }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:options)` with same value `[:fast, :safe]` in ALL sibling contexts. Extract to parent context.
        end

        context 'with operation B' do
          let(:options) { [:fast, :safe] }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateLetValues: Duplicate `let(:options)` with same value `[:fast, :safe]` in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "does not check nested contexts as siblings" do
    expect_no_offenses(<<~RUBY)
      describe 'Calculator' do
        context 'A' do
          let(:currency) { :usd }

          context 'nested' do
            let(:currency) { :usd }
          end
        end

        context 'B' do
          let(:currency) { :eur }
        end
      end
    RUBY
  end

  it "handles empty let blocks without crashing" do
    expect_no_offenses(<<~RUBY)
      describe '#descendants' do
        context 'when setting has no children' do
          let(:no_children) {}

          it { expect(result).to be_empty }
        end

        context 'when setting has children' do
          let(:child) { create(:child) }

          it { expect(result).not_to be_empty }
        end
      end
    RUBY
  end
end
