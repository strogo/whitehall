When /^I filter to only those from the "([^"]*)" department$/ do |department|
  # This call to `unselect` doesn't work with capybara-webkit because it does
  # not recognise the select as a multi-select.
  # Here's the fix, waiting to be merged:
  # https://github.com/thoughtbot/capybara-webkit/pull/361
  # unselect "All departments", from: "Department"
  page.evaluate_script(%{$("#departments option[value='all']").removeAttr("selected"); 1})

  select department, from: "Department"
  click_button "Refresh"
  wait_until { page.evaluate_script("jQuery.active") == 0 }
end

Then /^I should see a link to the next page of documents$/ do
  assert has_css?('#show-more-documents li.next')
end

Then /^I should see that the (next|previous) page is (\d+) of (\d+)$/ do |css_class, next_page, total_pages|
  assert has_css?("#show-more-documents .#{css_class} span", text: "#{next_page} of #{total_pages}")
end
