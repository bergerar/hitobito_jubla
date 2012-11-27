# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  group_id               :integer          not null
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#

Fabricator(:camp, from: :event, class_name: :'Event::Camp') do
  groups { [Group.all_types.detect {|t| t.event_types.include?(Event::Camp) }.first] }
end

Fabricator(:jubla_course, from: :course) do
  application_contact do |attrs| 

    contact_groups = []
    groups = attrs[:groups]
    groups.each do |g|
      if type = g.class.contact_group_type
        state_agencies = g.children.where(type: type.sti_name).all
        contact_groups.concat(state_agencies)
      end
    end
    contact_groups.sample

  end
end
