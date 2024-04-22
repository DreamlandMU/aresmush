module AresMUSH
  module FS3Skills
    class SkillsCensusTemplate < ErbTemplateRenderer

      attr_accessor :skills, :type

      def initialize(type)
        self.type = type
        self.skills = FS3Skills.skills_census(type)
        super File.dirname(__FILE__) + "/skills_census.erb"
      end

      def display_name(name)
        FS3Skills.special_names.has_key?(name) ? "%xh#{FS3Skills.special_names[name]}:%xn" : "%xh#{name}:%xn"
      end

      def people_skills(people)
        display = {}
        people.each do |p|
          name = p.before(":")
          rating = p.after(":")
          if (display[rating])
            display[rating] << name
          else
            display[rating] = [ name ]
          end
        end

        display
      end
    end
  end
end
