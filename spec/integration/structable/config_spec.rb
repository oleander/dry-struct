# frozen_string_literal: true

require "dry/struct/structable/config"
require "rspec/its"

RSpec.describe Dry::Struct::Structable::Config do
  describe "without config" do
    subject { described_class.new(scope: scope, config: {}) }

    context "given a module" do
      let(:scope) { Module.new }

      context "given no classes" do
        its(:types) { is_expected.to be_empty }
      end

      context "given a struct" do
        let(:klass) { Class.new(Dry::Struct) }

        before do
          scope.const_set("Struct", klass)
        end

        its(:types) { is_expected.to match_array([klass]) }
      end

      context "given a regular class" do
        let(:regular) { Class.new }

        before do
          scope.const_set("RegularClass", regular)
        end

        its(:types) { is_expected.to be_empty }
      end

      context "given a regular constant" do
        let(:constant) { :frozen }

        before do
          scope.const_set("CONST", constant)
        end

        its(:types) { is_expected.to be_empty }
      end

      context "given a regular module" do
        let(:regular) { Module.new }

        before do
          scope.const_set("RegularModule", regular)
        end

        its(:types) { is_expected.to be_empty }

        context "given a struct" do
          let(:struct) { Class.new(Dry::Struct) }

          before do
            regular.const_set("Struct", struct)
          end

          its(:types) { is_expected.to be_empty }
        end
      end

      context "given an abstract class" do
        let(:abstract) do
          Class.new(Dry::Struct) do
            abstract
          end
        end

        before do
          scope.const_set("Abstract", abstract)
        end

        its(:types) { is_expected.to be_empty }

        context "given a sub class of abstract class" do
          let(:struct) do
            Class.new(abstract)
          end

          before do
            scope.const_set("Struct", struct)
          end

          its(:types) { is_expected.to match_array([struct]) }
        end

        context "given a sum module" do
          let(:structable) do
            Module.new do
              include Dry::Struct::Structable
            end
          end

          before do
            scope.const_set("SumModule", structable)
          end

          its(:types) { is_expected.to match_array([structable]) }

          context "given a struct" do
            let(:inner_struct) { Class.new(abstract) }

            before do
              structable.const_set("InnerStruct", inner_struct)
            end

            its(:types) { is_expected.to match_array([structable]) }
          end
        end
      end
    end
  end

  describe "with config" do
    context "given [only: A]" do
      subject { described_class.new(scope: scope, config: {only: "A"}) }

      let(:scope) do
        Module.new {}
      end

      context "given struct A" do
        let(:klass_a) { Class.new(Dry::Struct) }

        before do
          scope.const_set("A", klass_a)
        end

        its(:types) { is_expected.to match_array([klass_a]) }

        context "given struct B" do
          let(:klass_b) { Class.new(Dry::Struct) }

          before do
            scope.const_set("B", klass_b)
          end

          its(:types) { is_expected.to match_array([klass_a]) }
        end
      end
    end

    context "given [except: A]" do
      subject { described_class.new(scope: scope, config: {except: "A"}) }

      let(:scope) do
        Module.new {}
      end

      context "given struct A" do
        let(:klass_a) { Class.new(Dry::Struct) }

        before do
          scope.const_set("A", klass_a)
        end

        its(:types) { is_expected.to be_empty }

        context "given struct B" do
          let(:klass_b) { Class.new(Dry::Struct) }

          before do
            scope.const_set("B", klass_b)
          end

          its(:types) { is_expected.to match_array([klass_b]) }
        end
      end
    end

    context "given [except: A, only: B]" do
      subject { described_class.new(scope: scope, config: {except: "A", only: "B"}) }

      let(:scope) do
        Module.new {}
      end

      context "given struct A" do
        let(:klass_a) { Class.new(Dry::Struct) }

        before do
          scope.const_set("A", klass_a)
        end

        # its(:types) { is_expected.to be_empty }

        context "given struct B" do
          let(:klass_b) { Class.new(Dry::Struct) }

          before do
            scope.const_set("B", klass_b)
          end

          its(:types) { is_expected.to match_array([klass_b]) }

          context "given struct C" do
            let(:klass_c) { Class.new(Dry::Struct) }

            before do
              scope.const_set("C", klass_c)
            end

            its(:types) { is_expected.to match_array([klass_b]) }
          end
        end
      end
    end
  end
end
