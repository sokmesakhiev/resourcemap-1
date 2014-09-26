require 'spec_helper' 

describe "collections", :type => :request do 
 
  it "should edit site Text values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    text = layer.text_fields.make(:name => 'Text', :code => 'text')
    collection.sites.make properties: { text.es_code => 'one text' }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 2
    fill_in 'value', :with => 'Prueba'
    click_button 'Done'
    sleep 3 
    expect(page).not_to have_content 'one text'
    expect(page).to have_content 'Prueba'
    page.save_screenshot "Edit_site_Text_value.png"
  end
end
