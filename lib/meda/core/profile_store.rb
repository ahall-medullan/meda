require_relative 'mapdb'
require 'uuidtools'
require 'digest'

module Meda
  class ProfileStore

    attr_reader :mapdb, :path, :tree

    def initialize(path)
      @path = path
      @mapdb = MapDB::DB.new(path.to_s)
      @tree = @mapdb.tree(:meda)
    end

    # Create a new profile with the given identifying info

    def create_profile(info)
      profile_id = UUIDTools::UUID.timestamp_create.hexdigest
      # Create the main record, ie "profile:12341234123412341234124"
      @tree.encode(profile_key(profile_id), {'id' => profile_id})

      # Create lookups for each attribute. ie "profile:lookup:{hashed key}:{hashed val}"
      info.each_pair do |k, v|
        @tree.encode(key_hashed_profile_lookup(k,v), profile_id)
      end
      ActiveSupport::HashWithIndifferentAccess.new({'id' => profile_id})
    end

    # Add additional identifying info to existing profile

    def alias_profile(profile_id, info)
      # Create additional for each alias attribute.
      if @tree.key?(profile_key(profile_id))
        info.each_pair do |k, v|
          @tree.encode(key_hashed_profile_lookup(k,v), profile_id)
        end
        true
      else
        false # no profile
      end
    end

    def find_or_create_profile(info)
      profile_id = lookup_profile(info)
      if profile_id
        get_profile_by_id(profile_id)
      else
        create_profile(info)
      end
    end

    def get_profile_by_id(profile_id)
      if @tree.key?(profile_key(profile_id))
        ActiveSupport::HashWithIndifferentAccess.new(@tree.decode(profile_key(profile_id)))
      else
        false # no profile
      end
    end

    # Set additional hash values on profile attributes

    def set_profile(profile_id, profile_info)
      if @tree.key?(profile_key(profile_id))
        existing_profile = @tree.decode(profile_key(profile_id))
        @tree.encode(profile_key(profile_id), existing_profile.merge(profile_info))
      else
        false # no profile
      end
    end

    # Uses one criteria at a time, in order, until a match is found

    def lookup_profile(info)
      lookup_keys = info.map{|k,v| key_hashed_profile_lookup(k,v)}
      while (lookup_keys.length > 0) do
        test_key = lookup_keys.shift
        return @tree.decode(test_key) if @tree.key?(test_key)
      end
      false
    end

    # Generate keys

    def key_hashed_profile_lookup(k,v)
      "profile:lookup:#{Digest::SHA1.hexdigest(k.to_s)}:#{Digest::SHA1.hexdigest(v.to_s)}"
    end

    def profile_key(id)
      "profile:#{id}"
    end

  end
end

