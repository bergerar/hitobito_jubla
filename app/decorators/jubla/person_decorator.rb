# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_jubla.

module Jubla::PersonDecorator
  extend ActiveSupport::Concern

  def active_roles_grouped
    build_memo(active_roles)
  end

  def inactive_roles_grouped
    build_memo(alumnus_roles + deleted_alumnus_applicable_roles)
  end

  def coached_events
    @coached_events ||= EventDecorator.decorate_collection(event_queries.coached_events)
  end

  private

  def roles_array
    @roles_array ||= roles.includes(:group).to_a
  end

  def active_roles
    roles_array.reject(&:alumnus?)
  end

  def alumnus_roles
    roles_array - active_roles
  end

  def deleted_alumnus_applicable_roles
    roles.deleted.includes(:group).select do |role|
      role.group &&
        role.applies_for_alumnus? &&
        !(role.group.is_a?(Group::AlumnusGroup) && role.is_a?(Jubla::Role::Member))
    end
  end

  def build_memo(roles)
    roles.each_with_object(Hash.new { |h, k| h[k] = [] }) do |role, memo|
      memo[role.group] << role
    end
  end
end
