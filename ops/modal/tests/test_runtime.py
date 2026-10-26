"""Contract tests: never connect to real hosts or leak database URLs."""
import base64
import importlib.util
import pathlib
import unittest

SOURCE = pathlib.Path(__file__).resolve().parents[1] / "runtime.py"
SPEC = importlib.util.spec_from_file_location("revault_modal_runtime", SOURCE)
runtime = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runtime)


class ModalDatabaseSelectionTest(unittest.TestCase):
    def setUp(self):
        self.environment = {
            "SECRET_KEY_BASE": "a" * 80,
            "APP_HOSTS": "example.modal.run",
            "VAULT_ACTIVE_KEK_ID": "key-2026",
            "VAULT_KEK_B64": base64.b64encode(b"k" * 32).decode(),
            "DEMO_PASSWORD": "synthetic-demo-password",
        }

    def test_demo_without_url_uses_disposable_database(self):
        self.assertIsNone(runtime.select_database("demo", {}))
        self.assertIsNone(runtime.verify_config("demo", self.environment))

    def test_demo_rejects_external_url(self):
        for name in ("PRODUCTION_POSTGRES_URL", "DATABASE_URL"):
            with self.subTest(name=name):
                with self.assertRaisesRegex(ValueError, "DEMO_MUST_NOT_USE_EXTERNAL"):
                    runtime.select_database("demo", {name: "postgresql://user:pass@db.example/test"})

    def test_private_fails_closed_when_url_missing(self):
        with self.assertRaisesRegex(ValueError, "PRIVATE_REQUIRES_PRODUCTION_POSTGRES_URL"):
            runtime.select_database("private", {})

    def test_private_uses_external_with_tls(self):
        url = "postgresql://user:pass@db.example/private_vault"
        self.assertEqual(
            runtime.select_database("private", {"PRODUCTION_POSTGRES_URL": url}),
            url + "?sslmode=require",
        )

    def test_private_preserves_verified_ssl_mode(self):
        url = "postgresql://u:p@db.example/vault?sslmode=verify-full"
        self.assertEqual(
            runtime.select_database("private", {"PRODUCTION_POSTGRES_URL": url}), url
        )

    def test_private_rejects_non_tls_config(self):
        for mode in ("disable", "allow", "prefer"):
            with self.subTest(mode=mode), self.assertRaisesRegex(ValueError, "SSL"):
                runtime.select_database(
                    "private", {"PRODUCTION_POSTGRES_URL":
                                "postgresql://u:p@db.example/vault?sslmode=" + mode}
                )

    def test_private_rejects_local_database(self):
        for host in ("localhost", "127.0.0.1", "[::1]"):
            with self.subTest(host=host), self.assertRaisesRegex(ValueError, "EXTERNAL"):
                runtime.select_database(
                    "private", {"PRODUCTION_POSTGRES_URL":
                                "postgresql://u:p@" + host + "/vault"}
                )

    def test_private_rejects_invalid_url(self):
        for url in ("sqlite3:/tmp/data", "postgresql://localhost", "postgresql:///missing"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                runtime.select_database("private", {"PRODUCTION_POSTGRES_URL": url})

    def test_private_config_succeeds_only_with_database_url(self):
        private = dict(self.environment,
                       PRODUCTION_POSTGRES_URL="postgresql://u:p@db.example/vault")
        self.assertIn("sslmode=require", runtime.verify_config("private", private))

    def test_private_disallows_loopback_app_host(self):
        private = dict(self.environment, APP_HOSTS="localhost",
                       PRODUCTION_POSTGRES_URL="postgresql://u:p@db.example/vault")
        with self.assertRaisesRegex(ValueError, "LOOPBACK"):
            runtime.verify_config("private", private)

    def test_short_key_fails(self):
        short = dict(self.environment, VAULT_KEK_B64=base64.b64encode(b"short").decode())
        with self.assertRaisesRegex(ValueError, "INVALID_KEK_LENGTH"):
            runtime.verify_config("demo", short)

    def test_password_requirement_is_demo_only(self):
        demo = dict(self.environment, DEMO_PASSWORD="short")
        with self.assertRaisesRegex(ValueError, "DEMO_PASSWORD"):
            runtime.verify_config("demo", demo)
        private = dict(demo, PRODUCTION_POSTGRES_URL="postgresql://u:p@db.example/vault")
        self.assertIsNotNone(runtime.verify_config("private", private))


if __name__ == "__main__":
    unittest.main()
