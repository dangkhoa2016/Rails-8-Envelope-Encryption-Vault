require_relative "../../crypto_test_helper"

class LocalFileKeyProviderTest < Minitest::Test
  include CryptoTestSupport

  def test_wrap_unwrap_round_trip
    with_provider do |provider|
      dek = OpenSSL::Random.random_bytes(32)
      wrapped = provider.wrap_key(dek: dek, context: context)
      assert_equal dek, provider.unwrap_key(wrapped_key: wrapped, key_id: provider.active_key_id, context: context)
      refute_includes wrapped, dek
    end
  end

  def test_tampered_wrapped_key_fails
    with_provider do |provider|
      dek = OpenSSL::Random.random_bytes(32)
      wrapped = provider.wrap_key(dek: dek, context: context)
      data = JSON.parse(wrapped)
      ct = Base64.urlsafe_decode64(data.fetch("ct"))
      ct.setbyte(0, ct.getbyte(0) ^ 0x01)
      data["ct"] = Base64.urlsafe_encode64(ct, padding: false)
      assert_raises(Crypto::KeyUnwrapError) do
        provider.unwrap_key(wrapped_key: JSON.generate(data), key_id: provider.active_key_id, context: context)
      end
    end
  end

  def test_wrong_kek_fails
    Dir.mktmpdir("revault-test") do |dir|
      File.binwrite(File.join(dir, "a.key"), OpenSSL::Random.random_bytes(32))
      File.binwrite(File.join(dir, "b.key"), OpenSSL::Random.random_bytes(32))
      a = KeyProviders::LocalFile.new(key_dir: dir, active_key_id: "a")
      wrapped = a.wrap_key(dek: OpenSSL::Random.random_bytes(32), context: context)
      assert_raises(Crypto::KeyUnwrapError) { a.unwrap_key(wrapped_key: wrapped, key_id: "b", context: context) }
    end
  end
end
