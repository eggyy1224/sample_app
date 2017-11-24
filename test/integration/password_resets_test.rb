require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password reset" do
    get new_password_reset_path#到reset的表單裡
    assert_template 'password_resets/new'#確認進去對的頁面
    #給無效的電子郵件
    post password_resets_path, params: { password_reset: {email: ""} }
    assert_not flash.empty?#確認有flash
    assert_template 'password_resets/new'#確認業面導回new
    #valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest#信件有寄發出去的話會產生一組新的reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size#信件寄發的量多一
    assert_not flash.empty?#確認有flash
    assert_redirected_to root_url
    #密碼重設表單
    user = assigns(:user)
    #電子郵件錯誤
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    #用戶未激活
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    #correct email with wrong token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    #correct email with correct token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'#確認跑到edit頁面
    assert_select 'input[name=email][type=hidden][value=?]', user.email#確認html tag正確
    #密碼與密碼確認不匹配
    patch password_reset_path(user.reset_token), params: { user: { password: 'foobar', password_confirmation: '123456' }, email: user.email }
    assert_select 'div#error_explaination'
    #empty password
    patch password_reset_path(user.reset_token), params: { user: { password: '', password_confirmation: '' }, email: user.email }
    assert_select 'div#error_explaination'
    #valid psd and confirmation
    patch password_reset_path(user.reset_token), params: { user: { password: 'foobar', password_confirmation: 'foobar' }, email: user.email }
    assert is_logged_in? 
    assert_not flash.empty?
    
    assert user.reload.reset_digest.nil?
    
    assert_redirected_to user
  end

  test 'expired reset_token' do
    get new_password_reset_path #to password_resets/
    #to password_resets/create
    post password_resets_path, params: { password_reset: { email: @user.email } }
    @user = assigns(:user)

    @user.update_attribute( :reset_sent_at, 3.hours.ago )
    patch password_reset_path(@user.reset_token), params: { user: { password: "foobar", password_confirmation: "foobar" }, email: @user.email }
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end

end
