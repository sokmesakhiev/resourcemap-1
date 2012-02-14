module Site::GeomConcern
  extend ActiveSupport::Concern

  included do
    before_save :compute_bounding_box_and_zoom, :unless => :group, :if => lambda { new_record? || lat_changed? || lng_changed? || min_zoom_changed? || max_zoom_changed? }
    before_save :compute_bounding_box_and_zoom!, :if => lambda { !@computed_location && group? && !new_record? && location_mode_changed? }
    after_save  :compute_parent_bounding_box_and_zoom!, :if => lambda { parent_id && (new_record? || lat_changed? || lng_changed? || min_lat_changed? || max_lat_changed? || min_lng_changed? || max_lng_changed? || min_zoom_changed? || max_zoom_changed? ) }
    after_save  :compute_collection_center!, :if => lambda { !parent_id && (new_record? || lat_changed? || lng_changed?) }
    after_destroy :compute_parent_bounding_box_and_zoom!, :if => :parent
    after_destroy :compute_collection_center!
  end

  def compute_bounding_box_and_zoom
    if group
      query = 'min(min_lat) as v1, min(max_lat) as v2, max(min_lat) as v3, max(max_lat) as v4, min(min_lng) as v5, min(max_lng) as v6, max(min_lng) as v7, max(max_lng) as v8'
      query += ', sum(lat) as v9, sum(lng) as v10, count(*) as v11' if automatic_location_mode?
      self.sites.where('lat is not null and lng is not null').select(query).each do |v|
        if v.v1 && v.v2 && v.v3 && v.v4 && v.v5 && v.v6 && v.v7 && v.v8
          self.min_lat = [v.v1, v.v2].min
          self.max_lat = [v.v3, v.v4].max
          self.min_lng = [v.v5, v.v6].min
          self.max_lng = [v.v7, v.v8].max
          max_size = [self.max_lat - self.min_lat, self.max_lng - self.min_lng].max.to_f
          if max_size && max_size > 0
            self.min_zoom = 0
            self.max_zoom = Clusterer.zoom_for(max_size)
            self.sites.update_all "min_zoom = #{self.max_zoom + 1}"
          else
            self.min_zoom = 22
            self.max_zoom = 22
          end
        else
          self.min_zoom = 22
          self.max_zoom = 22
        end
        if automatic_location_mode? && v.v9 && v.v10 && v.v11
          self.lat = v.v9 / v.v11
          self.lng = v.v10 / v.v11
        end
      end
      if none_location_mode?
        self.lat = nil
        self.lng = nil
      end
    else
      self.min_lat = self.max_lat = lat
      self.min_lng = self.max_lng = lng
    end
  end

  def compute_bounding_box_and_zoom!
    compute_bounding_box_and_zoom
    @computed_location = true
    self.save!
  end

  def compute_parent_bounding_box_and_zoom!
    parent.compute_bounding_box_and_zoom!
  end

  def compute_collection_center!
    collection.compute_center!
  end

  def automatic_location_mode?
    location_mode.to_s == 'automatic'
  end

  def none_location_mode?
    location_mode.to_s == 'none'
  end
end
