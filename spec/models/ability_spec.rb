require 'spec_helper'
require "cancan/matchers"

describe Ability do
	let!(:admin) { User.make }
	let!(:guest) { User.make is_guest: true}
	let!(:user) { User.make }
	let!(:member) { User.make }
	let!(:collection) { admin.create_collection Collection.make }
	let!(:membership) { collection.memberships.create! :user_id => member.id, admin: false }

	let!(:layer) { Layer.make collection: collection, user: admin }

	let!(:admin_ability) { Ability.new(admin)}
	let!(:member_ability) { Ability.new(member)}
	let!(:user_ability) { Ability.new(user)}
	let!(:guest_ability) { Ability.new(guest)}


	describe "Collection Abilities" do

		describe "Destroy collection" do
			it { admin_ability.should be_able_to(:destroy, collection) }
			it { member_ability.should_not be_able_to(:destroy, collection) }
			it { user_ability.should_not be_able_to(:destroy, collection) }
			it { guest_ability.should_not be_able_to(:destroy, collection) }
		end

		describe "Create snapshot" do
			it { admin_ability.should be_able_to(:create_snapshot, collection) }
			it { member_ability.should_not be_able_to(:create_snapshot, collection) }
			it { user_ability.should_not be_able_to(:create_snapshot, collection) }
			it { guest_ability.should_not be_able_to(:create_snapshot, collection) }
		end

		describe "Update collection" do
			it { admin_ability.should be_able_to(:update, collection) }
			it { member_ability.should_not be_able_to(:upate, collection) }
			it { user_ability.should_not be_able_to(:update, collection) }
			it { guest_ability.should_not be_able_to(:update, collection) }
		end

		describe "Create collection" do
			it { guest_ability.should_not be_able_to(:create, Collection) }
			it { user_ability.should be_able_to(:create, Collection) }
		end

		describe "Public Collection Abilities" do
			let!(:public_collection) { admin.create_collection Collection.make public: true}

			it { user_ability.should_not be_able_to(:read, collection) }
			it { user_ability.should_not be_able_to(:update, collection) }

		end

		describe "Manage snapshots" do

			it { admin_ability.should be_able_to(:create, (Snapshot.make collection: collection)) }
			it { member_ability.should_not be_able_to(:create, (Snapshot.make collection: collection)) }
			it { user_ability.should_not be_able_to(:create, (Snapshot.make collection: collection)) }
			it { guest_ability.should_not be_able_to(:create, (Snapshot.make collection: collection)) }
		end

		describe "Members" do
			it { admin_ability.should be_able_to(:members, collection) }
			it { member_ability.should_not be_able_to(:members, collection) }
			it { user_ability.should_not be_able_to(:members, collection) }
			it { guest_ability.should_not be_able_to(:members, collection) }
		end
	end

	describe "Layer Abilities" do
		let!(:new_layer) { Layer.new collection: collection, user: admin }

		describe "Create layer" do
			it { admin_ability.should be_able_to(:create, new_layer) }
			it { member_ability.should_not be_able_to(:create, new_layer) }
			it { user_ability.should_not be_able_to(:create, new_layer) }
			it { guest_ability.should_not be_able_to(:create, new_layer) }
		end

		describe "Update layer" do
			it { admin_ability.should be_able_to(:update, layer) }
			it { member_ability.should_not be_able_to(:update, layer) }
			it { user_ability.should_not be_able_to(:update, layer) }
			it { guest_ability.should_not be_able_to(:update, layer) }
		end

		describe "Read layer with read permission" do
			let!(:layer_member_read) { LayerMembership.make layer: layer, user: member, read: true }
			let!(:member_ability_with_read_permission) { Ability.new member }

			it { admin_ability.should be_able_to(:read, layer) }
			it { member_ability_with_read_permission.should be_able_to(:read, layer) }
			it { user_ability.should_not be_able_to(:read, layer) }
			it { guest_ability.should_not be_able_to(:read, layer) }
		end

		describe "Should not read layer without read permission" do
			let!(:layer_member_none) { LayerMembership.make layer: layer, user: member, read: false }
			let!(:member_ability_without_read_permission) { Ability.new member }

			it { admin_ability.should be_able_to(:read, layer) }
			it { member_ability_without_read_permission.should_not be_able_to(:read, layer) }
			it { user_ability.should_not be_able_to(:read, layer) }
			it { guest_ability.should_not be_able_to(:read, layer) }
		end

		describe "Should read layers if the collection is public" do
			let!(:public_collection) { admin.create_collection Collection.make public: true}
			let!(:layer_in_public_collection) { Layer.make collection: public_collection, user: admin }

			it { admin_ability.should be_able_to(:read, layer_in_public_collection) }
			it { user_ability.should_not be_able_to(:read, layer_in_public_collection) }
			it { guest_ability.should be_able_to(:read, layer_in_public_collection) }
		end

	end

	describe "Site-field Abilities for layers" do
		let!(:field) { Field::TextField.make collection: collection, layer: layer }
		let!(:site) { collection.sites.make }

		describe "admin" do
			it { admin_ability.should be_able_to(:update_site_property, field, site) }
			it { admin_ability.should be_able_to(:read_site_property, field, site) }
		end

		describe "member with none permission" do
			let!(:layer_member_none) { LayerMembership.make layer: layer, user: member, read: false }
			let!(:member_ability_without_read_permission) { Ability.new member }

			it { member_ability_without_read_permission.should_not be_able_to(:update_site_property, field, site) }
			it { member_ability_without_read_permission.should_not be_able_to(:read_site_property, field, site) }
		end

		describe "member with read permission" do
			let!(:layer_member_none) { LayerMembership.make layer: layer, user: member, read: true }
			let!(:member_ability_with_read_permission) { Ability.new member }

			it { member_ability_with_read_permission.should_not be_able_to(:update_site_property, field, site) }
			it { member_ability_with_read_permission.should be_able_to(:read_site_property, field, site) }
		end

		describe "member with write permission" do
			let!(:layer_member_none) { LayerMembership.make layer: layer, user: member, write: true }
			let!(:member_ability_with_write_permission) { Ability.new member }

			it { member_ability_with_write_permission.should be_able_to(:update_site_property, field, site) }
			it { member_ability_with_write_permission.should be_able_to(:read_site_property, field, site) }
		end
	end

end
