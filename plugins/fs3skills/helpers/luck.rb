module AresMUSH
  module FS3Skills
    def self.can_manage_luck?(actor)
      actor && actor.has_permission?("manage_abilities")
    end
    
    def self.modify_luck(char, amount)
      max_luck = Global.read_config("fs3skills", "max_luck")
      luck = char.fs3_luck + amount
      luck = [max_luck, luck].min
      luck = [0, luck].max
      char.update(fs3_luck: luck)
    end
    
    def self.spend_luck(char, reason, scene, amount)
      char.spend_luck(amount)
      message = if amount == 1
                  t('fs3skills.luck_point_spent', :name => char.name, :reason => reason)
                else
                  t('fs3skills.luck_points_spent', :name => char.name, :amount => amount, :reason => reason)
                end

      if (scene)
        scene.room.emit_ooc message
        Scenes.add_to_scene(scene, message)
      else
        char.room.emit_ooc message
      end
      
      Achievements.award_achievement(char, "fs3_luck_spent")
      
      if (Global.read_config('fs3skills', 'job_on_luck_spend'))
        category = Jobs.system_category
        status = Jobs.create_job(category, t('fs3skills.luck_job_title', :name => char.name), message, Game.master.system_character)
        if (status[:job])
          Jobs.close_job(Game.master.system_character, status[:job])
        end
      end
      
      Global.logger.info "#{char.name} spent #{amount} luck points on #{reason}."
    end
  end
end
