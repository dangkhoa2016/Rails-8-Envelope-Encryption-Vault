require "test_helper"

class FaviconMetadataTest < ActionDispatch::IntegrationTest
  test "public favicon images and their third-party attribution remain available" do
    png = Rails.root.join("public/favicon.png")
    ico = Rails.root.join("public/favicon.ico")
    notice = Rails.root.join("public/FAVICON-LICENSE.txt")

    assert File.file?(png)
    assert File.file?(ico)
    assert File.file?(notice)
    assert_equal "\x89PNG\r\n\x1a\n".b, File.binread(png, 8)
    assert_equal "\x00\x00\x01\x00".b, File.binread(ico, 4)
    assert_includes File.read(notice), "https://www.magnific.com/icon/safe-box_5861990"
    assert_includes File.read(notice), "https://www.magnific.com/author/magnific"
  end

  test "public login page links both favicon formats and credits original designer" do
    get new_session_path
    assert_response :success
    assert_select "head link[rel='icon'][href='/favicon.ico'][type='image/x-icon']", 1
    assert_select "head link[rel='icon'][href='/favicon.png'][type='image/png']", 1
    assert_select "footer[aria-label='Favicon attribution'] a[href='https://www.magnific.com/author/magnific']", 1
  end
end
