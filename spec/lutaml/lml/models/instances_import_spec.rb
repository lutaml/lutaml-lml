# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Lml::InstancesImport do
  it "has format_type and file attributes" do
    imp = described_class.new(format_type: "xml", file: "data/products.xml")
    expect(imp.format_type).to eq("xml")
    expect(imp.file).to eq("data/products.xml")
  end

  it "holds attributes as TopElementAttribute collection" do
    attr = Lutaml::Lml::TopElementAttribute.new(name: "map_to", value: "Product")
    imp = described_class.new(format_type: "csv", attributes: attr)
    expect(imp.attributes).to eq(attr)
  end
end
