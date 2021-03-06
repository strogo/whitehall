require 'test_helper'

class OrganisationTest < ActiveSupport::TestCase
  test 'should be invalid without a name' do
    organisation = build(:organisation, name: nil)
    refute organisation.valid?
  end

  test 'should be invalid without a logo formatted name' do
    organisation = build(:organisation, logo_formatted_name: nil)
    refute organisation.valid?
  end

  test 'should be invalid with a duplicate name' do
    existing_organisation = create(:organisation)
    new_organisation = build(:organisation, name: existing_organisation.name)
    refute new_organisation.valid?
  end

  test 'should be invalid with a badly formatted alternative_format_contact_email' do
    new_organisation = build(:organisation, alternative_format_contact_email: "this@email@is@invalid")
    refute new_organisation.valid?
  end

  test 'should be invalid with a blank alternative_format_contact_email if it is used as a alternative_format_provider' do
    organisation = create(:organisation, alternative_format_contact_email: "alternative@example.com")
    create(:draft_publication, alternative_format_provider: organisation)
    assert organisation.valid?
    organisation.alternative_format_contact_email = ""
    refute organisation.valid?
  end

  test "should be orderable ignoring common prefixes" do
    culture = create(:organisation, name: "Department for Culture and Sports")
    education = create(:organisation, name: "Department of Education")
    hmrc = create(:organisation, name: "HMRC")
    defence = create(:organisation, name: "Ministry of Defence")

    assert_equal [culture, defence, education, hmrc], Organisation.ordered_by_name_ignoring_prefix
  end

  test "#child_organisations should return the parent's children organisations" do
    parent_org_1 = create(:organisation)
    parent_org_2 = create(:organisation)
    child_org_1 = create(:organisation, parent_organisations: [parent_org_1])
    child_org_2 = create(:organisation, parent_organisations: [parent_org_1])
    child_org_3 = create(:organisation, parent_organisations: [parent_org_2])

    assert_equal [child_org_1, child_org_2], parent_org_1.child_organisations
  end

  test "#parent_organisations should return the child's parent organisations" do
    child_org_1 = create(:organisation)
    child_org_2 = create(:organisation)
    parent_org_1 = create(:organisation, child_organisations: [child_org_1])
    parent_org_2 = create(:organisation, child_organisations: [child_org_1])
    parent_org_3 = create(:organisation, child_organisations: [child_org_2])

    assert_equal [parent_org_1, parent_org_2], child_org_1.parent_organisations
  end

  test 'can list all parent organisations' do
    parent = create(:organisation, child_organisations: [create(:organisation)])

    assert_equal [parent.id], Organisation.parent_organisations.map(&:id)
  end

  test '#root_organisation returns the organsation itself for a top level organisation' do
    parent = create(:organisation)
    assert_equal parent, parent.root_organisation
  end

  test '#root_organisation returns the parent of a child organsation' do
    child = create(:organisation)
    parent = create(:organisation, child_organisations: [child])
    assert_equal parent, child.root_organisation
  end

  test '#root_organisation returns the first org before the loop if there is a loop' do
    org1 = create(:organisation)
    org2 = create(:organisation, child_organisations: [org1])
    org1.child_organisations << org2
    org1.save!
    assert_equal org2, org1.root_organisation
  end

  test '#ministerial_roles includes all ministerial roles' do
    minister = create(:ministerial_role)
    organisation = create(:organisation, roles:  [minister])
    assert_equal [minister], organisation.ministerial_roles
  end

  test '#ministerial_roles excludes non-ministerial roles' do
    permanent_secretary = create(:board_member_role)
    organisation = create(:organisation, roles:  [permanent_secretary])
    assert_equal [], organisation.ministerial_roles
  end

  test "#top_ministerial_role returns the first ministerial role as defined by the ordering" do
    organisation = create(:organisation)
    junior_ministerial_role = create(:ministerial_role)
    senior_ministerial_role = create(:ministerial_role)
    junior_ministerial_organisation_role = create(:organisation_role, organisation: organisation, role: junior_ministerial_role, ordering: 2)
    senior_ministerial_organisation_role = create(:organisation_role, organisation: organisation, role: senior_ministerial_role, ordering: 1)
    assert_equal senior_ministerial_role, organisation.top_ministerial_role
  end

  test "#top_civil_servant returns the permanent secretary" do
    civil_servant = create(:board_member_role, permanent_secretary: false)
    permanent_secretary = create(:board_member_role, permanent_secretary: true)
    organisation = create(:organisation, roles:  [civil_servant, permanent_secretary])
    assert_equal permanent_secretary, organisation.top_civil_servant
  end

  test "#top_civil_servant returns nil if there aren't any permanent secretary" do
    civil_servant = create(:board_member_role, permanent_secretary: false)
    organisation = create(:organisation, roles:  [civil_servant])
    assert_nil organisation.top_civil_servant
  end

  test "#top_civil_servant never returns a ministerial role" do
    minister = create(:ministerial_role)
    cabinet_minister = create(:ministerial_role, cabinet_member: true)
    organisation = create(:organisation, roles:  [minister, cabinet_minister])
    assert_equal nil, organisation.top_civil_servant
  end

  test "#top_military_role returns the first role marked as the chief_of_the_defence_staff" do
    chief_of_staff = create(:military_role, chief_of_the_defence_staff: false)
    chief_of_the_defence_staff = create(:military_role, chief_of_the_defence_staff: true)
    organisation = create(:organisation, roles:  [chief_of_staff, chief_of_the_defence_staff])
    assert_equal chief_of_the_defence_staff, organisation.top_military_role
  end

  test "#top_military_role returns nil if the chief_of_the_defence_staff role doesn't exist" do
    chief_of_staff = create(:military_role, chief_of_the_defence_staff: false)
    organisation = create(:organisation, roles:  [chief_of_staff])
    assert_nil organisation.top_military_role
  end

  test '#board_member_roles includes all non-ministerial roles' do
    permanent_secretary = create(:board_member_role)
    organisation = create(:organisation, roles:  [permanent_secretary])
    assert_equal [permanent_secretary], organisation.board_member_roles
  end

  test '#board_member_roles excludes any ministerial roles' do
    minister = create(:ministerial_role)
    organisation = create(:organisation, roles:  [minister])
    assert_equal [], organisation.board_member_roles
  end

  test 'should be creatable with contact data' do
    params = {
      contacts_attributes: [
        {description: "Office address",
         email: "someone@gov.uk", address: "Aviation House, London",
         postcode: "WC2A 1BE", latitude: -0.112311, longitude: 51.215125},
        {description: "Helpline", contact_numbers_attributes: [
          {label: "Telephone", number: "020712345678"},
          {label: "Fax", number: "020712345679"}
        ]}
      ]
    }
    organisation = create(:organisation, params)

    assert_equal 2, organisation.contacts.count
    assert_equal "someone@gov.uk", organisation.contacts[0].email
    assert_equal "Aviation House, London", organisation.contacts[0].address
    assert_equal "WC2A 1BE", organisation.contacts[0].postcode
    assert_equal -0.112311, organisation.contacts[0].latitude
    assert_equal 51.215125, organisation.contacts[0].longitude
    assert_equal "Helpline", organisation.contacts[1].description
    assert_equal 2, organisation.contacts[1].contact_numbers.count
    assert_equal "Telephone", organisation.contacts[1].contact_numbers[0].label
    assert_equal "020712345678", organisation.contacts[1].contact_numbers[0].number
    assert_equal "Fax", organisation.contacts[1].contact_numbers[1].label
    assert_equal "020712345679", organisation.contacts[1].contact_numbers[1].number
  end

  test "should be creatable when both contacts and contact numbers are blank" do
    organisation = build(:organisation, contacts_attributes: [
      {description: "", contact_numbers_attributes: [{label: "", number: ""}]}
    ])
    assert organisation.valid?
  end

  test "should set a slug from the organisation name" do
    organisation = create(:organisation, name: 'Love all the people')
    assert_equal 'love-all-the-people', organisation.slug
  end

  test "should not change the slug when the name is changed" do
    organisation = create(:organisation, name: 'Love all the people')
    organisation.update_attributes(name: 'Hold hands')
    assert_equal 'love-all-the-people', organisation.slug
  end

  test "should concatenate words containing apostrophes" do
    organisation = create(:organisation, name: "Bob's bike")
    assert_equal 'bobs-bike', organisation.slug
  end

  test "should be returnable in an ordering suitable for organisational listing" do
    type_names = [
      "Ministerial department",
      "Non-ministerial department",
      "Executive agency",
      "Executive non-departmental public body",
      "Advisory non-departmental public body",
      "Tribunal non-departmental public body",
      "Public corporation",
      "Independent monitoring body",
      "Ad-hoc advisory group",
      "Other"
    ]
    types = type_names.shuffle.map { |t| create(:organisation_type, name: t) }
    organisations = types.shuffle.each { |t| create(:organisation, organisation_type: t) }

    orgs_in_order = Organisation.in_listing_order
    assert_equal type_names, orgs_in_order.map(&:organisation_type).map(&:name)
  end

  test 'should return search index data suitable for Rummageable' do
    organisation = create(:organisation, name: 'Ministry of Funk')

    assert_equal 'Ministry of Funk', organisation.search_index['title']
    assert_equal "/government/organisations/#{organisation.slug}", organisation.search_index['link']
    assert_equal organisation.description, organisation.search_index['indexable_content']
    assert_equal 'organisation', organisation.search_index['format']
  end

  test 'should add organisation to search index on creating' do
    organisation = build(:organisation)

    search_index_data = stub('search index data')
    organisation.stubs(:search_index).returns(search_index_data)
    Rummageable.stubs(:index) # ignore the update to the ministerial role index
    Rummageable.expects(:index).with(search_index_data)

    organisation.save
  end

  test 'should add organisation to search index on updating' do
    organisation = create(:organisation)

    search_index_data = stub('search index data')
    organisation.stubs(:search_index).returns(search_index_data)
    Rummageable.stubs(:index) # ignore the update to the ministerial role index
    Rummageable.expects(:index).with(search_index_data)

    organisation.name = 'Ministry of Junk'
    organisation.save
  end

  test 'should remove organisation from search index on destroying' do
    organisation = create(:organisation)
    Rummageable.expects(:delete).with("/government/organisations/#{organisation.slug}")
    organisation.destroy
  end

  test 'should return search index data for all organisations' do
    create(:organisation, name: 'Department for Culture and Sports', description: 'Sporty.')
    create(:organisation, name: 'Department of Education', description: 'Bookish.')
    create(:organisation, name: 'HMRC', description: 'Taxing.', acronym: 'hmrc')
    create(:organisation, name: 'Ministry of Defence', description: 'Defensive.', acronym: 'mod')

    results = Organisation.search_index

    assert_equal 4, results.length
    assert_equal({'title' => 'Department for Culture and Sports',
                  'link' => '/government/organisations/department-for-culture-and-sports',
                  'indexable_content' => 'Sporty.',
                  'format' => 'organisation',
                  'description' => ''}, results[0])
    assert_equal({'title' => 'Department of Education',
                  'link' => '/government/organisations/department-of-education',
                  'indexable_content' => 'Bookish.',
                  'format' => 'organisation',
                  'description' => ''}, results[1])
    assert_equal({'title' => 'HMRC',
                  'link' => '/government/organisations/hmrc',
                  'indexable_content' => 'Taxing.',
                  'format' => 'organisation',
                  'boost_phrases' => 'hmrc',
                  'description' => ''}, results[2])
    assert_equal({'title' => 'Ministry of Defence',
                  'link' => '/government/organisations/ministry-of-defence',
                  'indexable_content' => 'Defensive.',
                  'format' => 'organisation',
                  'boost_phrases' => 'mod',
                  'description' => ''}, results[3])
  end

  test '#featured_editions returns featured editions by ordering' do
    organisation = create(:organisation)
    alpha = create(:edition_organisation, organisation: organisation, edition: create(:published_edition, title: "Alpha"))
    beta = create(:edition_organisation, organisation: organisation, edition: create(:published_edition, title: "Beta"), featured: true, ordering: 1)
    gamma = create(:edition_organisation, organisation: organisation, edition: create(:published_edition, title: "Gamma"), featured: true, ordering: 0)
    delta = create(:edition_organisation, organisation: organisation, edition: create(:published_edition, title: "Delta"), featured: true, ordering: 2)

    assert_equal [gamma.edition, beta.edition, delta.edition], organisation.featured_editions
  end

  test '#published_specialist_guides returns published specialist guides' do
    organisation = create(:organisation)
    alpha = create(:draft_specialist_guide, organisations: [organisation], title: "Alpha")
    beta = create(:published_specialist_guide, organisations: [organisation], title: "Beta")
    gamma = create(:published_specialist_guide, organisations: [organisation], title: "Gamma")
    delta = create(:published_specialist_guide, organisations: [organisation], title: "Delta")

    assert_same_elements [gamma, beta, delta], organisation.published_specialist_guides
  end

  test '#destroy removes parent relationships' do
    child = create(:organisation)
    parent = create(:organisation, child_organisations: [child])
    child.destroy
    assert_equal 0, OrganisationalRelationship.count
    assert parent.reload.child_organisations.empty?
  end

  test 'destroy deletes related contacts' do
    organisation = create(:organisation)
    contact = create(:contact, organisation: organisation)
    organisation.destroy
    assert_nil Contact.find_by_id(contact.id)
  end

  test 'destroy deletes related social media accounts' do
    organisation = create(:organisation)
    social_media_account = create(:social_media_account, organisation: organisation)
    organisation.destroy
    assert_nil SocialMediaAccount.find_by_id(social_media_account.id)
  end

  test 'destroy removes edition relationships' do
    organisation = create(:organisation)
    edition = create(:published_edition, organisations: [organisation])
    organisation.destroy
    assert_equal 0, EditionOrganisation.count
  end

  test 'destroy removes topic relationships' do
    organisation = create(:organisation)
    topic = create(:topic, organisations: [organisation])
    organisation.destroy
    assert_equal 0, OrganisationTopic.count
  end

  test 'destroy unsets user organisation' do
    organisation = create(:organisation)
    user = create(:policy_writer, organisation: organisation)
    organisation.destroy
    assert_nil user.reload.organisation_id
  end

  test 'should be active if it is a department' do
    type = create(:organisation_type, name: "Ministerial department")
    assert type.department?
    organisation = create(:organisation, organisation_type: type)
    assert organisation.calculate_active?
  end

  test 'should be inactive if it is not a department' do
    type = create(:organisation_type, name: "Executive agency")
    organisation = create(:organisation, organisation_type: type)
    refute organisation.calculate_active?
  end

  test 'should update cached active state' do
    organisation = create(:organisation)
    organisation.update_cached_active_state!
    refute organisation.reload.active?

    type = create(:organisation_type, name: "Ministerial department")
    organisation.organisation_type = type
    organisation.update_cached_active_state!
    assert organisation.reload.active?
  end

  test 'should use full name as display_name if acronym is an empty string' do
    assert_equal 'Blah blah', build(:organisation, acronym: '', name: 'Blah blah').display_name
  end

  test "should be destroyable when there are no associated people/child orgs/roles" do
    organisation = create(:organisation)
    assert organisation.destroyable?
  end

  test "should not be destroyable if there are associated roles" do
    organisation = create(:organisation)
    role = create(:role)
    organisation.roles << role
    refute organisation.destroyable?
    organisation.destroy
    assert Organisation.find(organisation.id)
  end

  test "should not be destroyable if there are associated child orgs" do
    organisation = create(:organisation)
    child_org = create(:organisation)
    organisation.child_organisations << child_org
    refute organisation.destroyable?
    organisation.destroy
    assert Organisation.find(organisation.id)
  end

end
