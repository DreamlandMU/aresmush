module AresMUSH
  module Tinker
    class TinkerCmd
      include CommandHandler

      def check_can_manage
        return t('dispatcher.not_allowed') if !enactor.is_coder?
        return nil
      end

      def handle
        client.emit_success "Starting group roll test cases."

        test_cases = [
          { name: "All Botch", results: [-1, -1, -1] },
          { name: "All Fail", results: [0, 0, 0] },
          { name: "Mixed Fail and Botch", results: [0, -1, 0] },
          { name: "One Minor Success", results: [1, 0, -1] },
          { name: "Multiple Minor Successes", results: [2, 1, 0] },
          { name: "One Good Success", results: [3, 1, 0] },
          { name: "Mixed Good and Minor", results: [3, 2, 1] },
          { name: "All Good Success", results: [3, 3, 3] },
          { name: "Mixed Great and Good", results: [5, 3, 2] },
          { name: "All Great Success", results: [5, 5, 5] },
          { name: "Someones Gonna Be Smug", results: [7, 2, -1] }
        ]

        test_cases.each do |test|
          client.emit_ooc "Test Case: #{test[:name]}"
          fake_roll(test[:results])
          client.emit_ooc "-------------------------"
        end

        client.emit_success "Group roll test cases complete."
      end

      def fake_roll(results)
        fake_chars = results.map.with_index { |r, i| "Character#{i + 1}" }
        message = []

        message << t('fs3skills.group_roll_start_no_reason', :roller => enactor_name, :roll => "Test Roll")

        results.each_with_index do |result, index|
          success_title = FS3Skills.get_success_title(result)
          message << t('fs3skills.group_roll_individual_result', :name => fake_chars[index], :success => success_title, :dice => "Fake Roll")
        end

        best_roll = results.max
        if best_roll > 0
          best_success_title = FS3Skills.get_success_title(best_roll)
          message << t('fs3skills.group_roll_best_result', :name => fake_chars[results.index(best_roll)], :success => best_success_title)

          if best_roll <= 2
            minor_successes = results.count { |r| r > 0 && r <= best_roll } - 1
            complications_avoided = results.count { |r| r <= 0 }
            total_minor = minor_successes + complications_avoided
            if total_minor > 0
              message << (total_minor == 1 ?
                t('fs3skills.group_roll_minor_success', :count => total_minor) :
                t('fs3skills.group_roll_minor_successes', :count => total_minor))
            end
          else
            complications = results.count { |r| r < 3 }
            if complications > 0
              message << (complications == 1 ? 
                t('fs3skills.group_roll_complication_avoided', :complications => complications) :
                t('fs3skills.group_roll_complications_avoided', :complications => complications))
            end
          end
        elsif best_roll == -1
          message << t('fs3skills.group_roll_all_botched')
        else
          message << t('fs3skills.group_roll_complication')
        end

        client.emit message.join("\n")
      end
    end
  end
end
