ProjectsHelper.module_eval do
    # Returns a set of options for a select field, grouped by project.
    # override so we also see team of sprint/version.
    alias old_version_options_for_select version_options_for_select
    
    def version_options_for_select(versions, selected=nil)
      grouped = Hash.new {|h,k| h[k] = []}
      versions.each do |version|
        grouped[version.project.name] << [version.name_team, version.id]
      end

      selected = selected.is_a?(Version) ? selected.id : selected
      if grouped.keys.size > 1
        grouped_options_for_select(grouped, selected)
      else
        options_for_select((grouped.values.first || []), selected)
      end
    end
end