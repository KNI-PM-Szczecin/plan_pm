require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'
require 'fastlane'
require 'fastlane/fast_file'
Fastlane.load_actions

# Exercise real lane switching, but replace network/download and gh commands.
class GithubLaneTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir('planpm-fastlane-test-')
    @android = File.join(@dir, 'frontend/android')
    FileUtils.mkdir_p(File.join(@android, 'fastlane'))
    %w[Fastfile apk_validator.rb].each do |name|
      FileUtils.cp(File.join(__dir__, name), File.join(@android, 'fastlane', name))
    end
    File.write(File.join(@dir, 'frontend/pubspec.yaml'), "version: 1.3.2+29\n")
    File.write(File.join(@dir, 'frontend/CHANGELOG.md'), "## 1.3.2\n\n### pl-PL\nNaprawa APK.\n")
    @commands = []
    @protected = false
    @existing_tags = "v1.3.2\n"
    test = self
    Dir.chdir(@android) do
      @fastfile = Fastlane::FastFile.new(File.join(@android, 'fastlane/Fastfile'))
    end
    @fastfile.define_singleton_method(:download_play_apk) do |name, _code|
      unless test.instance_variable_get(:@protected)
        path = File.expand_path("../../build/app/outputs/universal-apk/plan_pm-#{name}.apk")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, 'verified APK fixture')
      end
    end
    @fastfile.define_singleton_method(:upload_to_play_store) { |*| raise 'GitHub lane must never upload to Play' }
    @fastfile.define_singleton_method(:sh) do |*args, **_options|
      test.instance_variable_get(:@commands) << args
      case args[0..1]
      when %w[gh api]
        result = test.instance_variable_get(:@existing_tags)
        FastlaneCore::UI.shell_error!('GitHub API unavailable') if result.nil?
        result
      when %w[git rev-parse] then 'fixture-commit'
      when %w[gh release]
        if args[2] == 'create'
          notes = args[args.index('--notes-file') + 1]
          raise 'Release notes missing' unless File.read(notes).include?('Naprawa APK.')
        end
        ''
      else raise "Unexpected build/upload command: #{args.inspect}"
      end
    end
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def run_lane
    Dir.chdir(@android) { @fastfile.runner.execute(:github, :android, {}) }
  end

  def test_existing_release_only_replaces_the_asset
    run_lane
    assert @commands.any? { |args| args[0..2] == %w[gh release upload] }
    refute @commands.any? { |args| args[0..2] == %w[gh release create] }
  end

  def test_new_release_uses_changelog_and_commit
    @existing_tags = ''
    run_lane
    assert @commands.any? { |args| args[0..2] == %w[gh release create] }
  end

  def test_rejected_apk_never_reaches_github
    @protected = true
    assert_raises(FastlaneCore::Interface::FastlaneError) { run_lane }
    assert_empty @commands
  end

  def test_github_api_failure_does_not_create_a_release
    @existing_tags = nil
    assert_raises(FastlaneCore::Interface::FastlaneShellError) { run_lane }
    refute @commands.any? { |args| args[0..1] == %w[gh release] }
  end
end
