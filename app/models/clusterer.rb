class Clusterer
  CellSize = 115.0

  def initialize(zoom)
    @zoom = zoom
    @width, @height = self.class.cell_size_for zoom
    @clusters = Hash.new { |h, k| h[k] = {lat_sum: 0, lng_sum: 0, alert: false, status: true, ord: 100, count: 0, min_lat: 90, max_lat: -90, min_lng: 180, max_lng: -180, highlighted: false } }
    @sites = []
    @clustering_enabled = @zoom < 20
    @highlight = {}
  end

  def self.cell_size_for(zoom)
    zoom = zoom.to_i
    zoom = 2 ** (zoom)
    [CellSize / zoom, CellSize / zoom]
  end

  def self.zoom_for(size)
    Math.log2(CellSize / size).floor
  end

  def highlight(hierarchy_info)
    @highlight[:hierarchy_code] = hierarchy_info[:code]
    @highlight[:hierachies_selected] = hierarchy_info[:selected]
  end

  def add(site)
    if @clustering_enabled
      lat, lng = site[:lat].to_f, site[:lng].to_f
      x, y = cell_for site
      cluster = @clusters["#{x}:#{y}"]
      cluster[:id] = "#{@zoom}:#{x}:#{y}"
      cluster[:collection_id] ||= site[:collection_id]
      cluster[:count] += 1
      cluster[:min_lat] = lat if lat < cluster[:min_lat]
      cluster[:min_lng] = lng if lng < cluster[:min_lng]
      cluster[:max_lat] = lat if lat > cluster[:max_lat]
      cluster[:max_lng] = lng if lng > cluster[:max_lng]
      cluster[:status] = false if site[:collection_id] != cluster[:collection_id]
      cluster[:icon] = site[:icon] ? site[:icon] : ''
      cluster[:lat_sum] += lat
      cluster[:lng_sum] += lng
      cluster[:highlighted] ||= !site[:property].nil? && !@highlight[:hierachies_selected].nil? &&
                                  (site[:property] & @highlight[:hierachies_selected]).present?
      Plugin.hooks(:clusterer).each do |clusterer|
        clusterer[:map].call site, cluster
      end

      if cluster[:count] == 1
        cluster[:site] = site.dup
      else
        cluster.delete :site
      end
    else
      @sites.push site.dup
    end
  end

  def clusters
    result = {}
    if @clustering_enabled
      clusters_to_return = []
      sites_to_return = []

      @clusters.each_value do |cluster|
        count = cluster[:count]
        if count == 1
          site = cluster[:site]
          site[:highlighted] = !site[:property].nil? && !@highlight[:hierachies_selected].nil? &&
                               (site[:property] & @highlight[:hierachies_selected]).present?
          site.delete(:property)

          sites_to_return.push site
        else
          hash = {
            id: cluster[:id],
            lat: cluster[:lat_sum] / count,
            lng: cluster[:lng_sum] / count,
            min_lat: cluster[:min_lat],
            min_lng: cluster[:min_lng],
            max_lat: cluster[:max_lat],
            max_lng: cluster[:max_lng],
            icon: cluster[:status] ? cluster[:icon] : 'default',
            count: count,
            status: cluster[:status],
            highlighted: cluster[:highlighted]
          }

          Plugin.hooks(:clusterer).each do |clusterer|
            clusterer[:reduce].call cluster, hash
          end

          hash[:site_ids] = cluster[:site_ids] if cluster[:site_ids]
          clusters_to_return.push hash
        end
      end

      result[:clusters] = clusters_to_return if clusters_to_return.present?
      result[:sites] = sites_to_return if sites_to_return.present?
    else
      # Disambiguation for sites in identical location
      result[:sites] = []
      result[:original_ghost] = []
      r = 15
      sites_by_lat_lng = @sites.group_by {|s| [s[:lat], s[:lng]] }
      sites_by_lat_lng.each do |k, sites|
        quantity = sites.count
        if quantity == 1
          result[:sites].push sites.first
        else
          result[:original_ghost].push(lat: k.first, lng: k.last)
          angle_each = 2 * Math::PI / quantity
          sites.each_with_index do |site, index|
            angle = angle_each * index
            site[:ghost_radius] = angle
            result[:sites].push site
          end
        end
      end
    end

    result
  end

  protected

  def cell_for(site)
    x = ((90 + site[:lng]) / @width).floor
    y = ((180 + site[:lat]) / @height).floor
    [x, y]
  end
end
