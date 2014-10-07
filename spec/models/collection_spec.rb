require 'spec_helper'
describe Collection do
  auth_scope(:user) { User.make }

  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }
  it { should have_many :thresholds }

  let(:collection) { user.create_collection Collection.make_unsaved(anonymous_name_permission: 'read', anonymous_location_permission: 'read')}
  let(:collection2) { user.create_collection Collection.make_unsaved(anonymous_name_permission: 'none', anonymous_location_permission: 'none')}
  let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'foo', name: 'Foo', ord: 1}] }
  let(:field) { layer.fields.first }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {field.es_code => 10}
      collection.sites.make :properties => {field.es_code => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {field.es_code => 5}

      collection.max_value_of_property(field.es_code).should eq(20)
    end
  end

  describe "thresholds test" do
    let(:site) { collection.sites.make properties: {field.es_code => 9}}
    it "should return false when there is no threshold" do
      collection.thresholds_test(site).should be_false
    end

    it "should return false when no threshold is hit" do
      collection.thresholds.make is_all_site: true, conditions: [ field: 1, op: :gt, value: 10 ]
      collection.thresholds_test(site).should be_false
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make is_all_site: false, sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :lt, value: 10 ]
      collection.thresholds_test(site).should be_true
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :eq, value: 9 ]
      collection.thresholds_test(site).should be_true
    end

    describe "multiple thresholds test" do
      let(:site_2) { collection.sites.make properties: {field.es_code => 25}}

      it "should evaluate second threshold" do
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 10} ], sites: [{ "id" => site.id }]
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 20} ], sites: [{ "id" => site_2.id }]
        collection.thresholds_test(site_2).should be_true
      end
    end
  end

  describe "SMS query" do
    describe "Operator parser" do
      it "should return operator for search class" do
        collection.operator_parser(">").should eq("gt")
        collection.operator_parser("<").should eq("lt")
        collection.operator_parser("=>").should eq("gte")
        collection.operator_parser("=<").should eq("lte")
        collection.operator_parser(">=").should eq("gte")
        collection.operator_parser("<=").should eq("lte")
      end
    end
  end

  describe "History" do
    it "shold have user_snapshots througt snapshots" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_2 = collection.snapshots.create! date: Time.now, name: 'snp2'

      snp_1.user_snapshots.create! user: AuthCop.unsafe { User.make }
      snp_2.user_snapshots.create! user: AuthCop.unsafe { User.make }

      user_snapshots = AuthCop.unsafe { collection.user_snapshots.to_a }
      user_snapshots.count.should eq(2)
      user_snapshots[0].snapshot.name.should eq('snp1')
      user_snapshots[1].snapshot.name.should eq('snp2')
    end

    it "should obtain snapshot for user if user_snapshot exists" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: user

      snp_2 = collection.snapshots.create! date: Time.now, name: 'snp2'
      snp_2.user_snapshots.create! user: AuthCop.unsafe { User.make }

      snapshot = collection.snapshot_for(user)
      snapshot.name.should eq('snp1')
    end

    it "should obtain nil snapshot_name for user if user_snapshot does not exists" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: AuthCop.unsafe { User.make }

      snapshot = collection.snapshot_for(user)
      snapshot.should be_nil
    end
  end

  describe "memberships" do
    it "should obtain membership for collection admin" do
      membership = collection.membership_for(user)
      membership.admin.should be(true)
    end

    it "should obtain membership for collection user" do
      member = AuthCop.unsafe { User.make }
      membership_for_member = collection.memberships.create! :user_id => member.id, admin: false
      membership = collection.membership_for(member)
      membership.admin.should be(false)
    end

    it "should obtain membership if collection has anonymous read permission and user is not member " do
      non_member = AuthCop.unsafe { User.make }
      membership = collection.membership_for(non_member)
      membership.should_not be_nil
    end

    it "should not obtain membership if collection doesn't have anonymous read permission and useris not member" do
      non_member = AuthCop.unsafe { User.make }
      membership = collection2.membership_for(non_member)
      membership.should be_nil
    end

    it "should obtain dummy membership for guest user" do
      guest = AuthCop.unsafe { User.new(is_guest: true) }
      membership = collection.membership_for(guest)
      membership.admin.should be(false)
    end
  end

  describe "plugins" do
    # will fixe as soon as possible
    pending do
      it "should set plugins by names" do
        collection.selected_plugins = ['plugin_1', 'plugin_2']
        collection.plugins.should eq({'plugin_1' => {}, 'plugin_2' => {}})
      end

      it "should skip blank plugin name when setting plugins" do
        collection.selected_plugins = ["", 'plugin_1', ""]
        collection.plugins.should eq({'plugin_1' => {}})
      end
    end
  end

  describe 'es_codes_by_field_code' do
    let(:collection_a) { user.create_collection Collection.make_unsaved }
    let(:layer_a) { collection_a.layers.make user: user }

    let!(:field_a) { layer_a.text_fields.make code: 'A', name: 'A', ord: 1 }
    let!(:field_b) { layer_a.text_fields.make code: 'B', name: 'B', ord: 2 }
    let!(:field_c) { layer_a.text_fields.make code: 'C', name: 'C', ord: 3 }
    let!(:field_d) { layer_a.text_fields.make code: 'D', name: 'D', ord: 4 }

    it 'returns a dict of es_codes by field_code' do
      dict = collection_a.es_codes_by_field_code

      dict['A'].should eq(field_a.es_code)
      dict['B'].should eq(field_b.es_code)
      dict['C'].should eq(field_c.es_code)
      dict['D'].should eq(field_d.es_code)
    end
  end

  describe 'visibility by user for' do
    # Layers are tested in layer_access_spec
    context 'fields' do

      it "should be visible for collection owner" do
        collection.visible_fields_for(user, {}).should eq([field])
      end

      it "should not be visible for unrelated user" do
        new_user = User.make
        collection.visible_fields_for(new_user, {}).should be_empty
      end

      # Test for https://github.com/instedd/resourcemap/issues/735
      it "should not create duplicates with multiple users when anonymous permissions are given for a layer" do
        layer.anonymous_user_permission = 'read'
        layer.save!

        new_user = User.make
        membership = collection.memberships.create user: new_user
        membership.set_layer_access :verb => :read, :access => true, :layer_id => layer.id
        collection.visible_fields_for(user, {}).should eq([field])
      end
    end
  end
end
