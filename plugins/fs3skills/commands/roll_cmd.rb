module AresMUSH
  module FS3Skills
    class RollCmd
      include CommandHandler
      
      attr_accessor :name, :roll_str, :roll_reason, :private_roll

      def parse_args
        if (cmd.args =~ /\//)
          args = cmd.parse_args(ArgParser.arg1_slash_arg2)          
          self.name = titlecase_arg(args.arg1)
          self.roll_str, self.roll_reason = parse_roll_and_reason(args.arg2)
        else
          self.name = enactor_name        
          self.roll_str, self.roll_reason = parse_roll_and_reason(cmd.args)
        end
        self.private_roll = cmd.switch_is?("private")
      end

      def parse_roll_and_reason(args)
        parts = args.split("::", 2)
        roll_str = titlecase_arg(parts[0])
        roll_reason = parts.length > 1 ? parts[1].strip : "no reason"
        return roll_str, roll_reason
      end
      
      def required_args
        [ self.name, self.roll_str ]
      end
      
      def handle
        char = Character.named(self.name)
        if (char)
          die_result = FS3Skills.parse_and_roll(char, self.roll_str)
          
        elsif (self.roll_str.is_integer?)
          die_result = FS3Skills.parse_and_roll(enactor, self.roll_str)
        else
          die_result = nil
        end
        
        if !die_result
          client.emit_failure t('fs3skills.unknown_roll_params')
          return
        end
        
        success_level = FS3Skills.get_success_level(die_result)
        success_title = FS3Skills.get_success_title(success_level)

        if (success_title == t('fs3skills.amazing_success'))
          Achievements.award_achievement(char, 'fs3-are-amazing')
        end
        if (success_title == t('fs3skills.embarrassing_failure'))
          Achievements.award_achievement(char, 'fs3-are-embarrassed')
        end

        message_key = self.roll_reason == "no reason" ? 'fs3skills.simple_roll_result_no_reason' : 'fs3skills.simple_roll_result'
        message = t(message_key, 
          :name => char ? char.name : "#{self.name}", 
          :roll => self.roll_str,
          :reason => self.roll_reason,
          :dice => FS3Skills.print_dice(die_result),
          :success => success_title,
          :roller => enactor.name
        )
        FS3Skills.emit_results message, client, enactor_room, self.private_roll
      end
    end
  end
end
