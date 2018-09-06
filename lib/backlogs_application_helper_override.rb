ApplicationHelper.module_eval do
  # Original generates a link to a version
  # Now generate a link to a sprint
  old_link_to_version = instance_method(:link_to_version)
  
  def link_to_version(version, options = {})
    return '' unless version && version.is_a?(Version)
    return old_link_to_version(version, options) unless Backlogs.configured?
    link_to_sprint(version, options.merge({:team => true}))
  end
end
