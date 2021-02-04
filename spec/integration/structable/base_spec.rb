# frozen_string_literal: true

require "dry/struct/structable"
require "dry/struct"
require "rspec/its"

module People
  # include Dry::Struct::Structable(only: ["Developer", "Engineer", "Farmer"])
  include Dry::Struct::Structable

  module Types
    include Dry::Types()
  end

  class Base < Dry::Struct
    abstract
  end

  class Developer < Base
    attribute :id, Types.Constant(:developer)
  end

  class Engineer < Base
    attribute :id, Types.Constant(:engineer)
  end

  module Farmer
    include Dry::Struct.Structable(only: %w[Carrot Potato])

    class Carrot < Base
      attribute :id, Types.Constant(:carrot)
    end

    class Potato < Base
      attribute :id, Types.Constant(:potato)
    end

    class Pig < Base
      attribute :id, Types.Constant(:pig)
    end
  end
end

RSpec.describe Dry::Struct::Structable do
  describe People do
    subject { People.call(input) }

    describe described_class::Developer do
      let(:input) { {id: :developer} }

      it { is_expected.to be_a(described_class) }
    end

    describe described_class::Farmer do
      describe described_class::Carrot do
        let(:input) { {id: :carrot} }

        it { is_expected.to be_a(described_class) }
      end

      describe described_class::Potato do
        let(:input) { {id: :potato} }

        it { is_expected.to be_a(described_class) }
      end

      describe described_class::Pig do
        let(:input) { {id: :pig} }

        it "raises an error" do
          expect { subject }.to raise_error(Dry::Struct::Error)
        end
      end
    end
  end
end

RSpec.describe Dry::Struct::Structable::Config do
  describe People do
    let(:developer) { described_class::Developer }
    let(:engineer) { described_class::Engineer }
    let(:farmer) { described_class::Farmer }
    let(:scope) { described_class }

    subject(:container) do
      Dry::Struct::Structable::Config.new(
        config: config,
        scope: scope
      )
    end

    context "given no restrictions" do
      let(:config) { {} }

      describe "#types" do
        subject { container.types }
        let(:types) { [developer, farmer, engineer] }

        it { is_expected.to match_array(types) }
      end

      describe described_class::Farmer do
        subject { container.types }
        let(:types) { [described_class::Carrot, described_class::Potato, described_class::Pig] }

        it { is_expected.to match_array(types) }
      end
    end

    describe "order" do
      describe "only" do
        context "given order [Developer, Farmer]" do
          let(:config) { {only: %w[Developer Farmer]} }

          describe "#types" do
            subject { container.types }
            let(:types) { [developer, farmer] }

            it { is_expected.to eq(types) }
          end
        end

        context "given order [Farmer, Developer]" do
          let(:config) { {only: %w[Farmer Developer]} }

          describe "#types" do
            subject { container.types }
            let(:types) { [farmer, developer] }

            it { is_expected.to eq(types) }
          end
        end

        context "given order []" do
          let(:config) { {only: []} }

          describe "#types" do
            subject { container.types }
            let(:types) { [] }

            it { is_expected.to eq(types) }
          end
        end
      end

      describe "only & exclude" do
        context "given order [Developer, Farmer]" do
          let(:config) { {only: %w[Developer Farmer], exclude: "Engineer"} }

          describe "#types" do
            subject { container.types }
            let(:types) { [developer, farmer] }

            it { is_expected.to eq(types) }
          end
        end
      end

      describe "empty config" do
        context "given classes ordered in file" do
          let(:config) { {} }

          describe "#types" do
            subject { container.types }
            let(:types) { [developer, engineer, farmer] }

            it { is_expected.to eq(types) }
          end
        end
      end
    end

    describe "only" do
      context "given only [Developer]" do
        let(:config) { {only: "Developer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [developer] }

          it { is_expected.to match_array(types) }
        end
      end

      context "given only [Farmer]" do
        let(:config) { {only: "Farmer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [farmer] }

          it { is_expected.to match_array(types) }
        end
      end
    end

    describe "except" do
      context "given all, except [Developer]" do
        let(:config) { {except: "Developer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [farmer, engineer] }

          it { is_expected.to match_array(types) }
        end
      end

      context "given all, except [Farmer]" do
        let(:config) { {except: "Farmer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [developer, engineer] }

          it { is_expected.to match_array(types) }
        end
      end
    end

    describe "except & only" do
      context "given only [Farmer], except [Developer] " do
        let(:config) { {except: "Developer", only: "Farmer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [farmer] }

          it { is_expected.to match_array(types) }
        end
      end

      context "given only [Developer], except [Farmer] " do
        let(:config) { {except: "Farmer", only: "Developer"} }

        describe "#types" do
          subject { container.types }
          let(:types) { [developer] }

          it { is_expected.to match_array(types) }
        end
      end
    end
  end
end
