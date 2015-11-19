module ApplicationHelper
   def full_title(page_title="")
      page_title + (" | " unless page_title.empty?) + "MiGA Clades"
   end
   def breadcrumb(location="")
      (location.empty? ? "" : ("/ " + location + "")).html_safe
   end
end
