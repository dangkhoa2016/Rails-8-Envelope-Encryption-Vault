require "application_system_test_case"
require "timeout"

class ScrollExperienceTest < ApplicationSystemTestCase
  def wait_for_scroll_to(target_id)
    Timeout.timeout(7) do
      loop do
        position = evaluate_script(<<~JS)
          (() => {
            const target = document.getElementById("#{target_id}");
            return target ? target.getBoundingClientRect().top : -999;
          })()
        JS
        break if position >= 30 && position <= 135
        sleep 0.08
      end
    end
  end

  test "back-to-top appears after scrolling and respects reduced motion on mobile" do
    user = create_system_user("scroll-ux-top@example.test")
    sign_in_system_user(user)
    28.times { AuditEvent.create!(user:, action: "vault_item.updated", metadata: {}) }

    [ [ 1400, 650 ], [ 390, 650 ] ].each do |width, height|
      page.current_window.resize_to(width, height)
      visit audit_events_path
      assert_no_selector 'button[aria-label="Back to top"]', visible: true
      execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
      assert_operator evaluate_script("window.scrollY"), :>, 160
      # Scroll listeners run asynchronously; wait for the visible state before
      # checking its geometry to avoid a race on fast CI browsers.
      assert_selector 'button[aria-label="Back to top"]', visible: true
      diagnosis = evaluate_script(<<~JS)
        (() => {
          const b = document.querySelector('button[aria-label="Back to top"]');
          return {
            y: window.scrollY,
            hidden: b?.hidden,
            display: b ? getComputedStyle(b).display : 'missing',
            visibility: b ? getComputedStyle(b).visibility : 'missing',
            bodyController: document.body.dataset.controller,
            controllerLoaded: Boolean(window.Stimulus?.controllers?.some(c => c.identifier === 'scroll-experience')),
            connectedControllers: window.Stimulus?.controllers?.map(c => c.identifier) || [],
            errors: window.__scrollErrors || [],
            position: b ? getComputedStyle(b).position : 'missing',
            opacity: b ? getComputedStyle(b).opacity : 'missing',
            rect: b ? [b.getBoundingClientRect().x, b.getBoundingClientRect().y, b.getBoundingClientRect().width, b.getBoundingClientRect().height] : [],
            viewport: [window.innerWidth, window.innerHeight],
            parent: b?.parentElement?.tagName,
            matchesHiddenSelector: b?.matches('[hidden]'),
            capybaraVisible: null
          };
        })()
      JS
      assert_equal false, diagnosis.fetch("hidden")
      assert_equal "fixed", diagnosis.fetch("position")
      assert_operator diagnosis.fetch("rect")[1], :>=, 0
      assert_operator diagnosis.fetch("rect")[1] + diagnosis.fetch("rect")[3], :<=, diagnosis.fetch("viewport")[1]
      assert_selector 'button[aria-label="Back to top"]', visible: true
      assert_equal "fixed", evaluate_script(
        "getComputedStyle(document.querySelector('button[aria-label=\"Back to top\"]')).position"
      )

      # Emulate the accessibility preference without relying on an OS setting.
      execute_script(<<~JS)
        window.__scrollTopBehavior = null;
        const realScrollTo = window.scrollTo.bind(window);
        window.matchMedia = () => ({ matches: true });
        window.scrollTo = (options) => {
          window.__scrollTopBehavior = options.behavior;
          return realScrollTo(options);
        };
      JS
      click_button "Back to top"
      assert_equal "auto", evaluate_script("window.__scrollTopBehavior")
      assert_no_selector 'button[aria-label="Back to top"]', visible: true
      assert_operator evaluate_script("window.scrollY"), :<=, 10
      assert_operator evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth"),
        :<=, 1
    end
  end

  test "audit pagination smoothly returns to its results heading, not summary cards" do
    user = create_system_user("scroll-ux-audit@example.test")
    sign_in_system_user(user)
    29.times { AuditEvent.create!(user:, action: "vault_item.updated", metadata: {}) }

    page.current_window.resize_to(1000, 640)
    visit audit_events_path
    assert_selector 'nav[aria-label="Audit pagination"][data-pagination-scroll-target="audit_timeline"]'
    assert_selector 'a[rel="next"]', visible: true
    click_link "Next", match: :first
    assert_text "Page 2 of"
    assert_current_path(/page=2/, ignore_query: false)
    wait_for_scroll_to("audit_timeline")
    assert_operator evaluate_script("window.scrollY"), :>, 100
    assert_nil evaluate_script("sessionStorage.getItem('revault:pagination-scroll')")
  end

  test "Sessions and Vault pagination return to their own listing without removing filters" do
    user = create_system_user("scroll-ux-sessions@example.test")
    sign_in_system_user(user)
    23.times do |index|
      user.sessions.create!(
        user_agent: "Chrome Synthetic/#{index + 1}",
        ip_address: "198.51.100.#{index + 10}",
        created_at: Time.current - (index + 1).minutes,
        last_seen_at: Time.current, absolute_expires_at: Time.current + 1.day
      )
    end

    page.current_window.resize_to(1000, 640)
    visit settings_sessions_path
    assert_selector 'nav[aria-label="Sessions pagination"][data-pagination-scroll-target="sessions_history"]'
    click_link "Next"
    assert_text "Page 2 of 3"
    wait_for_scroll_to("sessions_history")
    assert_operator evaluate_script("window.scrollY"), :>, 100

    17.times do |index|
      Vault::CreateItem.call(user:, kind: "login", payload: {
        "schema" => "vault.login.v1", "title" => "Encrypted paging #{index}",
        "username" => "synthetic@example.test", "password" => "example",
        "url" => "https://example.test", "notes" => "", "tags" => %w[synthetic]
      })
    end
    visit vault_items_path
    assert_selector 'nav[aria-label="Vault pagination"][data-pagination-scroll-target="vault_listing"]'
    click_link "Next"
    assert_text "Page 2 of"
    assert_selector "#vault_listing", visible: true
    assert_current_path(/page=2/, ignore_query: false)
    assert_nil evaluate_script("sessionStorage.getItem('revault:pagination-scroll')")
  end
end
