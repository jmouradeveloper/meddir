require "test_helper"

class I18nModelTest < ActiveSupport::TestCase
  # ============================================
  # MedicalFolder Specialty Translation Tests
  # ============================================

  test "medical folder specialty_name returns English name when locale is English" do
    I18n.with_locale(:en) do
      folder = medical_folders(:cardiology)
      assert_equal "Cardiology", folder.specialty_name
    end
  end

  test "medical folder specialty_name returns Portuguese name when locale is Portuguese" do
    I18n.with_locale(:"pt-BR") do
      folder = medical_folders(:cardiology)
      assert_equal "Cardiologia", folder.specialty_name
    end
  end

  test "medical folder specialty_name falls back to default for unknown specialty" do
    folder = MedicalFolder.new(specialty: "unknown")
    # Should return the default from SPECIALTIES hash
    assert_not_nil folder.specialty_name
  end

  # ============================================
  # Document Date Formatting Tests
  # ============================================

  test "document formatted_date returns English format" do
    I18n.with_locale(:en) do
      document = Document.new(document_date: Date.new(2026, 1, 15))
      assert_equal "January 15, 2026", document.formatted_date
    end
  end

  test "document formatted_date returns Portuguese format" do
    I18n.with_locale(:"pt-BR") do
      document = Document.new(document_date: Date.new(2026, 1, 15))
      assert_equal "15 de janeiro de 2026", document.formatted_date
    end
  end

  test "document formatted_date returns no_date translation when date is nil" do
    I18n.with_locale(:en) do
      document = Document.new(document_date: nil)
      assert_equal "No date", document.formatted_date
    end
  end

  test "document formatted_date returns Portuguese no_date when date is nil" do
    I18n.with_locale(:"pt-BR") do
      document = Document.new(document_date: nil)
      assert_equal "Sem data", document.formatted_date
    end
  end

  # ============================================
  # ShareableLink Expiration Translation Tests
  # ============================================

  test "shareable link formatted_expiration returns never expires in English" do
    I18n.with_locale(:en) do
      link = ShareableLink.new(expires_at: nil, active: true)
      assert_equal "Never expires", link.formatted_expiration
    end
  end

  test "shareable link formatted_expiration returns never expires in Portuguese" do
    I18n.with_locale(:"pt-BR") do
      link = ShareableLink.new(expires_at: nil, active: true)
      assert_equal "Nunca expira", link.formatted_expiration
    end
  end

  test "shareable link formatted_expiration shows expiration date in English" do
    I18n.with_locale(:en) do
      link = ShareableLink.new(expires_at: Time.new(2026, 2, 15, 14, 30), active: true)
      assert_match(/Expires on/, link.formatted_expiration)
      assert_match(/February/, link.formatted_expiration)
    end
  end

  test "shareable link formatted_expiration shows expiration date in Portuguese" do
    I18n.with_locale(:"pt-BR") do
      link = ShareableLink.new(expires_at: Time.new(2026, 2, 15, 14, 30), active: true)
      assert_match(/Expira em/, link.formatted_expiration)
      assert_match(/fevereiro/, link.formatted_expiration)
    end
  end

  test "shareable link formatted_expiration shows expired in English" do
    I18n.with_locale(:en) do
      link = ShareableLink.new(expires_at: 1.day.ago, active: true)
      assert_match(/Expired on/, link.formatted_expiration)
    end
  end

  test "shareable link formatted_expiration shows expired in Portuguese" do
    I18n.with_locale(:"pt-BR") do
      link = ShareableLink.new(expires_at: 1.day.ago, active: true)
      assert_match(/Expirou em/, link.formatted_expiration)
    end
  end

  # ============================================
  # User Locale Attribute Tests
  # ============================================

  test "user can have locale attribute set to English" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      locale: "en"
    )
    assert user.valid?
    assert_equal "en", user.locale
  end

  test "user can have locale attribute set to Portuguese" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      locale: "pt-BR"
    )
    assert user.valid?
    assert_equal "pt-BR", user.locale
  end

  test "user locale can be nil" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      locale: nil
    )
    assert user.valid?
    assert_nil user.locale
  end

  # ============================================
  # Translation Key Tests
  # ============================================

  test "all specialty keys have English translations" do
    I18n.with_locale(:en) do
      MedicalFolder::SPECIALTIES.keys.each do |specialty|
        translation = I18n.t("specialties.#{specialty}")
        assert_no_match(/translation missing/i, translation.to_s,
          "Missing English translation for specialty: #{specialty}")
      end
    end
  end

  test "all specialty keys have Portuguese translations" do
    I18n.with_locale(:"pt-BR") do
      MedicalFolder::SPECIALTIES.keys.each do |specialty|
        translation = I18n.t("specialties.#{specialty}")
        assert_no_match(/translation missing/i, translation.to_s,
          "Missing Portuguese translation for specialty: #{specialty}")
      end
    end
  end

  test "common flash messages have English translations" do
    I18n.with_locale(:en) do
      flash_keys = %w[
        flash.sessions.invalid_credentials
        flash.registrations.welcome
        flash.passwords.reset_sent
        flash.medical_folders.created
        flash.documents.created
        flash.shareable_links.created
      ]

      flash_keys.each do |key|
        translation = I18n.t(key)
        assert_no_match(/translation missing/i, translation.to_s,
          "Missing English translation for: #{key}")
      end
    end
  end

  test "common flash messages have Portuguese translations" do
    I18n.with_locale(:"pt-BR") do
      flash_keys = %w[
        flash.sessions.invalid_credentials
        flash.registrations.welcome
        flash.passwords.reset_sent
        flash.medical_folders.created
        flash.documents.created
        flash.shareable_links.created
      ]

      flash_keys.each do |key|
        translation = I18n.t(key)
        assert_no_match(/translation missing/i, translation.to_s,
          "Missing Portuguese translation for: #{key}")
      end
    end
  end
end
