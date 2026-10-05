# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'LML declarations (isa, defaults, derive, payloads, string_format)' do
  def compile_lml(source)
    file = Tempfile.new(%w[test .lml])
    file.write(source)
    file.rewind
    Lutaml::Lml::ModelCompiler.new.tap { |c| c.compile(file) }
  ensure
    file.close!
  end

  def write_grammar_artifact
    source = <<~PARG
      grammar CodeFmt version "1" {
        code = ( 1*%x30-39 ) as code
        entry code: code
        bindings code {
          code -> code (string)
        }
        test { accept "42" }
      }
    PARG
    document = Parsanol::PARG::Parser.new(source).parse
    envelope = Parsanol::PARG::Compiler.compile(document).envelope
    file = Tempfile.new(%w[code .artifact.json])
    file.write(JSON.generate(envelope.respond_to?(:to_h) ? envelope.to_h : envelope))
    file.flush
    file.path
  end

  describe 'isa instance-type override (L6)' do
    it 'routes hydration through isa and keeps type as data' do
      compiler = compile_lml(<<~LML)
        models M {
          class Item {
            attribute type { type String cardinality 0..1 }
            attribute size { type String cardinality 1 }
          }
        }
      LML
      data = Tempfile.new(%w[d .lml])
      data.write("instance Item {\n  isa Item\n  type = \"standard\"\n  size = \"L\"\n}\n")
      data.rewind
      item = compiler.hydrate(data)
      expect(item).to be_a(compiler.compiled_classes['Item'])
      expect(item.type).to eq('standard')
      expect(item.size).to eq('L')
    ensure
      data.close!
    end
  end

  describe 'attribute defaults and render_nil (L7b)' do
    it 'compiles declared default literals and render_nil' do
      compiler = compile_lml(<<~LML)
        models M {
          class C {
            attribute originator { type String cardinality 0..1 default "iso" }
            attribute remark { type String cardinality 0..1 render_nil true }
          }
        }
      LML
      options = compiler.compiled_classes['C'].attributes[:originator].options
      expect(options[:default]).to eq('iso')
      remark_rule = compiler.compiled_classes['C'].mappings_for(:yaml)
                            .mappings.find { |rule| rule.name == 'remark' }
      expect(remark_rule.render_nil).to be(true)
    end
  end

  describe 'derive declarations (L7b)' do
    it 'declares the attribute and records the derivation' do
      compiler = compile_lml(<<~LML)
        models M {
          class Doc {
            attribute urn { type String cardinality 0..1 }
            derive tiny: String
          }
        }
      LML
      klass = compiler.compiled_classes['Doc']
      expect(klass.attributes).to have_key(:tiny)
      expect(klass.derived_fields).to eq([:tiny])
    end
  end

  describe 'enum member payloads (L7a)' do
    it 'carries typed payloads on members' do
      compiler = compile_lml(<<~LML)
        models M {
          enum Stage {
            member_fields { abbreviation String  urn_segment String }
            draft10 { abbreviation = "WD"  urn_segment = "wd" }
            published { abbreviation = "IS"  urn_segment = "published" }
          }
        }
      LML
      stage = compiler.compiled_classes['Stage']
      expect(stage.draft10.abbreviation).to eq('WD')
      expect(stage.published.urn_segment).to eq('published')
    end

    it 'rejects undeclared payload fields' do
      expect do
        compile_lml(<<~LML)
          models M {
            enum Stage {
              member_fields { abbreviation String }
              draft10 { abbreviation = "WD"  oops = "x" }
            }
          }
        LML
      end.to raise_error(ArgumentError, /undeclared payload fields/)
    end
  end

  describe 'string_format declarations (L5)' do
    let(:artifact_path) { write_grammar_artifact }

    it 'registers a grammar-backed format on the class' do
      compiler = Lutaml::Lml::ModelCompiler.new(
        artifact_paths: { 'code_fmt' => artifact_path }
      )
      source = Tempfile.new(%w[test .lml])
      source.write(<<~LML)
        models M {
          class Widget {
            attribute code { type String cardinality 1 }
            string_format code_id {
              artifact "code_fmt"
              root "code"
            }
          }
        }
      LML
      source.rewind
      compiler.compile(source)
      widget = compiler.compiled_classes['Widget']
      expect(widget).to respond_to(:from_code_id)
      expect(widget.from_code_id('42').code).to eq('42')
    ensure
      source.close!
    end
  end

  describe 'enum from_table (L7a, artifact-table reference)' do
    it 'bakes artifact table rows as members at compile time' do
      artifact_path = write_grammar_artifact
      envelope = JSON.parse(File.read(artifact_path))
      envelope['tables'] = {
        'stages' => {
          'file' => 'stages.yaml',
          'rows' => [
            { 'name' => 'draft10', 'abbreviation' => 'WD', 'urn_segment' => 'wd' },
            { 'name' => 'published', 'abbreviation' => 'IS', 'urn_segment' => 'published' },
            { 'name' => 'withdrawn', 'abbreviation' => nil }
          ]
        }
      }
      File.write(artifact_path, JSON.generate(envelope))

      compiler = Lutaml::Lml::ModelCompiler.new(
        artifact_paths: { 'code_fmt' => artifact_path }
      )
      source = Tempfile.new(%w[test .lml])
      source.write(<<~LML)
        models M {
          enum Stage {
            member_fields { abbreviation String  urn_segment String }
            from_table "stages" {
              artifact "code_fmt"
            }
          }
        }
      LML
      source.rewind
      compiler.compile(source)

      stage = compiler.compiled_classes['Stage']
      expect(stage.draft10.abbreviation).to eq('WD')
      expect(stage.published.urn_segment).to eq('published')
      expect(stage.withdrawn.abbreviation).to be_nil
      expect(stage.values.map(&:name)).to eq(%w[draft10 published withdrawn])
    ensure
      source.close!
    end

    it 'rejects unknown table fields' do
      artifact_path = write_grammar_artifact
      envelope = JSON.parse(File.read(artifact_path))
      envelope['tables'] = {
        'stages' => { 'file' => 'stages.yaml', 'rows' => [{ 'name' => 'draft10', 'oops' => 'x' }] }
      }
      File.write(artifact_path, JSON.generate(envelope))

      compiler = Lutaml::Lml::ModelCompiler.new(
        artifact_paths: { 'code_fmt' => artifact_path }
      )
      source = Tempfile.new(%w[test .lml])
      source.write(<<~LML)
        models M {
          enum Stage {
            member_fields { abbreviation String }
            from_table "stages" {
              artifact "code_fmt"
            }
          }
        }
      LML
      source.rewind
      expect { compiler.compile(source) }.to raise_error(ArgumentError, /undeclared fields/)
    ensure
      source.close!
    end
  end
end
