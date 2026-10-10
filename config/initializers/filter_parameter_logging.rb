# The vault deliberately treats even titles/usernames/URLs/notes as sensitive
# because those fields are encrypted inside the payload at rest.
Rails.application.config.filter_parameters += [
  :passw, :current_password, :password_confirmation,
  :secret, :secret_value, :token, :api_key, :private_key, :credential, :plaintext,
  :title, :q, :username, :url, :notes, :email, :email_address,
  :environment, :environment_name, :env_text, :value,
  :otp, :totp, :recovery_code, :code,
  :wrapped_dek, :ciphertext, :authentication_tag, :nonce
]
