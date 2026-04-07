module AresMUSH
  module FS3Skills
    
    def self.success_target_number
      6
    end
    
    # Makes an ability roll and returns the raw dice results.
    # Good for when you're doing a regular roll because you can show the raw dice and
    # use the other methods in this class to get the success level and title to display.
    def self.roll_ability(char, roll_params)
      dice = FS3Skills.dice_to_roll_for_ability(char, roll_params)
      roll = FS3Skills.roll_dice(dice)
      Global.logger.info "#{char.name} rolling #{roll_params} dice=#{dice} result=#{roll}"
      Achievements.award_achievement(char, "fs3_roll")
      roll
    end
    
    # Rolls a number of FS3 dice and returns the raw die results.
    def self.roll_dice(dice)
      if (dice > 30)
        Global.logger.warn "Attempt to roll #{dice} dice."
        # Hey if they're rolling this many dice they ought to succeed spectacularly.
        return [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8]
      end
      
      dice = [dice, 1].max.ceil
      dice.times.collect { 1 + rand(8) }
    end
    
    # Determines the success level based on the raw die result.
    # Either:  0 for failure, -1 for a botch (embarrassing failure), or
    #    the number of successes.
    def self.get_success_level(die_result)
      successes = die_result.count { |d| d >= FS3Skills.success_target_number }
      botches = die_result.count { |d| d == 1 }
      return successes if (successes > 0)
      return -1 if (botches > die_result.count / 2)
      return 0
    end
    
    def self.emit_results(message, client, room, is_private)
      if (is_private)
        client.emit message
      else
        room.emit message
        channel = Global.read_config("fs3skills", "roll_channel")
        if (channel)
          Channels.send_to_channel(channel, message)
        end
        
        if (room.scene)
          Scenes.add_to_scene(room.scene, message)
        end
        
      end
      Global.logger.info "FS3 roll results: #{message}"
    end
    
    # Returns either { message: roll_result_message }  or  { error: error_message }
    def self.determine_web_roll_result(request, enactor)
      roll_str = request.args['roll_string']
      roll_reason = request.args['roll_reason']
      vs_roll1 = request.args['vs_roll1'] || ""
      vs_roll2 = request.args['vs_roll2'] || ""
      vs_name1 = (request.args['vs_name1'] || "").titlecase
      vs_name2 = (request.args['vs_name2'] || "").titlecase
      pc_name = request.args['pc_name'] || ""
      pc_skill = request.args['pc_skill'] || ""
      is_group_roll = request.args['is_group_roll'] == 'true'
      group_roll_names = request.args['group_roll_names'] || ""
      no_draw = request.args['no_draw'] || false
      
      if (!vs_roll1.blank?)
        result = ClassTargetFinder.find(vs_name1, Character, enactor)
        model1 = result.target
        if (!model1 && !vs_roll1.is_integer?)
          vs_roll1 = "3"
        end
                              
        result = ClassTargetFinder.find(vs_name2, Character, enactor)
        model2 = result.target
        vs_name2 = model2 ? model2.name : vs_name2
                              
        if (!model2 && !vs_roll2.is_integer?)
          vs_roll2 = "3"
        end
        
        die_result1 = FS3Skills.parse_and_roll(model1, vs_roll1)
        die_result2 = FS3Skills.parse_and_roll(model2, vs_roll2)
        
        if (!die_result1 || !die_result2)
          return { error: t('fs3skills.unknown_roll_params') }
        end
        
        successes1 = FS3Skills.get_success_level(die_result1)
        successes2 = FS3Skills.get_success_level(die_result2)

        if (no_draw == 'true')
          Global.logger.info "Round 1: #{successes1}, #{successes2}."
          i = 1
          until successes1 != successes2 do
            die_result1 = FS3Skills.parse_and_roll(model1, vs_roll1)
            die_result2 = FS3Skills.parse_and_roll(model2, vs_roll2)

            if (!die_result1 || !die_result2)
              return { error: t('fs3skills.unknown_roll_params') }
            end

            successes1 = FS3Skills.get_success_level(die_result1)
            successes2 = FS3Skills.get_success_level(die_result2)

            i += 1
            Global.logger.info "Round #{i}: #{successes1}, #{successes2}."
          end
        end
          
        results = FS3Skills.opposed_result_title(vs_name1, successes1, vs_name2, successes2)
        
        message = t('fs3skills.opposed_roll_result', 
           :name1 => !model1 ? t('fs3skills.npc', :name => vs_name1) : model1.name,
           :name2 => !model2 ? t('fs3skills.npc', :name => vs_name2) : model2.name,
           :roll1 => vs_roll1,
           :roll2 => vs_roll2,
           :dice1 => FS3Skills.print_dice(die_result1),
           :dice2 => FS3Skills.print_dice(die_result2),
           :result => results,
           :roller => enactor.name
        )  
      elsif (!pc_name.blank?)
        char = Character.find_one_by_name(pc_name)
  
        if (!char && !pc_skill.is_integer?)
          pc_skill = "3"
        end
  
        roll = FS3Skills.parse_and_roll(char, pc_skill)
        roll_result = FS3Skills.get_success_level(roll)
        success_title = FS3Skills.get_success_title(roll_result)
        if (success_title == t('fs3skills.amazing_success'))
          Achievements.award_achievement(char, 'fs3-are-amazing') 
        end
        if (success_title == t('fs3skills.embarrassing_failure'))
          Achievements.award_achievement(char, 'fs3-are-embarrassed')
        end
        message_key = roll_reason.strip.downcase == "no reason" ? 'fs3skills.simple_roll_result_no_reason' : 'fs3skills.simple_roll_result'
        message = t(message_key, 
          :name => char ? char.name : "#{pc_name}",
          :roll => pc_skill,
          :reason => roll_reason,
          :dice => FS3Skills.print_dice(roll),
          :success => success_title,
          :roller => enactor.name
          )
      elsif (is_group_roll)
        names = group_roll_names.split(' ')
        results = []
        names.each do |name|
          char = Character.named(name)
          if (!char)
            return { error: t('fs3skills.character_not_found', :name => name) }
          end
          roll = FS3Skills.parse_and_roll(char, roll_str)
          results << { :name => char.name, :roll => roll }
        end
        message = FS3Skills.format_group_roll_results(results, roll_str, roll_reason, enactor)
      else
        roll = FS3Skills.parse_and_roll(enactor, roll_str)
        roll_result = FS3Skills.get_success_level(roll)
        success_title = FS3Skills.get_success_title(roll_result)
        if (success_title == t('fs3skills.amazing_success'))
          Achievements.award_achievement(enactor, 'fs3-are-amazing')
        end
        if (success_title == t('fs3skills.embarrassing_failure'))
          Achievements.award_achievement(enactor, 'fs3-are-embarrassed')
        end
        message_key = roll_reason.strip.downcase == "no reason" ? 'fs3skills.simple_roll_result_no_reason' : 'fs3skills.simple_roll_result'
        message = t(message_key, 
          :name => enactor.name,
          :roll => roll_str,
          :reason => roll_reason,
          :dice => FS3Skills.print_dice(roll),
          :success => success_title,
          :roller => enactor.name
          )
      end
      
      return { message: message }
    end

    def self.format_group_roll_results(results, roll_str, roll_reason, enactor)
      message_key = roll_reason.strip.downcase == "no reason" ? 'fs3skills.group_roll_start_no_reason' : 'fs3skills.group_roll_start_reason'
      message = t(message_key, :roller => enactor.name, :roll => roll_str, :reason => roll_reason)
    
      results.each do |r|
        success_level = FS3Skills.get_success_level(r[:roll])
        success_title = FS3Skills.get_success_title(success_level)
        message << "\n#{t('fs3skills.group_roll_individual_result', :name => r[:name], :success => success_title, :dice => FS3Skills.print_dice(r[:roll]))}"
      end
      
      best_roll = results.max_by { |r| FS3Skills.get_success_level(r[:roll]) }
      best_success_level = FS3Skills.get_success_level(best_roll[:roll])
      
      if best_success_level > 0
        message << "\n#{t('fs3skills.group_roll_best_result', :name => best_roll[:name], :success => FS3Skills.get_success_title(best_success_level))}"
        
        if best_success_level <= 2
          minor_successes = results.count { |r| FS3Skills.get_success_level(r[:roll]) > 0 && FS3Skills.get_success_level(r[:roll]) <= best_success_level } - 1
          complications_avoided = results.count { |r| FS3Skills.get_success_level(r[:roll]) <= 0 }
          total_minor = minor_successes + complications_avoided
          if total_minor > 0
            message << "\n#{total_minor == 1 ? 
              t('fs3skills.group_roll_minor_success', :count => total_minor) :
              t('fs3skills.group_roll_minor_successes', :count => total_minor)}"
          end
        else
          complications = results.count { |r| FS3Skills.get_success_level(r[:roll]) < 3 }
          if complications > 0
            message << "\n#{complications == 1 ? 
              t('fs3skills.group_roll_complication_avoided', :complications => complications) :
              t('fs3skills.group_roll_complications_avoided', :complications => complications)}"
          end
        end
      elsif best_success_level == -1
        message << "\n#{t('fs3skills.group_roll_all_botched')}"
      else
        message << "\n#{t('fs3skills.group_roll_complication')}"
      end
      
      message
    end
  end
end
