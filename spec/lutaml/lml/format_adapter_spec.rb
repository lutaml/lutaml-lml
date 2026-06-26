# frozen_string_literal: true

require "spec_helper"
require "lutaml/lml/format"

RSpec.describe "LML format adapter" do
  before(:all) do
    unless Lutaml::Model::FormatRegistry.registered?(:lml)
      require "lutaml/lml/format"
    end
  end

  let(:model_class) do
    Class.new(Lutaml::Model::Serializable) do
      attribute :name, :string
      attribute :age, :integer
      attribute :active, :boolean, default: false

      lml do
        map :name, to: :name
        map :age, to: :age
        map :active, to: :active
      end
    end
  end

  describe "from_lml" do
    it "parses LML instance syntax into model objects" do
      lml = "instance Data {\n  name = \"Alice\"\n  age = 25\n  active = true\n}"
      obj = model_class.from_lml(lml)
      expect(obj.name).to eq("Alice")
      expect(obj.age).to eq(25)
      expect(obj.active).to eq(true)
    end

    it "handles string values without quotes" do
      lml = "instance Data {\n  name = SimpleWord\n  age = 1\n  active = false\n}"
      obj = model_class.from_lml(lml)
      expect(obj.name).to eq("SimpleWord")
    end
  end

  describe "to_lml" do
    it "serializes model objects to LML instance syntax" do
      obj = model_class.new(name: "Bob", age: 30, active: true)
      lml = obj.to_lml
      expect(lml).to include("name = Bob")
      expect(lml).to include("age = 30")
      expect(lml).to include("active = true")
      expect(lml).to start_with("instance ")
    end

    it "quotes strings with special characters" do
      obj = model_class.new(name: "Hello World", age: 1, active: false)
      lml = obj.to_lml
      expect(lml).to include('name = "Hello World"')
    end
  end

  describe "round-trip" do
    it "round-trips through from_lml/to_lml" do
      original = model_class.new(name: "Carol", age: 42, active: false)
      lml = original.to_lml
      restored = model_class.from_lml(lml)
      expect(restored.name).to eq(original.name)
      expect(restored.age).to eq(original.age)
      expect(restored.active).to eq(original.active)
    end

    it "round-trips floats and booleans" do
      sensor_class = Class.new(Lutaml::Model::Serializable) do
        attribute :sensor_id, :string
        attribute :reading, :float
        attribute :active, :boolean, default: true

        lml do
          map :sensor_id, to: :sensor_id
          map :reading, to: :reading
          map :active, to: :active
        end
      end

      original = sensor_class.new(sensor_id: "TH-042", reading: 21.7, active: false)
      restored = sensor_class.from_lml(original.to_lml)
      expect(restored.sensor_id).to eq("TH-042")
      expect(restored.reading).to eq(21.7)
      expect(restored.active).to eq(false)
    end
  end

  describe "nested round-trip" do
    it "preserves __type__ in nested instance output" do
      data = {
        "name" => "Outer",
        "__type__" => "OuterType",
        "inner" => {
          "__type__" => "InnerType",
          "value" => "hello"
        }
      }
      adapter = Lutaml::Lml::Format::Adapter::StandardAdapter.new(data)
      lml = adapter.to_lml
      expect(lml).to include("instance OuterType {")
      expect(lml).to include("instance InnerType {")
      expect(lml).to include("value = hello")
    end

    it "preserves __type__ in array of nested instances" do
      data = {
        "__type__" => "Container",
        "items" => [
          { "__type__" => "Item", "name" => "first" },
          { "__type__" => "Item", "name" => "second" }
        ]
      }
      adapter = Lutaml::Lml::Format::Adapter::StandardAdapter.new(data)
      lml = adapter.to_lml
      expect(lml).to include("instance Container {")
      expect(lml).to include("instance Item {")
      expect(lml).to include("name = first")
      expect(lml).to include("name = second")
    end

    it "handles nested instances without __type__" do
      data = {
        "name" => "Top",
        "nested" => { "key" => "value" }
      }
      adapter = Lutaml::Lml::Format::Adapter::StandardAdapter.new(data)
      lml = adapter.to_lml
      expect(lml).to include("name = Top")
      expect(lml).to include("nested = instance {")
      expect(lml).to include("key = value")
    end

    it "round-trips typed nested single instance through from_lml/to_lml" do
      address_cls = Class.new(Lutaml::Model::Serializable) do
        attribute :street, :string
        attribute :city, :string
        lml do
          map :street, to: :street
          map :city, to: :city
        end
      end
      person_cls = Class.new(Lutaml::Model::Serializable) do
        attribute :name, :string
        attribute :address, address_cls
        lml do
          map :name, to: :name
          map :address, to: :address
        end
      end

      original = person_cls.new(
        name: "Alice",
        address: address_cls.new(street: "Main", city: "NYC")
      )
      restored = person_cls.from_lml(original.to_lml)
      expect(restored.name).to eq("Alice")
      expect(restored.address).to be_a(address_cls)
      expect(restored.address.street).to eq("Main")
      expect(restored.address.city).to eq("NYC")
    end

    it "round-trips typed nested collection through from_lml/to_lml" do
      item_cls = Class.new(Lutaml::Model::Serializable) do
        attribute :sku, :string
        attribute :qty, :integer
        lml do
          map :sku, to: :sku
          map :qty, to: :qty
        end
      end
      order_cls = Class.new(Lutaml::Model::Serializable) do
        attribute :id, :string
        attribute :items, item_cls, collection: true
        lml do
          map :id, to: :id
          map :items, to: :items
        end
      end

      original = order_cls.new(
        id: "ORD-1",
        items: [
          item_cls.new(sku: "A1", qty: 3),
          item_cls.new(sku: "B2", qty: 1)
        ]
      )
      restored = order_cls.from_lml(original.to_lml)
      expect(restored.id).to eq("ORD-1")
      expect(restored.items.size).to eq(2)
      expect(restored.items.first).to be_a(item_cls)
      expect(restored.items.first.sku).to eq("A1")
      expect(restored.items.last.qty).to eq(1)
    end
  end

  describe "format registration" do
    it "registers :lml in FormatRegistry" do
      expect(Lutaml::Model::FormatRegistry.registered?(:lml)).to be true
    end

    it "provides from_lml class method" do
      expect(model_class).to respond_to(:from_lml)
    end

    it "provides to_lml instance method" do
      expect(model_class.new).to respond_to(:to_lml)
    end
  end
end
