module OpenProject::Costs::Hooks
  class WorkPackagesShowHook < Redmine::Hook::Listener
    include ActionView::Helpers::TagHelper
    include ActionView::Context
    include WorkPackagesHelper

    def work_packages_show_attributes(context = {})
      work_package = context[:work_package]
      project = context[:project]
      attributes = context[:attributes]

      return unless project.module_enabled? :costs_module

      attributes.reject!{ |a| a.attribute == :spent_time }

      attributes << cost_work_package_attributes(work_package)
      attributes.flatten!

      attributes
    end

    private

    def cost_work_package_attributes(work_package)
      attributes = []

      attributes << work_package_show_table_row(:cost_object) do
        work_package.cost_object ?
          link_to_cost_object(work_package.cost_object) :
          empty_element_tag
      end
      if User.current.allowed_to?(:view_time_entries, @project) ||
        User.current.allowed_to?(:view_own_time_entries, @project)

        attributes << work_package_show_table_row(:spent_hours) do
          # TODO: put inside controller or model
          summed_hours = @time_entries.sum(&:hours)

          summed_hours > 0 ?
            link_to(l_hours(summed_hours), work_package_time_entries_path(work_package)) :
            empty_element_tag
        end

      end
      attributes << work_package_show_table_row(:overall_costs) do
        @overall_costs.nil? ?
          empty_element_tag :
          number_to_currency(@overall_costs)
      end

      if User.current.allowed_to?(:view_cost_entries, @project) ||
        User.current.allowed_to?(:view_own_cost_entries, @project)

        attributes << work_package_show_table_row(:spent_units) do
          summarized_cost_entries(@cost_entries, work_package)
        end
      end

      attributes
    end

    def summarized_cost_entries(cost_entries, work_package, create_link=true)
      last_cost_type = ""

      return empty_element_tag if cost_entries.blank?
      result = cost_entries.sort_by(&:id).inject(Hash.new) do |result, entry|
        if entry.cost_type == last_cost_type
          result[last_cost_type][:units] += entry.units
        else
          last_cost_type = entry.cost_type

          result[last_cost_type] = {}
          result[last_cost_type][:units] = entry.units
          result[last_cost_type][:unit] = entry.cost_type.unit
          result[last_cost_type][:unit_plural] = entry.cost_type.unit_plural
        end
        result
      end

      str_array = []
      result.each do |k, v|
        txt = pluralize(v[:units], v[:unit], v[:unit_plural])
        if create_link
          # TODO why does this have project_id, work_package_id and cost_type_id params?
          str_array << link_to(txt, { :controller => '/costlog',
                                      :action => 'index',
                                      :project_id => work_package.project,
                                      :work_package_id => work_package,
                                      :cost_type_id => k },
                                      { :title => k.name })
        else
          str_array << "<span title=\"#{h(k.name)}\">#{txt}</span>"
        end
      end
      str_array.join(", ").html_safe
    end
  end
end