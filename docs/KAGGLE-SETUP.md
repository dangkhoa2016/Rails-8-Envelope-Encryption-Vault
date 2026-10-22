# Notebook Setup — 1.0.0

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](KAGGLE-SETUP.vi.md)
The Rails 8 source can be demonstrated in Kaggle or Colab without Docker
or systemd. Use synthetic secrets and enable network access during installation.

Run these commands in a notebook terminal:

    git clone https://github.com/dangkhoa2016/Rails-8-Envelope-Encryption-Vault.git
    cd Rails-8-Envelope-Encryption-Vault
    chmod +x bootstrap.sh
    START_SERVER=0 ./bootstrap.sh

Then start with ./bootstrap.sh, inspect with ./bootstrap.sh status,
or perform diagnostics using ./bootstrap.sh doctor.

The bootstrap stores writable runtime state outside the Git checkout:
under /kaggle/working on Kaggle, or /content on Colab.
In a fresh terminal run: source ./activate-runtime.sh

Never commit .env.kaggle, actual vault data, recovery keys, KEKs,
database dumps or production credentials. Notebook setup does not
constitute production deployment acceptance.

## Notebook roadmap

This source-driven CPU demonstration uses a temporary Rails database and synthetic encrypted data. The notebook implementation will be published after its security and source verification contracts are ready.
