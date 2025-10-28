# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::CharacteristicsAndContexts, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  # Characteristic: Number of sibling contexts in describe block
  # States: insufficient (0 or 1), sufficient (2+)

  context "when describe block has insufficient sibling contexts" do
    context "with no contexts at all" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          describe '#calculate' do
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/CharacteristicsAndContexts: Describe block should have at least 2 contexts (happy path + edge cases). Use `# rubocop:disable RSpecGuide/CharacteristicsAndContexts` if truly no edge cases exist.
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
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/CharacteristicsAndContexts: Describe block should have at least 2 contexts (happy path + edge cases). Use `# rubocop:disable RSpecGuide/CharacteristicsAndContexts` if truly no edge cases exist.
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
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/CharacteristicsAndContexts: Describe block should have at least 2 contexts (happy path + edge cases). Use `# rubocop:disable RSpecGuide/CharacteristicsAndContexts` if truly no edge cases exist.
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
end
