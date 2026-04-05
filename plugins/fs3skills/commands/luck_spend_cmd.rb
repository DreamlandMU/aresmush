module AresMUSH
  module FS3Skills
    class LuckSpendCmd
      include CommandHandler
      
      attr_accessor :reason, :amount

      def parse_args
        args = cmd.parse_args(ArgParser.arg1_equals_arg2)
        self.amount = args.arg1 ? args.arg1.to_i : 1
        self.reason = trim_arg(args.arg2)
      end

      def required_args
        [ self.reason, self.amount ]
      end
      
      def check_luck
        return t('fs3skills.not_enough_points') if enactor.fs3_luck < self.amount
        return nil
      end
      
      def handle
        FS3Skills.spend_luck(enactor, self.reason, enactor_room.scene, self.amount)
      end
    end
  end
end
