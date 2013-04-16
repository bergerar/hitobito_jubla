module JublaOst
  # Scharen, Releis, Kaleis, AGs, FGs, ...
  class Schar < Base
    self.table_name = 'tSchar'
    self.primary_key = 'SCID'

    # Kaleis werden nicht importiert
    # Releis werden via RegionRelei der ersten Region zugeordnet, welche nicht einem Kanton entspricht.
    # Scharen werden via SCREID der Region zugeordent
    # Alle anderen Typen werden via SCREID der Region/Kanton zugeordnet. Startet der Name mit AG/FG, wird
    # eine Arbeitsgruppe/Fachgruppe erstellt, sonst eine einfache Gruppe.

    KINDS = {'br' => 'Blauring',
             'jw' => 'Jungwacht',
             'jubla' => 'Jubla'}

    class << self

      def migrate_state(current, legacy)
        migrate_groups(current, legacy, JublaOst::Schartyp::Kalei) {|g| Group::StateBoard }
        migrate_groups(current, legacy, *other_types) do |g|
          group_class(g.Schar, Group::StateProfessionalGroup, Group::StateWorkGroup)
        end
      end

      def migrate_region(current, legacy)
        # TODO Releis via RegionRelei
        migrate_groups(current, legacy, JublaOst::Schartyp::Schar) {|g| Group::Flock }
        migrate_groups(current, legacy, *other_types) do |g|
          group_class(g.Schar, Group::RegionalProfessionalGroup, Group::RegionalWorkGroup)
        end
      end

      def flocks(region_id, *types)
        flocks = where('SCREID = ?', region_id)
        if types.present?
          flocks = flocks.where('st IN (?)', types.collect(&:id))
        end
        flocks
      end

      def cache
        @cache ||= {}
      end

      private

      def other_types
        [JublaOst::Schartyp::Intern,
         JublaOst::Schartyp::Andere,
         JublaOst::Schartyp::Iast,
         JublaOst::Schartyp::Ehemalige]
      end

      def migrate_groups(current, legacy, *types)
        flocks(legacy.REID, *types).each do |group|
          clazz = yield group
          migrate_group(current, group, clazz)
        end
      end

      def group_class(name, fg_class, ag_class)
        case name
        when /^FG /, /^Fachgruppe / then fg_class
        when /^AG / then ag_class
        else Group::SimpleGroup
        end
      end

      def migrate_group(parent, legacy_group, clazz)
        if legacy_group.Schar.present?
          group = clazz.new
          group.parent = parent
          migrate_attributes(group, legacy_group)
          group.save!
          cache[legacy_group.SCID] = group.id
          group
        end
      end

      def migrate_attributes(group, legacy)
        group.name = legacy.Schar
        group.short_name = legacy.Scharkurz
        group.zip_code = legacy.PLZ
        group.town = legacy.Ort
        group.email = legacy.SCemail
        group.address = combine("\n", legacy.Adresse1, legacy.Adresse2)
        # TODO: bank_account, Kontakt
        migrate_flock_attributes(group, legacy) if group.is_a?(Group::Flock)
        if legacy.URL.present?
          group.social_accounts.build(label: 'Webseite', name: legacy.URL, public: true)
        end
      end

      def migrate_flock_attributes(group, legacy)
        group.kind = KINDS[legacy.Art]
        group.unsexed = legacy.geschlechtergemischt == '1'
        group.parish = legacy.Pfarrei
        group.jubla_insurance = legacy.Jublavers == 1
        group.jubla_full_coverage = legacy.Vollkasko == 1
        group.founding_year = legacy.gruendung
        group.clairongarde = legacy.clairon == 1
      end

    end

  end
end