# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

LAYOUT_LML = <<~LML
  models M {
    class Outer {
      attribute inner, Inner { cardinality 1 }
      attribute inners, Inner { cardinality 0..n }
    }
    class Inner {
      attribute x, String
    }
  }
  instance Outer {
    inner = instance Inner { x = "one" }
    inners = [instance Inner { x = "a" }]
  }
LML

def compile_and_hydrate(lml)
  source = StringIO.new(lml)
  compiler = Lutaml::Lml::ModelCompiler.new
  compiler.compile(source)
  source.rewind
  compiler.hydrate(source)
end

RSpec.describe 'instance hydration semantics (issue #17)' do
  it 'hydrates nested instances under collection attributes as arrays' do
    hydrated = compile_and_hydrate(LAYOUT_LML)
    expect(hydrated.inners).to be_an(Array)
    expect(hydrated.inners.first.x).to eq('a')
  end

  # Scalar-nested hydration (single nested instance under a scalar
  # attribute = the object, not a one-element array) needs the compiler
  # to surface cardinality on the compiled attribute — tracked on
  # issue #17 with the map/scale work.
  xit 'hydrates a scalar attribute with one nested instance as the object' do
    hydrated = compile_and_hydrate(LAYOUT_LML)
    expect(hydrated.inner).to be_a(Lutaml::Lml::Inner)
    expect(hydrated.inner.x).to eq('one')
    expect(hydrated.inners).to be_an(Array)
  end

  it 'materializes inline maps as a Hash at the parse level (not corrupt text)' do
    doc = Lutaml::Lml.parse_document(StringIO.new(<<~LML))
      instance Cfg {
        settings = { a = "1"; b = "2" }
      }
    LML
    attr = doc.instance.attributes.first
    cargo = attr.value.respond_to?(:value) ? attr.value.value : attr.value
    expect(cargo).to eq(a: '1', b: '2')
  end

  it 'accumulates repeated instances blocks' do
    doc = Lutaml::Lml.parse_document(StringIO.new(<<~LML))
      instances {
        collection "A" {
          validation { condition "count >= 0" }
        }
      }
      instances {
        collection "B" {
          validation { condition "count >= 0" }
        }
      }
    LML
    expect(doc.instances.collections.map(&:name)).to eq(%w[A B])
  end

  it 'errors on duplicate collection names across instances blocks' do
    duplicate = "instances { collection \"A\" { } }\ninstances { collection \"A\" { } }\n"
    expect { Lutaml::Lml.parse_document(StringIO.new(duplicate)) }
      .to raise_error(Lutaml::Lml::Error, /duplicate collection name 'A'/)
  end
end
