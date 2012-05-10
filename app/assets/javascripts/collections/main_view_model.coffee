$(-> if $('#collections-main').length > 0

  class window.MainViewModel extends Module
    @include CollectionsViewModel
    @include SitesViewModel
    @include ExportLinksViewModel
    @include MapViewModel
    @include RefineViewModel
    @include SearchViewModel
    @include SammyViewModel
    @include SortViewModel

    initialize: (collections) ->
      @constructorCollectionsViewModel(collections)
      @constructorSitesViewModel()
      @constructorMapViewModel()
      @constructorRefineViewModel()
      @constructorSearchViewModel()
      @constructorSortViewModel()

      @groupBy = ko.observable(@defaultGroupBy)

      @filters.subscribe => @performSearchOrHierarchy()
      @groupBy.subscribe => @performSearchOrHierarchy()

      location.hash = '#/' unless location.hash

      # We make sure all the methods in this model are correctly bound to "this".
      # Using Module and @include makes the methods in the included class not bound
      # to this, and they don't work when being invoked by knockout when interacting
      # with the view.
      @[k] = v.bind(@) for k, v of @ when v.bind? && !ko.isObservable(v)

    defaultGroupBy: {code: (-> ''), name: (-> 'None')}

    showPopupWithMaxValueOfProperty: (field, event) =>
      # Create a popup that first says "Loading...", then loads the content via ajax.
      # The popup is removed when on mouse out.
      offset = $(event.target).offset()
      element = $("<div id=\"thepopup\" style=\"position:absolute;top:#{offset.top - 30}px;left:#{offset.left}px;padding:4px;background-color:black;color:white;border:1px solid grey\">Loading maximum value...</div>")
      $(document.body).append(element)
      mouseoutHandler = ->
        element.remove()
        $(event.target).unbind 'mouseout', mouseoutHandler
      event = $(event.target).bind 'mouseout', mouseoutHandler
      $.get "/collections/#{@currentCollection().id()}/max_value_of_property.json", {property: field.code()}, (data) =>
        element.text "Maximum #{field.name()}: #{data}"

    refreshTimeago: -> $('.timeago').timeago()

)
