# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FactoryBotGuide::DynamicAttributesForTimeAndRandom, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when using time-based methods without block" do
    context "with Time.now" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :user do
            created_at Time.now
            ^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `created_at` because `Time.now` is evaluated once at factory definition time. Wrap in block: `created_at { Time.now }`
          end
        RUBY
      end
    end

    context "with Date.today" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :event do
            event_date Date.today
            ^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `event_date` because `Date.today` is evaluated once at factory definition time. Wrap in block: `event_date { Date.today }`
          end
        RUBY
      end
    end

    context "with DateTime.now" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :post do
            published_at DateTime.now
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `published_at` because `DateTime.now` is evaluated once at factory definition time. Wrap in block: `published_at { DateTime.now }`
          end
        RUBY
      end
    end

    context "with time modifiers like 1.day.from_now" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :order do
            expires_at 1.day.from_now
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `expires_at` because `1.day.from_now` is evaluated once at factory definition time. Wrap in block: `expires_at { 1.day.from_now }`
          end
        RUBY
      end
    end
  end

  context "when using random-based methods without block" do
    context "with SecureRandom.hex" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :user do
            token SecureRandom.hex
            ^^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `token` because `SecureRandom.hex` is evaluated once at factory definition time. Wrap in block: `token { SecureRandom.hex }`
          end
        RUBY
      end
    end

    context "with SecureRandom.uuid" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          factory :user do
            uuid SecureRandom.uuid
            ^^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `uuid` because `SecureRandom.uuid` is evaluated once at factory definition time. Wrap in block: `uuid { SecureRandom.uuid }`
          end
        RUBY
      end
    end
  end

  context "when using method calls like Array.new without block" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        factory :user do
          tags Array.new
          ^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `tags` because `Array.new` is evaluated once at factory definition time. Wrap in block: `tags { Array.new }`
        end
      RUBY
    end
  end

  context "when using block syntax" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        factory :user do
          created_at { Time.now }
          token { SecureRandom.hex }
          expires_at { 1.day.from_now }
        end
      RUBY
    end
  end

  context "when using static values" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        factory :user do
          name "John"
          age 25
          active true
          balance 100.50
        end
      RUBY
    end
  end

  context "when using symbols" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        factory :user do
          status :active
          role :admin
        end
      RUBY
    end
  end

  context "with FactoryBot prefix" do
    it "registers an offense for dynamic attributes" do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
            created_at Time.now
            ^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `created_at` because `Time.now` is evaluated once at factory definition time. Wrap in block: `created_at { Time.now }`
          end
        end
      RUBY
    end
  end

  context "with multiple violations in one factory" do
    it "registers multiple offenses" do
      expect_offense(<<~RUBY)
        factory :user do
          created_at Time.now
          ^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `created_at` because `Time.now` is evaluated once at factory definition time. Wrap in block: `created_at { Time.now }`
          token SecureRandom.hex
          ^^^^^^^^^^^^^^^^^^^^^^ FactoryBotGuide/DynamicAttributesForTimeAndRandom: Use block syntax for attribute `token` because `SecureRandom.hex` is evaluated once at factory definition time. Wrap in block: `token { SecureRandom.hex }`
          name "John"
        end
      RUBY
    end
  end
end
