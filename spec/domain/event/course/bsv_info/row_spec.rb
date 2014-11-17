# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

require 'spec_helper'

describe Event::Course::BsvInfo::Row do
  let(:course) { events(:top_course) }
  let(:participant) { people(:flock_leader_bern) }
  let(:info) { Event::Course::BsvInfo::Row.new(course.reload) }

  def create_participation(*role_types)
    roles = role_types.map { |type| Fabricate(:event_role, type: type.name) }
    Fabricate(:event_participation, event: course, roles: roles, active: true)
  end

  def create_participant_with_person_attrs(attrs)
    participation = create_participation(course.participant_types.first)
    participation.person.update_attributes(attrs)
  end

  context 'info from dates' do
    it 'blank if no dates specified' do
      course.dates.destroy_all

      %w(date total_days location).each do |attr|
        info.send(attr.to_sym).should be_blank
      end
    end

    it 'sets date to start_at of first date' do
      info.date.should eq '01.03.2012'
    end

    it 'calculates total from summed date durations' do
      info.total_days.should eq 9
    end

    it 'sets location from date with longest duration' do
      event_dates(:first_two).update_attribute(:location, 'somewhere')
      info.location.should eq 'somewhere'
    end
  end

  context 'info from participations' do
    it 'handles null values' do
      course.participations.destroy_all

      %w(participants participants_total leaders leaders_total cooks speakers).each do |attr|
        info.send(attr.to_sym).should eq 0
      end
    end

    context 'role counts' do
      it 'counts roles from fixtures' do
        info.leaders.should eq 1
        info.leaders_total.should eq 1
        info.participants.should eq 0
        info.participants_total.should eq 1

        info.cooks.should eq 0
        info.speakers.should eq 0
      end

      it 'counts participation with multiple leader roles only once' do
        create_participation(Event::Role::Leader, Event::Role::Leader,
                             Event::Role::AssistantLeader)

        info.leaders_total.should eq 2
      end

      it 'counts roles not people for cooks and speakers' do
        create_participation(Event::Role::Leader, Event::Role::Cook, Event::Role::Speaker)

        info.leaders_total.should eq 2
        info.cooks.should eq 1
        info.speakers.should eq 1
      end

      it 'does not count Advisor role' do
        create_participation(Event::Course::Role::Advisor)

        info.leaders.should eq 1
        info.leaders_total.should eq 1
      end
    end

    context '#participants' do
      it 'does not count participants born 16 years before course year' do
        participant.update_attribute(:birthday, '01.01.1996')
        info.participants.should eq 0
      end

      it 'counts participant born 17 years before course year' do
        participant.update_attribute(:birthday, '31.12.1995')
        info.participants.should eq 1
      end

      it 'counts participant born 30 years before course year' do
        participant.update_attribute(:birthday, '01.01.1982')
        info.participants.should eq 1
      end

      it 'does not count participants born 31 years before course year' do
        participant.update_attribute(:birthday, '31.12.1981')
        info.participants.should eq 0
      end

      context 'warnings' do
        it 'is set if not birthday is present' do
          participant.update_attribute(:birthday, nil)
          info.warnings[:participants].should be_true
        end

        it 'is not set if birthday is present' do
          participant.update_attribute(:birthday, '31.12.1981')
          info.warnings[:participants].should be_false
        end
      end
    end

    context 'cantons' do
      let(:birthday) { '01.01.1982' }

      it 'counts valid canton abbreviations of particpants aged 17 to 30' do
        create_participant_with_person_attrs(canton: 'ag', birthday: birthday)
        create_participant_with_person_attrs(canton: 'be', birthday: birthday)
        info.cantons.should eq 2
      end

      it 'counts valid abbreviations only once' do
        2.times { create_participant_with_person_attrs(canton: 'ag', birthday: birthday) }
        info.cantons.should eq 1
      end

      it 'ignores case when counting' do
        create_participant_with_person_attrs(canton: 'AG', birthday: birthday)
        info.cantons.should eq 1
      end

      it 'ignores cantons on people outside of aged 17 to 30 group' do
        create_participant_with_person_attrs(canton: 'ag', birthday: '31.12.1981')
        info.cantons.should eq 0
      end

      context 'warnings' do
        it 'is set if particpants of any age are missing cantons' do
          participant.update_attribute(:canton, nil)
          info.warnings[:cantons].should be_true
        end

        it 'is set if canton value is not a valid abbreviation' do
          participant.update_attribute(:canton, 'Bern')
          info.warnings[:cantons].should be_true
        end

        it 'is not set if canton is present and a valid abbreviation' do
          participant.update_attribute(:canton, 'be')
          info.warnings[:cantons].should be_false
        end
      end
    end

  end
end
