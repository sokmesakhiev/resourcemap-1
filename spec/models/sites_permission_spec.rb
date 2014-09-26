require 'spec_helper'

describe SitesPermission, :type => :model do
  it { is_expected.to belong_to :membership }

  describe "convert to json" do
    its(:to_json) { should_not include "\"id\":" }
    its(:to_json) { should_not include "\"membership_id\":" }
    its(:to_json) { should_not include "\"created_at\":" }
    its(:to_json) { should_not include "\"updated_at\":" }
  end
end
