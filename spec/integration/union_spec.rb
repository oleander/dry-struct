# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock
RSpec.describe Dry::Struct::Union do
  describe Fixtures do
    let(:remove) { "" }
    let(:cold) { {id: :cold, temp: 100} }
    let(:warm) { {id: :warm, temp: 100} }
    let(:spring) { {id: :spring} }

    describe described_class::Weather do
      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Fixtures::Weather<[#{remove}Fixtures::Weather::Warm]>") }
      end

      describe ".call" do
        describe "Warm" do
          subject { described_class.call(warm) }
          it { is_expected.to be_a(described_class::Warm) }
        end

        describe "Cold" do
          it "throws an error" do
            expect do
              described_class.call(cold)
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end

    describe described_class::Planet do
      let(:earth) { {id: :earth, weather: warm, season: spring} }
      let(:mars) { {id: :mars, closest: earth, weather: warm} }

      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Fixtures::Planet<[#{remove}Fixtures::Planet::Earth | #{remove}Fixtures::Planet::Mars]>") }
      end

      describe ".call" do
        describe "Mars" do
          subject { described_class.call(mars) }
          it { is_expected.to be_a(described_class::Mars) }
          it { is_expected.to have_attributes(to_h: mars) }
        end

        describe "Earth" do
          subject { described_class.call(earth) }
          it { is_expected.to be_a(described_class::Earth) }
          it { is_expected.to have_attributes(to_h: earth) }
        end

        describe "Pluto" do
          it "throws an error" do
            expect do
              described_class.call({id: :pluto})
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end

    describe described_class::Season do
      describe ".name" do
        it { is_expected.to have_attributes(name: "#{remove}Fixtures::Season<[#{remove}Fixtures::Season::Spring]>") }
      end

      describe ".call" do
        describe "Spring" do
          subject { described_class.call(spring) }
          it { is_expected.to be_a(described_class::Spring) }
        end

        describe "Autum" do
          it "throws an error" do
            expect do
              described_class.call({id: :autum})
            end.to raise_error(Dry::Struct::Error)
          end
        end
      end
    end
  end

  describe "edge cases" do
    subject { self.class::Type }

    describe ".call" do
      context "given an empty type union" do
        subject do
          Module.new do
            include Dry::Struct::Union
          end
        end

        it { is_expected.to have_attributes(__types__: []) }
      end

      context "given a type module with nothing excluded" do
        module self::Type
          include Dry::Struct::Union

          class A < Dry::Struct
            # NOP
          end
        end

        subject { self.class::Type }
        it { is_expected.to have_attributes(__types__: [self.class::Type::A]) }
      end
    end
  end

  fdescribe ".call" do
    context "given a union module containing a struct" do
      subject(:struct) do
        Module.new do
          include Dry::Struct::Union
        end
      end

      before do
        struct.const_set(:A, Class.new(Dry::Struct))
      end

      it { is_expected.to have_attributes(__types__: [struct::A]) }

      context "when a struct is added" do
        before do
          struct.const_set(:B, Class.new(Dry::Struct))
        end

        it { is_expected.to have_attributes(__types__: [struct::A, struct::B]) }

        context "when a struct is deleted" do
          before do
            struct.send(:remove_const, :A)
          end

          it { is_expected.to have_attributes(__types__: [struct::B]) }
        end
      end
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock
