require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael) 
  end

  test 'micropost interface' do
    log_in_as @user
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type="file"]'#看有沒有上傳圖片的表格
    #無效提交
    assert_no_difference 'Micropost.count' do #因為是無效提交所以應該要數量不會改變
      post microposts_path, params: {micropost: {content: ""} }
    end
    assert_select 'div#error_explaination'
    #有效提交
    content = "This micropost really ties the room together"
    picture = fixture_file_upload('test/fixtures/rails.png', 'image/png')
    assert_difference 'Micropost.count', 1 do 
      post microposts_path, params: {micropost: { content: content, picture: picture }}
    end
    assert @user.microposts.find_by(content: content).picture?#確認剛剛ＰＯ的文裡面有照片
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    #刪除一篇微薄
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end

    #訪問另外的用戶頁面，不可以顯示delete連結
    get user_path(users(:archer))
    assert_select 'a', text: 'delete', count: 0
  end

  test "micropost sidebar count" do
    log_in_as @user
    get root_path
    assert_match "#{@user.microposts.count} Microposts", response.body

    #沒有發布微薄的用戶
    other_user = users(:malory)
    log_in_as other_user
    get root_path
    assert_match "0 Microposts", response.body
    other_user.microposts.create!(content: "A Micropost")
    get root_path
    assert_match "1 Micropost", response.body
  end
end
