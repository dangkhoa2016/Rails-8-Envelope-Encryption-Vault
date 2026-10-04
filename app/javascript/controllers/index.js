import { application } from "controllers/application"
import RevealController from "controllers/reveal_controller"
import ClipboardController from "controllers/clipboard_controller"
import SecretFieldController from "controllers/secret_field_controller"
import MobileNavController from "controllers/mobile_nav_controller"
import FlashController from "controllers/flash_controller"

application.register("reveal", RevealController)
application.register("clipboard", ClipboardController)
application.register("secret-field", SecretFieldController)
application.register("mobile-nav", MobileNavController)
application.register("flash", FlashController)
