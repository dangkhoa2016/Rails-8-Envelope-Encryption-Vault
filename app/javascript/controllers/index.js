import { application } from "controllers/application"
import RevealController from "controllers/reveal_controller"
import ClipboardController from "controllers/clipboard_controller"
import SecretFieldController from "controllers/secret_field_controller"
import MobileNavController from "controllers/mobile_nav_controller"
import FlashController from "controllers/flash_controller"
import VaultSearchController from "controllers/vault_search_controller"
import AuditFiltersController from "controllers/audit_filters_controller"
import FavoriteControlController from "controllers/favorite_control_controller"

application.register("reveal", RevealController)
application.register("clipboard", ClipboardController)
application.register("secret-field", SecretFieldController)
application.register("mobile-nav", MobileNavController)
application.register("flash", FlashController)
application.register("vault-search", VaultSearchController)
application.register("audit-filters", AuditFiltersController)
application.register("favorite-control", FavoriteControlController)

import ScrollExperienceController from "controllers/scroll_experience_controller"
application.register("scroll-experience", ScrollExperienceController)
