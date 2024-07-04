module AresMUSH
  module Tinker
    class TinkerCmd
      include CommandHandler
      
      def check_can_manage
        return t('dispatcher.not_allowed') if !enactor.has_permission?("tinker")
        return nil
      end
      
      def handle
      
    	return nil if !Achievements.is_enabled?
    	
        name = 'tomfoolery-devil-bargain'  
    	
    	achievement_details = Achievements.achievement_data(name) 
    	if (!achievement_details)
    		client.emit "Achievement not found: #{name}"
    		return t('achievements.invalid_achievement')
    	end
       
    	type = achievement_details['type']
    	message = achievement_details['message']
    	count = achievement_details['count']
    
    	if (!type || !message)
    		raise "Invalid achievement details for #{name}.  Missing type or message."
    	end
    
    	Character.all.each do |c| 
    		c.achievements.each do |achievement|
    			if (achievement.name == name)
    				Global.logger.info "Updating #{name} achievement for #{c.name}."
    				message = message % { count: count }
    				achievement.delete
    				achievement = Achievement.create(character: c, type: type, name: name, message: message, count: count)
    				client.emit "Updated #{name} achievement for #{c.name}."
    			end
    		end

       end
      end
    end
  end
end