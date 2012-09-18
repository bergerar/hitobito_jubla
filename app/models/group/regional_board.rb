# Regionalleitung
class Group::RegionalBoard < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :layer_read, :contact_data, :login]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:layer_read, :contact_data, :login]
  end
  
  roles Leader, Member
  
end