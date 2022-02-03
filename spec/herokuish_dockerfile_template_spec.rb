# frozen_string_literal: true

describe 'Dockerfile.erb' do # rubocop:disable RSpec/DescribeClass
  subject(:rendered_dockerfile) do
    path = File.expand_path('../src/Dockerfile.erb', File.dirname(__FILE__))
    template = File.open(path, &:read)
    ERB.new(template, trim_mode: '-').result
  end

  context 'when AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES is non-empty' do
    before do
      stub_const('ENV', 'AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES' =>
        'non-empty')
    end

    it 'enables experimental docker syntax' do
      expect(rendered_dockerfile.lines.first).to eq(
        "# syntax = docker/dockerfile:experimental\n"
      )
    end

    it 'mounts a secret' do
      expect(rendered_dockerfile).to match(
        %r{^RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && /bin/herokuish buildpack build$} # rubocop:disable Metrics/LineLength
      )
    end
  end

  context 'when AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES is not given' do
    before do
      stub_const('ENV', {})
    end

    it 'does a herokuish build' do
      expect(rendered_dockerfile).to match(
        %r{^RUN /bin/herokuish buildpack build$}
      )
    end

    it 'does not use experimental syntax' do
      expect(rendered_dockerfile).not_to match(
        %r{# syntax = docker/dockerfile:experimental}
      )
    end

    it 'does not mount secrets' do
      expect(rendered_dockerfile).not_to match(/--mount=type=secret/)
    end
  end
end
