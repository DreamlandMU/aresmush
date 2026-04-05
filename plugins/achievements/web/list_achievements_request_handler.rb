
module AresMUSH
  module Achievements
    class ListAchievementsRequestHandler
      def handle(request)

        enactor = request.enactor
        error = Website.check_login(request, true)
        return error if error

        icon_types = Global.read_config('achievements', 'types')
        sections =  Global.read_config('achievements', 'sections')
        groups = Achievement.all.group_by { |a| a.name }

        section_names = []

        sections.each_key do |key|
           section_names << key 
        end

        cheevos = Achievements.all_achievements.sort_by { |k, v| [v['type'], v['message'], v['hidden']]}
          .map { |k, v| {
          name: k,
          message: (v['message'] % { count: "XXX" }),
          type: v['type'],
          type_icon: icon_types["#{v['type']}"] || "fa-question",
          levels: (Achievements.achievement_levels(k) || []).join(", "),
          chars: chars_for_achievement(k, groups),
          hidden: v['hidden']
          }}

	grouped = {}
        activity = {}
	hidden = {}
        hidden['hidden'] = []
        section_names.each_with_index do |sec, index|
            grouped[sec] = []
            activity[sec] = index == 0 ? 'active' : ''
        end
        cheevos.each do |cheevo|
           catch (:found) do 
               if cheevo[:hidden] && cheevo[:chars].length == 0
                    hidden['hidden'] << cheevo
                    next
               end
	       section_names[0..-2].each do |sec|
                    sections[sec].each do |cat|
                        if (cheevo[:type].start_with?(cat))
                            grouped[sec] << cheevo
                            throw :found
                        end
                     end
                end
                grouped[section_names.last] << cheevo
           end 
       end  

       unless (enactor && enactor.is_admin?)
                hidden = false
       end

       result = {
                 section_names: section_names, 
                 sections: grouped,
                 activity: activity,
                 hidden: hidden
                }
         return result

      end
      
      def chars_for_achievement(name, groups)
        return [] if !groups.has_key?(name)
        
        achievements = groups[name]
        
        achievements.sort_by { |a| [ 0 - a.count, a.character.name ] }
                    .map { |a| {
                      name: a.character.name,
                      count: a.count > 0 ? a.count : nil }
                    }
      end
    end
  end
end
