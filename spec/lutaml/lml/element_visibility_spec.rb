# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Element visibility modifier' do
  def parse(src)
    Lutaml::Lml.parse_document(StringIO.new(src))
  end

  it 'defaults to public' do
    doc = parse("class Foo { }\n")
    expect(doc.classes.first.visibility).to eq('public')
  end

  %w[public private protected package].each do |level|
    it "parses #{level} on a class" do
      doc = parse("#{level} class Foo { }\n")
      expect(doc.classes.first.visibility).to eq(level)
    end
  end

  it 'parses visibility on enums, data types and package contents' do
    doc = parse(<<~LML)
      private enum Finish { matte }
      protected data_type MyString { }
      package Pkg {
        private class Hidden { }
        public enum Open { a }
      }
    LML
    expect(doc.enums.first.visibility).to eq('private')
    expect(doc.data_types.first.visibility).to eq('protected')
    expect(doc.packages.first.classes.first.visibility).to eq('private')
    expect(doc.packages.first.enums.first.visibility).to eq('public')
  end

  it 'combines with the abstract/interface modifier' do
    doc = parse("private abstract class Base { }\n")
    expect(doc.classes.first.visibility).to eq('private')
    expect(doc.classes.first.modifier).to eq('abstract')
  end

  it 'binds `package class` as a package-visible class, not a package named class' do
    doc = parse("package class Foo { }\n")
    expect(doc.packages).to be_empty
    expect(doc.classes.first.name).to eq('Foo')
    expect(doc.classes.first.visibility).to eq('package')
  end
end
