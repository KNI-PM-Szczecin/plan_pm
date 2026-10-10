require 'open3'
require 'rubygems/version'

# A Play-signed universal APK can still contain Google's installer/licence
# check. Reject it before it becomes the public sideload download.
module PlanPmApkValidator
  class InvalidApk < StandardError; end

  def self.run(*command)
    output, error, status = Open3.capture3(*command)
    unless status.success?
      message = error.dup.force_encoding(Encoding::UTF_8).scrub.strip
      raise InvalidApk, "#{File.basename(command.first)} failed: #{message}"
    end

    output.b
  end

  def self.build_tools(sdk)
    paths = Dir.glob(File.join(sdk, 'build-tools', '*')).select do |path|
      File.executable?(File.join(path, 'aapt')) && File.executable?(File.join(path, 'apksigner'))
    end
    paths.max_by { |path| Gem::Version.new(File.basename(path)) } ||
      raise(InvalidApk, 'Android SDK build-tools with aapt and apksigner are required')
  end

  def self.validate!(apk, version_name:, version_code:, sdk: ENV['ANDROID_HOME'] || ENV['ANDROID_SDK_ROOT'])
    raise InvalidApk, 'ANDROID_HOME or ANDROID_SDK_ROOT must point to the Android SDK' if sdk.to_s.empty?

    tools = build_tools(sdk)
    run(File.join(tools, 'apksigner'), 'verify', apk)
    run('unzip', '-t', apk)
    badging = run(File.join(tools, 'aapt'), 'dump', 'badging', apk)
    manifest = run(File.join(tools, 'aapt'), 'dump', 'xmltree', apk, 'AndroidManifest.xml')
    check_metadata!(badging, manifest, version_name: version_name, version_code: version_code)

    dex_files = run('unzip', '-Z1', apk).lines.map(&:strip).grep(/\Aclasses\d*\.dex\z/)
    raise InvalidApk, 'APK has no Android application code' if dex_files.empty?

    dex_files.each do |name|
      if run('unzip', '-p', apk, name).include?('Lcom/pairip/licensecheck/')
        raise InvalidApk, 'APK contains Google Play licence checks; turn off installer protection for the Play release'
      end
    end
    true
  end

  def self.check_metadata!(badging, manifest, version_name:, version_code:)
    package = badging.lines.find { |line| line.start_with?('package:') }.to_s
    expected = { 'name' => 'com.piotrwittig.plan_pm', 'versionCode' => version_code.to_s, 'versionName' => version_name.to_s }
    expected.each do |key, value|
      actual = package[/\b#{key}='([^']*)'/, 1]
      raise InvalidApk, "Wrong APK #{key}: expected #{value}, got #{actual.inspect}" unless actual == value
    end
    if manifest.match?(/com\.pairip\.|com\.android\.vending\.CHECK_LICENSE/)
      raise InvalidApk, 'APK contains Google Play installer protection; turn it off for the Play release'
    end
    if package.match?(/\bsplit='/) || manifest.match?(/android:isSplitRequired[^\n]*0xffffffff/)
      raise InvalidApk, 'APK requires split APKs and cannot be distributed as a single installer'
    end
    abis = badging.lines.find { |line| line.start_with?('native-code:') }.to_s.scan(/'([^']+)'/).flatten
    missing = %w[arm64-v8a armeabi-v7a x86_64] - abis
    raise InvalidApk, "APK is not universal; missing ABIs: #{missing.join(', ')}" unless missing.empty?
  end
end
