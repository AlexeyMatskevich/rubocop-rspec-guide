# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpecGuide::DuplicateBeforeHooks, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it "registers an offense for duplicate before hooks in all siblings" do
    expect_offense(<<~RUBY)
      describe 'Controller' do
        context 'as admin' do
          before { sign_in(user) }
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          it { expect(response).to be_successful }
        end

        context 'as guest' do
          before { sign_in(user) }
          ^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          it { expect(response).to be_forbidden }
        end
      end
    RUBY
  end

  it "does not register an offense when before hooks differ" do
    expect_no_offenses(<<~RUBY)
      describe 'Controller' do
        context 'as admin' do
          before { sign_in(admin) }
        end

        context 'as guest' do
          before { sign_in(guest) }
        end
      end
    RUBY
  end

  it "registers a warning when before is duplicated in some but not all contexts" do
    expect_offense(<<~RUBY)
      describe 'Controller' do
        context 'A' do
          before { setup }
          ^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Before hook duplicated in 2/3 sibling contexts. Consider refactoring test hierarchy - this suggests poor organization.
        end

        context 'B' do
          # No before here
        end

        context 'C' do
          before { setup }
          ^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Before hook duplicated in 2/3 sibling contexts. Consider refactoring test hierarchy - this suggests poor organization.
        end
      end
    RUBY
  end

  context "when WarnOnPartialDuplicates is disabled" do
    let(:config) do
      rubocop_config_with_rspec_language(
        "RSpecGuide/DuplicateBeforeHooks" => {
          "WarnOnPartialDuplicates" => false
        }
      )
    end

    it "does not register warnings for partial duplicates" do
      expect_no_offenses(<<~RUBY)
        describe 'Controller' do
          context 'A' do
            before { setup }
          end

          context 'B' do
            # No before here
          end

          context 'C' do
            before { setup }
          end
        end
      RUBY
    end

    it "still registers errors when duplicated in all contexts" do
      expect_offense(<<~RUBY)
        describe 'Controller' do
          context 'A' do
            before { setup }
            ^^^^^^^^^^^^^^^^ Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          end

          context 'B' do
            before { setup }
            ^^^^^^^^^^^^^^^^ Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          end
        end
      RUBY
    end
  end

  it "registers an offense for multiline before hooks" do
    expect_offense(<<~RUBY)
      describe 'Service' do
        context 'scenario A' do
          before do
          ^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
            user.activate!
            user.reload
          end
        end

        context 'scenario B' do
          before do
          ^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
            user.activate!
            user.reload
          end
        end
      end
    RUBY
  end

  it "handles 3 or more sibling contexts" do
    expect_offense(<<~RUBY)
      describe 'API' do
        context 'GET' do
          before { authenticate }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
        end

        context 'POST' do
          before { authenticate }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
        end

        context 'DELETE' do
          before { authenticate }
          ^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "normalizes whitespace when comparing" do
    expect_offense(<<~RUBY)
      describe 'Service' do
        context 'A' do
          before { user.activate! }
          ^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
        end

        context 'B' do
          before {  user.activate!  }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
        end
      end
    RUBY
  end

  it "does not check nested contexts as siblings" do
    expect_no_offenses(<<~RUBY)
      describe 'Service' do
        context 'A' do
          before { setup }

          context 'nested' do
            before { setup }
          end
        end

        context 'B' do
          before { cleanup }
        end
      end
    RUBY
  end

  it "handles multiple different before hooks correctly" do
    expect_offense(<<~RUBY)
      describe 'Service' do
        context 'A' do
          before { setup }
          ^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          before { authenticate }
        end

        context 'B' do
          before { setup }
          ^^^^^^^^^^^^^^^^ RSpecGuide/DuplicateBeforeHooks: Duplicate `before` hook in ALL sibling contexts. Extract to parent context.
          before { authorize }
        end
      end
    RUBY
  end

  it "does not register offense when only some before hooks are duplicated" do
    expect_no_offenses(<<~RUBY)
      describe 'Service' do
        context 'A' do
          before { setup }
          before { authenticate }
        end

        context 'B' do
          before { cleanup }
          before { authorize }
        end
      end
    RUBY
  end
end
