require 'minitest/autorun'
require_relative 'apk_validator'

class ApkValidatorTest < Minitest::Test
  def setup
    @badging = "package: name='com.piotrwittig.plan_pm' versionCode='28' versionName='1.3.1'\n" \
               "native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'\n"
    @manifest = 'E: manifest'
  end

  def check(badging = @badging, manifest = @manifest)
    PlanPmApkValidator.check_metadata!(badging, manifest, version_name: '1.3.1', version_code: 28)
  end

  def test_complete_unprotected_apk_is_accepted
    check
  end

  def test_google_licence_activity_is_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging, 'com.pairip.licensecheck.LicenseActivity') }
  end

  def test_google_licence_permission_is_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging, 'com.android.vending.CHECK_LICENSE') }
  end

  def test_wrong_release_is_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging.sub("versionCode='28'", "versionCode='27'")) }
  end

  def test_other_application_is_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging.sub('com.piotrwittig.plan_pm', 'com.example.other')) }
  end

  def test_incomplete_architectures_are_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging.sub("'arm64-v8a'", '')) }
  end

  def test_split_apk_is_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging.sub("versionCode='28'", "split='config.arm64_v8a' versionCode='28'")) }
  end

  def test_missing_required_splits_are_rejected
    assert_raises(PlanPmApkValidator::InvalidApk) { check(@badging, 'A: android:isSplitRequired(0x0101064e)=(type 0x12)0xffffffff') }
  end
end
