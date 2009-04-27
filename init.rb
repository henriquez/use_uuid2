require 'use_uuid'
ActiveRecord::Base.send(:include, Distributed::UseUuid)
