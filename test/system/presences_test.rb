require "application_system_test_case"

class PresencesTest < ApplicationSystemTestCase
  setup do
    @presence = presences(:one)
  end

  test "visiting the index" do
    visit presences_url
    assert_selector "h1", text: "Presences"
  end

  test "creating a Presence" do
    visit presences_url
    click_on "New Presence"

    fill_in "Arena", with: @presence.arena
    fill_in "Attendant", with: @presence.attendant
    fill_in "Name", with: @presence.name
    fill_in "Phone number", with: @presence.phone_number
    fill_in "Question1", with: @presence.question1
    fill_in "Question2", with: @presence.question2
    fill_in "Question3", with: @presence.question3
    fill_in "Question4", with: @presence.question4
    click_on "Create Presence"

    assert_text "Presence was successfully created"
    click_on "Back"
  end

  test "updating a Presence" do
    visit presences_url
    click_on "Edit", match: :first

    fill_in "Arena", with: @presence.arena
    fill_in "Attendant", with: @presence.attendant
    fill_in "Name", with: @presence.name
    fill_in "Phone number", with: @presence.phone_number
    fill_in "Question1", with: @presence.question1
    fill_in "Question2", with: @presence.question2
    fill_in "Question3", with: @presence.question3
    fill_in "Question4", with: @presence.question4
    click_on "Update Presence"

    assert_text "Presence was successfully updated"
    click_on "Back"
  end

  test "destroying a Presence" do
    visit presences_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Presence was successfully destroyed"
  end
end
