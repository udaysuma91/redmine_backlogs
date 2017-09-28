
# Usage:
#
# it "should show email for a newly created user" do
#   email = "john@example.com"
#
#   visit new_user_path
#   fill_in "Email", with: email
#   fill_in "Password", with: "secret-password"
#   click_button "Save"
#
#   user = nil
#   expect { user = User.find_by(email: email) }.to become_truthy
#
#   visit user_path(user)
#
#   expect(page).to have_content(email)
# end

RSpec::Matchers.define :become_truthy do |event_name|
  supports_block_expectations

  match do |block|
    begin
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep(0.05) until value = block.call
        value
      end
    rescue TimeoutError
      false
    end
  end
end