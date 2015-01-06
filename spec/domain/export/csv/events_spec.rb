# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

require 'spec_helper'

describe Export::Csv::Events do

  let(:person) { Fabricate.build(:person_with_address_and_phone, j_s_number: 123) }
  let(:advisor) { Fabricate(:person_with_address_and_phone, j_s_number: 123) }
  let(:course) { Fabricate.build(:course, contact: person, state: :application_open, advisor_id: advisor.id) }
  let(:contactable_keys) { [:name, :address, :zip_code, :town, :email, :phone_numbers, :j_s_number] }

  context Export::Csv::Events::List do

    context 'used labels' do
      let(:list) { Export::Csv::Events::List.new(double('courses', map: [], first: nil)) }
      subject { list.attribute_labels }

      its(:keys) { should include(*[:advisor_name, :advisor_address, :advisor_zip_code, :advisor_town, :advisor_email, :advisor_phone_numbers]) }
      its(:values) { should include(*['LKB Name', 'LKB Adresse', 'LKB PLZ', 'LKB Ort', 'LKB Haupt-E-Mail', 'LKB Telefonnummern']) }
    end

    context 'translatable state' do
      let(:course) do
        Fabricate(:jubla_course, groups: [groups(:ch)], location: 'somewhere',
                  state: 'created')
      end
      let(:list)  { Export::Csv::Events::List.new([course]) }
      let(:csv) { Export::Csv::Generator.new(list).csv.split("\n")  }
      subject { csv.second.split(';') }

      # This tests the case where Event.possible_states is non-empty,
      # the case without predefined states is tested in the core.
      its([5]) { should eq 'Erstellt' }
    end
  end

  context Export::Csv::Events::Row do
    let(:list) { OpenStruct.new(max_dates: 3, contactable_keys: contactable_keys) }
    let(:row) { Export::Csv::Events::Row.new(course) }

    it { row.fetch(:state).should eq 'Offen zur Anmeldung' }
    it { row.fetch(:contact_j_s_number).should eq 123 }
    it { row.fetch(:advisor_name).should eq advisor.to_s }
    it { row.fetch(:advisor_j_s_number).should eq '123' } # varchar in db
  end

end
