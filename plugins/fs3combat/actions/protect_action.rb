module AresMUSH
  module FS3Combat
    class ProtectAction < CombatAction
      def prepare
        error = self.parse_targets(self.action_args)
        return error if error

        return t('fs3combat.too_many_targets') if (self.targets.count > 1)
        nil
      end

      def print_action
        t('fs3combat.protect_action_msg_long', :name => self.name, :targets => print_target_names)
      end

      def print_action_short
        t('fs3combat.protect_action_msg_short', :targets => print_target_names)
      end

      def resolve
        messages = []

        # Clear previous protection if any
        self.combatant.combat.active_combatants.each do |c|
          if c.protectors.include?(self.combatant.id)
            c.remove_protector(self.combatant)
          end
        end

        self.targets.first.add_protector(self.combatant)
        message = t('fs3combat.protect_successful_msg', :name => self.name, :target => self.targets.first.name)
        messages << message
        self.combatant.log("#{self.combatant.name} is now protecting #{self.targets.first.name} (ID: #{self.targets.first.id})")

        messages
      end
    end
  end
end
