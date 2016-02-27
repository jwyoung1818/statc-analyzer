  module MobileHelper

    def full_site_url
      options = {
          :host => Rails.configuration.cms.site_domain,
          path: current_page.path,
          params: {:prefer_full_site => true}
      }
      ActionDispatch::Http::URL.url_for(options)
    end

    def mobile_site_url
      options = {
          :host => Rails.configuration.cms.site_domain,
          path: current_page.path,
          params: {:prefer_mobile_site => true}
      }
      ActionDispatch::Http::URL.url_for(options)
    end

    # Determines if the mobile template exists for a given page.
    # Used by view to show/hide the mobile toggle.
    def mobile_template_exists?(page)
      controller.template_exists?(page.layout_name, "layouts/mobile")
    end
  end

