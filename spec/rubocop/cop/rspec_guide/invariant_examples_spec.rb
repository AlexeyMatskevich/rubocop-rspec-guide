# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::InvariantExamples, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new("RSpecGuide/InvariantExamples" => {"MinLeafContexts" => 3}) }

  context "when example repeats in all leaf contexts" do
    it "registers an offense for example repeated in all leaf contexts" do
      expect_offense(<<~RUBY)
        describe 'Validator' do
          context 'with valid data' do
            it 'responds to valid?' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `responds to valid?` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(subject).to respond_to(:valid?)
            end
          end

          context 'with invalid data' do
            it 'responds to valid?' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `responds to valid?` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(subject).to respond_to(:valid?)
            end
          end

          context 'with empty data' do
            it 'responds to valid?' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `responds to valid?` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(subject).to respond_to(:valid?)
            end
          end
        end
      RUBY
    end

    it "handles nested contexts correctly" do
      expect_offense(<<~RUBY)
        describe 'Validator' do
          context 'group A' do
            context 'scenario 1' do
              it 'has interface' do
              ^^^^^^^^^^^^^^^^^^^^^ Example `has interface` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
                expect(subject).to respond_to(:process)
              end
            end

            context 'scenario 2' do
              it 'has interface' do
              ^^^^^^^^^^^^^^^^^^^^^ Example `has interface` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
                expect(subject).to respond_to(:process)
              end
            end
          end

          context 'group B' do
            it 'has interface' do
            ^^^^^^^^^^^^^^^^^^^^^ Example `has interface` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(subject).to respond_to(:process)
            end
          end
        end
      RUBY
    end

    it "handles multiple invariant examples" do
      expect_offense(<<~RUBY)
        describe 'API' do
          context 'endpoint A' do
            it 'requires authentication' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `requires authentication` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.status).to eq(401)
            end

            it 'returns JSON' do
            ^^^^^^^^^^^^^^^^^^^^ Example `returns JSON` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.content_type).to eq('application/json')
            end
          end

          context 'endpoint B' do
            it 'requires authentication' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `requires authentication` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.status).to eq(401)
            end

            it 'returns JSON' do
            ^^^^^^^^^^^^^^^^^^^^ Example `returns JSON` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.content_type).to eq('application/json')
            end
          end

          context 'endpoint C' do
            it 'requires authentication' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Example `requires authentication` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.status).to eq(401)
            end

            it 'returns JSON' do
            ^^^^^^^^^^^^^^^^^^^^ Example `returns JSON` repeats in all 3 leaf contexts. Consider extracting to shared_examples as an interface invariant.
              expect(response.content_type).to eq('application/json')
            end
          end
        end
      RUBY
    end
  end

  context "when example is only in some contexts" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        describe 'Validator' do
          context 'with valid data' do
            it 'responds to valid?' do
              expect(subject).to respond_to(:valid?)
            end
          end

          context 'with invalid data' do
            it 'responds to valid?' do
              expect(subject).to respond_to(:valid?)
            end
          end

          context 'with empty data' do
            it 'returns error' do
              expect(subject).to be_error
            end
          end
        end
      RUBY
    end
  end

  context "when there are less than configured minimum leaf contexts" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        describe 'Validator' do
          context 'with valid data' do
            it 'responds to valid?' do
              expect(subject).to respond_to(:valid?)
            end
          end

          context 'with invalid data' do
            it 'responds to valid?' do
              expect(subject).to respond_to(:valid?)
            end
          end
        end
      RUBY
    end
  end

  context "when example descriptions differ across contexts" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        describe 'Service' do
          context 'with option A' do
            it 'processes A' do
              expect(result).to be_a
            end
          end

          context 'with option B' do
            it 'processes B' do
              expect(result).to be_b
            end
          end

          context 'with option C' do
            it 'processes C' do
              expect(result).to be_c
            end
          end
        end
      RUBY
    end
  end
end
