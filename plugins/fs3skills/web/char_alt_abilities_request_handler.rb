module AresMUSH
  module FS3Skills
    class CharAltAbilitiesRequestHandler
      def handle(request)
        char = Character.find_one_by_name request.args['id']
        enactor = request.enactor

        if (!char)
          return []
        end

        error = Website.check_login(request, true)
        return error if error

        alts = AresCentral.play_screen_alts(char)

        abilityList = {}
        luckList = {}
        alts.each do |alt|
          abilityList[alt.name] = []
          [ alt.fs3_attributes, alt.fs3_action_skills, alt.fs3_background_skills, alt.fs3_languages, alt.fs3_advantages ].each do |list|
            list.each do |a|
              name = FS3Skills.special_names.has_key?(a.name) ? FS3Skills.special_names[a.name] : a.name
              abilityList[alt.name] << name
            end
          end
          luckList[alt.name] = alt.fs3_luck.to_i
          Global.logger.info "#{alt.name}: #{lucklist[alt.name]}"
        end

        {
          abilityList: abilityList,
          luckList: luckList
        }
      end
    end
  end
end

