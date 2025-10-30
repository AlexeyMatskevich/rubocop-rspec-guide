# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::MinimumBehavioralCoverage, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  # Characteristic: Number of sibling contexts in describe block
  # States: insufficient (0 or 1), sufficient (2+)

  context "when describe block has insufficient sibling contexts" do
    context "with no contexts at all" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#calculate' do
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/MinimumBehavioralCoverage: Describe block should test at least 2 behavioral variations: either use 2+ sibling contexts (happy path + edge cases), or combine it-blocks for default behavior with context-blocks for edge cases. Use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage` for simple cases (e.g., getters) with no edge cases.
            it 'works' do
              expect(result).to eq(100)
            end
          end
        RUBY
      end
    end

    context "with only 1 context" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#calculate' do
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/MinimumBehavioralCoverage: Describe block should test at least 2 behavioral variations: either use 2+ sibling contexts (happy path + edge cases), or combine it-blocks for default behavior with context-blocks for edge cases. Use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage` for simple cases (e.g., getters) with no edge cases.
            context 'when valid' do
              it 'works' do
                expect(result).to eq(100)
              end
            end
          end
        RUBY
      end
    end

    context "with nested contexts instead of sibling contexts" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#calculate' do
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/MinimumBehavioralCoverage: Describe block should test at least 2 behavioral variations: either use 2+ sibling contexts (happy path + edge cases), or combine it-blocks for default behavior with context-blocks for edge cases. Use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage` for simple cases (e.g., getters) with no edge cases.
            context 'when valid' do
              context 'with premium' do
                it 'works' do
                  expect(result).to eq(80)
                end
              end
            end
          end
        RUBY
      end
    end
  end

  context "when describe block has sufficient sibling contexts" do
    context "with exactly 2 sibling contexts" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            context 'when data is valid' do
              it 'calculates total' do
                expect(result).to eq(100)
              end
            end

            context 'when data is invalid' do
              it 'returns error' do
                expect(result).to be_error
              end
            end
          end
        RUBY
      end
    end

    context "with more than 2 sibling contexts" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            context 'with premium user' do
              it 'applies discount' do
                expect(result).to eq(80)
              end
            end

            context 'with regular user' do
              it 'no discount' do
                expect(result).to eq(100)
              end
            end

            context 'with invalid data' do
              it 'returns error' do
                expect(result).to be_error
              end
            end
          end
        RUBY
      end
    end
  end

  context "when describe block uses it-blocks + context-blocks pattern" do
    context "with single it-block followed by single context-block" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            it 'calculates with defaults' do
              expect(result).to eq(100)
            end

            context 'when data is invalid' do
              it 'returns error' do
                expect(result).to be_error
              end
            end
          end
        RUBY
      end
    end

    context "with multiple it-blocks followed by single context-block" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            it 'accepts true value', :aggregate_failures do
              expect { adapter.write(instance, true) }.not_to raise_error
              expect(instance.simple_feature).to be true
            end

            it 'accepts false value', :aggregate_failures do
              expect { adapter.write(instance, false) }.not_to raise_error
              expect(instance.simple_feature).to be false
            end

            context 'but with NOT valid values' do
              before { adapter.write(instance, "value") }

              it 'marks record as invalid' do
                expect(instance).not_to be_valid
              end
            end
          end
        RUBY
      end
    end

    context "with single it-block followed by multiple context-blocks" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            it 'calculates with defaults' do
              expect(result).to eq(100)
            end

            context 'when data is invalid' do
              it 'returns error' do
                expect(result).to be_error
              end
            end

            context 'when user is premium' do
              it 'applies discount' do
                expect(result).to eq(80)
              end
            end
          end
        RUBY
      end
    end

    context "with setup (before/let) + it-blocks + context-blocks" do
      it "does NOT register an offense" do
        expect_no_offenses(<<~RUBY)
          describe '#calculate' do
            let(:data) { build_data }
            before { setup_something }

            it 'calculates with defaults' do
              expect(result).to eq(100)
            end

            context 'when data is invalid' do
              it 'returns error' do
                expect(result).to be_error
              end
            end
          end
        RUBY
      end
    end

    context "with only it-blocks (no contexts)" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#calculate' do
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/MinimumBehavioralCoverage: Describe block should test at least 2 behavioral variations: either use 2+ sibling contexts (happy path + edge cases), or combine it-blocks for default behavior with context-blocks for edge cases. Use `# rubocop:disable RSpecGuide/MinimumBehavioralCoverage` for simple cases (e.g., getters) with no edge cases.
            it 'calculates with defaults' do
              expect(result).to eq(100)
            end

            it 'also calculates' do
              expect(result).to eq(200)
            end
          end
        RUBY
      end
    end
  end
end
