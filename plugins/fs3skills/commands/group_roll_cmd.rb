module AresMUSH
    module FS3Skills
      class GroupRollCmd
        include CommandHandler
        
        attr_accessor :names, :roll_str, :roll_reason
        
        def parse_args
          if (cmd.args =~ /=/)
            self.names, roll_and_reason = cmd.args.split('=')
            self.names = list_arg(self.names)
            if roll_and_reason.include?('::')
              self.roll_str, self.roll_reason = roll_and_reason.split('::')
            else
              self.roll_str = roll_and_reason
              self.roll_reason = 'no reason'
            end
            self.roll_str = titlecase_arg(self.roll_str)
          else
            self.names = cmd.args.nil? ? nil : list_arg(cmd.args)
          end
        end
        
        def required_args
          [ self.names, self.roll_str ]
        end
        
        def handle
          results = []
          message = []
  
          message_key = self.roll_reason.strip.downcase == "no reason" ? 'fs3skills.group_roll_start_no_reason' : 'fs3skills.group_roll_start_reason'
          message << t(message_key, :roller => enactor_name, :roll => self.roll_str, :reason => self.roll_reason)
  
          self.names.each do |name|
            char = Character.named(name.strip)
            if !char
              client.emit_failure t('fs3skills.character_not_found', :name => name.strip)
              return
            end
            die_result = FS3Skills.parse_and_roll(char, self.roll_str)
            results << { :name => char.name, :result => die_result }
            success_level = FS3Skills.get_success_level(die_result)
            success_title = FS3Skills.get_success_title(success_level)
            message << t('fs3skills.group_roll_individual_result', :name => char.name, :success => success_title, :dice => FS3Skills.print_dice(die_result))
          end
  
          best_roll = results.max_by { |r| FS3Skills.get_success_level(r[:result]) }
          best_success_level = FS3Skills.get_success_level(best_roll[:result])
          
          if best_success_level > 0
            best_success_title = FS3Skills.get_success_title(best_success_level)
            message << t('fs3skills.group_roll_best_result', :name => best_roll[:name], :success => best_success_title)
  
            if best_success_level <= 2
                minor_successes = results.count { |r| FS3Skills.get_success_level(r[:result]) > 0 && FS3Skills.get_success_level(r[:result]) <= best_success_level } - 1
                complications_avoided = results.count { |r| FS3Skills.get_success_level(r[:result]) <= 0 }
                total_minor = minor_successes + complications_avoided
                if total_minor > 0
                  message << (total_minor == 1 ?
                    t('fs3skills.group_roll_minor_success', :count => total_minor) :
                    t('fs3skills.group_roll_minor_successes', :count => total_minor))
                end
              else
                complications = results.count { |r| FS3Skills.get_success_level(r[:result]) < 3 }
                if complications > 0
                  message << (complications == 1 ? 
                    t('fs3skills.group_roll_complication_avoided', :complications => complications) :
                    t('fs3skills.group_roll_complications_avoided', :complications => complications))
                end
              end
              
          elsif best_success_level == -1
            message << t('fs3skills.group_roll_all_botched')
          else
            message << t('fs3skills.group_roll_complication')
          end
  
          FS3Skills.emit_results(message.join("\n"), client, enactor_room, false)
        end
      end
    end
  end
  