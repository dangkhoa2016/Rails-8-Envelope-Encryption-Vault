require "application_system_test_case"

class ProductionUxAccessibilityTest < ApplicationSystemTestCase
  test "keyboard tab reveals skip link with visible focus treatment" do
    visit new_session_path

    browser = page.driver.browser
    assert_equal "email_address", browser.switch_to.active_element.attribute("name")
    browser.action.key_down(:shift).send_keys(:tab).key_up(:shift).perform
    active = browser.switch_to.active_element

    assert_equal "A", active.tag_name.upcase
    assert_equal "#main-content", URI(active.attribute("href")).fragment.then { |f| "##{f}" }
    focus = page.evaluate_script(<<~JS)
      (() => {
        const s = getComputedStyle(document.activeElement)
        return { width: s.outlineWidth, style: s.outlineStyle, shadow: s.boxShadow }
      })()
    JS
    has_outline = focus["width"] != "0px" && focus["style"] != "none"
    has_ring = focus["shadow"] && focus["shadow"] != "none"
    assert(has_outline || has_ring, "focused skip link must expose outline or focus ring")
  end

  test "registration validation exposes assertive error semantics" do
    previous = ENV["ALLOW_SIGNUPS"]
    ENV["ALLOW_SIGNUPS"] = "true"

    visit new_registration_path
    page.execute_script("document.querySelector('form').noValidate = true")
    fill_in "user_email_address", with: "invalid-email"
    fill_in "user_password", with: "short-password"
    fill_in "user_password_confirmation", with: "mismatch-value"
    click_button "Create account"

    assert_selector "#registration-errors[role='alert'][aria-live='assertive']", count: 1
    assert_text "Please correct the following:"
  ensure
    ENV["ALLOW_SIGNUPS"] = previous
  end

  test "compact 640px viewport preserves core pages without horizontal overflow" do
    user = create_system_user("fix40-reflow@example.test")
    sign_in_system_user(user)
    page.current_window.resize_to(640, 900)

    [ root_path, vault_items_path, new_vault_item_path, settings_security_path ].each do |path|
      visit path
      widths = page.evaluate_script(<<~JS)
        ({
          client: document.documentElement.clientWidth,
          scroll: document.documentElement.scrollWidth
        })
      JS
      assert_operator widths["scroll"], :<=, widths["client"] + 1,
        "200% reflow proxy overflow at #{path}"
    end
  end

  test "dashboard medium desktop viewport stacks secondary cards without cramped security posture" do
    user = create_system_user("fix016-dashboard-reflow@example.test")
    sign_in_system_user(user)
    page.current_window.resize_to(1365, 900)
    visit root_path
    assert_selector "[data-dashboard-main-grid]"

    metrics = page.evaluate_script(<<~JS)
      (() => {
        const grid = document.querySelector("[data-dashboard-main-grid]")
        const badge = Array.from(document.querySelectorAll("a")).find((el) => el.textContent.trim() === "Not enabled")
        const style = getComputedStyle(grid)
        const badgeStyle = badge ? getComputedStyle(badge) : null
        return {
          client: document.documentElement.clientWidth,
          scroll: document.documentElement.scrollWidth,
          columns: style.gridTemplateColumns,
          badgeWhiteSpace: badgeStyle && badgeStyle.whiteSpace,
          badgeHeight: badge && badge.getBoundingClientRect().height
        }
      })()
    JS

    assert_operator metrics["scroll"], :<=, metrics["client"] + 1
    assert_equal 1, metrics["columns"].split(" ").length, "dashboard should stack below the 2xl breakpoint"
    assert_equal "nowrap", metrics["badgeWhiteSpace"]
    assert_operator metrics["badgeHeight"], :<, 40
  end

  test "primary mobile controls provide practical target dimensions" do
    user = create_system_user("fix40-targets@example.test")
    sign_in_system_user(user)
    assert_text "Your encrypted vault"

    page.current_window.resize_to(390, 844)
    visit root_path
    assert_operator page.evaluate_script("window.innerWidth"), :<, 1024
    assert_selector "button[aria-label='Toggle navigation']", visible: :all, count: 1

    selectors = [
      "button[aria-label='Toggle navigation']",
      "a[href='#{new_vault_item_path}']"
    ]
    selectors.each do |selector|
      element = find(selector, match: :first, visible: :all)
      box = page.evaluate_script(<<~JS, element)
        ((el) => {
          const r = el.getBoundingClientRect()
          return { width: r.width, height: r.height, display: getComputedStyle(el).display }
        })(arguments[0])
      JS
      refute_equal "none", box["display"], "target hidden at compact viewport: #{selector}"
      assert_operator box["width"], :>=, 40, "target too narrow: #{selector}"
      assert_operator box["height"], :>=, 40, "target too short: #{selector}"
    end
  end

  test "browser reduced motion preference activates reduced transition timing" do
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia",
      media: "",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    visit new_session_path

    assert page.evaluate_script("matchMedia('(prefers-reduced-motion: reduce)').matches")
    duration = page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector("[data-controller='flash'], .transition")
        if (!el) {
          const probe = document.createElement("div")
          probe.className = "transition"
          document.body.appendChild(probe)
          return getComputedStyle(probe).transitionDuration
        }
        return getComputedStyle(el).transitionDuration
      })()
    JS
    assert_includes [ "0s", "1e-05s", "0.00001s" ], duration
  ensure
    browser&.execute_cdp("Emulation.setEmulatedMedia", media: "", features: [])
  end
end
