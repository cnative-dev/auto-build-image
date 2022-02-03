# frozen_string_literal: true

# require_relative doesn't work if the file has no .rb extension
load File.expand_path('../src/export-build-secrets', File.dirname(__FILE__))

describe BuildSecrets do
  let(:build_secrets) { described_class.new(env) }

  let(:env) do
    {
      'USER' => 'hordur',
      'PATH' => '/usr/bin',
      'MULTILINE' => <<~MULTILINE.strip,
        this is a string with 'various "quotes"
        spanning
        multiple lines\twith tabs and spaces and $ # everything
      MULTILINE
      'IGNORED' => 'this env variable is not forwarded',
      'AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES' => ci_variable_value
    }
  end

  let(:ci_variable_value) { 'USER,PATH,MULTILINE' }

  describe '#variable_names' do
    subject(:variable_names) { build_secrets.variable_names }

    it { is_expected.to eq(%w[USER PATH MULTILINE]) }

    context 'when some names are invalid' do
      let(:ci_variable_value) { 'PATH,"inva,lid",USER,$IGNORED' }

      it 'only returns the valid ones' do
        expect(variable_names).to eq(%w[PATH USER])
      end
    end
  end

  describe '#export_string' do
    subject(:export_string) { build_secrets.export_string }

    it 'returns a shell script exporting each variable' do
      expect(export_string).to eq(<<~EXPECTED.strip)
        export USER=hordur
        export PATH=/usr/bin
        export MULTILINE=this\\ is\\ a\\ string\\ with\\ \\'various\\ \\"quotes\\"'
        'spanning'
        'multiple\\ lines\\	with\\ tabs\\ and\\ spaces\\ and\\ \\$\\ \\#\\ everything
      EXPECTED
    end

    context 'when variable is not present' do
      let(:env) { { 'A' => 'B', 'C' => 'D' } }

      it 'returns the empty string' do
        expect(export_string).to eq('')
      end
    end
  end

  describe '.run' do
    it 'prints #export_string with a trailing newline' do
      stub_const('ENV', env)
      expect { described_class.run }
        .to(output("#{build_secrets.export_string}\n").to_stdout)
    end
  end
end
